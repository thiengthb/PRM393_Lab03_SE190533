import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../utils/app_exception.dart';
import 'firestore_mappers.dart';

/// Lỗi khi chốt mà chưa có mạng: bản ghi đã nằm trong bộ nhớ đệm Firestore
/// trên máy và sẽ tự gửi khi có mạng (GV-OV2 “Mất mạng · đã lưu trên máy”).
class SavedOfflineException extends AppException {
  const SavedOfflineException() : super(AppErrorKind.network, 'Mất mạng · đã lưu trên máy');
}

/// Bản ghi `qrCodes/{mã}`: sinh viên gõ 6 số thì đọc đúng bản ghi này để lấy nội dung QR.
class QrCodeEntry {
  const QrCodeEntry({
    required this.code,
    required this.lecturerId,
    required this.slotId,
    required this.classId,
    required this.payload,
    required this.expiresAt,
  });

  final String code;
  final String lecturerId;
  final String slotId;
  final String classId;

  /// QrPayload.encode() của mã đang dùng.
  final String payload;
  final DateTime expiresAt;
}

/// Ghi một khung màn chiếu vào `tv/{key}`.
class TvWrite {
  const TvWrite({required this.key, required this.lecturerId, required this.slotId, required this.frame});
  final String key;
  final String lecturerId;
  final String slotId;
  final TvFrame frame;
}

abstract class SlotRepository {
  Stream<List<Slot>> watchSlots(String lecturerId);
  Stream<Slot?> watchSlot(String slotId);
  Stream<List<AttendanceRecord>> watchAttendance(String slotId);

  /// Mọi bản ghi điểm danh của giảng viên (collection group), để đếm buổi vắng.
  Stream<List<AttendanceRecord>> watchLecturerRecords(String lecturerId);

  /// true khi lịch của giảng viên đang lấy từ bộ nhớ đệm trên máy (mất mạng), false khi đã
  /// khớp máy chủ. Dùng cho dải Mất mạng ở GV-001 .X.
  Stream<bool> watchFromCache(String lecturerId);

  /// Một lần đổi mã, ghi trong một batch: slot, mã số mới [code], xoá các mã số [dropCodes]
  /// và cập nhật màn chiếu [tv]. [prevToken] là mã vừa thay, còn nhận tới [prevExpiresAt] để
  /// người quét chậm (hoặc gõ mã số) không bị báo hết hạn ngay lúc mã đổi.
  /// Ném AppException quyền nếu mã số trùng với lớp khác đang dùng; gọi lại với mã khác.
  Future<void> openQr(
    String slotId,
    String token,
    DateTime expiresAt, {
    String? prevToken,
    DateTime? prevExpiresAt,
    QrCodeEntry? code,
    List<String> dropCodes = const [],
    TvWrite? tv,
  });
  Future<void> closeQr(String slotId, {List<String> dropCodes = const [], TvWrite? tv});

  /// LOI-05: this device stops rotating (left the session screen); the code stays valid.
  Future<void> releaseQr(String slotId);

  /// Tạo màn chiếu `tv/{key}` và lưu khoá vào slot để mở lại màn vẫn dùng link cũ.
  Future<void> createTv(TvWrite tv);

  /// Cập nhật màn chiếu ngoài lần đổi mã (sau khi chốt).
  Future<void> pushTv(TvWrite tv);
  Future<void> markManual(Slot slot, Student student, bool present);

  /// Ghi kết quả cho cả lớp và đánh dấu slot đã chốt.
  /// Ném [SavedOfflineException] nếu máy chủ chưa xác nhận sau [timeout].
  Future<void> closeSession(
    Slot slot,
    List<Student> roster,
    Map<String, AttendanceRecord> current, {
    Duration timeout = const Duration(seconds: 8),
  });

  Future<void> undoClose(Slot slot, List<Student> roster);

  /// Chờ các thay đổi còn trong bộ nhớ đệm gửi xong (nút Thử lại ở GV-OV2).
  Future<void> waitForSync({Duration timeout = const Duration(seconds: 8)});
}

class FirestoreSlotRepository implements SlotRepository {
  FirestoreSlotRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _slots => _db.collection('slots');

  @override
  Stream<List<Slot>> watchSlots(String lecturerId) => Fs.guard(
        _slots.where('lecturerId', isEqualTo: lecturerId).snapshots().map(
              (q) => q.docs.map((d) => Fs.slot(d.id, d.data())).toList()..sort((a, b) => a.start.compareTo(b.start)),
            ),
      );

  @override
  Stream<bool> watchFromCache(String lecturerId) => _slots
      .where('lecturerId', isEqualTo: lecturerId)
      .snapshots(includeMetadataChanges: true)
      .map((q) => q.metadata.isFromCache)
      .distinct();

  @override
  Stream<Slot?> watchSlot(String slotId) =>
      Fs.guard(_slots.doc(slotId).snapshots().map((s) => s.exists ? Fs.slot(s.id, s.data()!) : null));

  @override
  Stream<List<AttendanceRecord>> watchAttendance(String slotId) => Fs.guard(
        _slots
            .doc(slotId)
            .collection('attendance')
            .snapshots()
            .map((q) => q.docs.map((d) => Fs.attendance(slotId, d.id, d.data())).toList()),
      );

  @override
  Stream<List<AttendanceRecord>> watchLecturerRecords(String lecturerId) => Fs.guard(
        _db
            .collectionGroup('attendance')
            .where('lecturerId', isEqualTo: lecturerId)
            .snapshots()
            .map((q) => q.docs.map((d) => Fs.attendance(d.reference.parent.parent?.id ?? '', d.id, d.data())).toList()),
      );

  @override
  Future<void> openQr(
    String slotId,
    String token,
    DateTime expiresAt, {
    String? prevToken,
    DateTime? prevExpiresAt,
    QrCodeEntry? code,
    List<String> dropCodes = const [],
    TvWrite? tv,
  }) =>
      _run(() {
        final b = _db.batch();
        b.update(_slots.doc(slotId), {
          'qrOpen': true,
          'qrToken': token,
          'qrExpiresAt': Timestamp.fromDate(expiresAt),
          'qrLeaseUntil': Timestamp.fromDate(expiresAt),
          if (prevToken != null && prevExpiresAt != null) ...{
            'qrTokenPrev': prevToken,
            'qrPrevExpiresAt': Timestamp.fromDate(prevExpiresAt),
          } else
            'qrTokenPrev': FieldValue.delete(),
        });
        if (code != null) {
          b.set(_codes.doc(code.code), {
            'lecturerId': code.lecturerId,
            'slotId': code.slotId,
            'classId': code.classId,
            'payload': code.payload,
            'expiresAt': Timestamp.fromDate(code.expiresAt),
          });
        }
        _drop(b, dropCodes);
        if (tv != null) b.set(_tv.doc(tv.key), Fs.tvMap(tv.lecturerId, tv.slotId, tv.frame));
        return b.commit();
      });

  @override
  Future<void> releaseQr(String slotId) => _run(() => _slots.doc(slotId).update({'qrLeaseUntil': FieldValue.serverTimestamp()}));

  @override
  Future<void> closeQr(String slotId, {List<String> dropCodes = const [], TvWrite? tv}) => _run(() {
        final b = _db.batch();
        b.update(_slots.doc(slotId), {
          'qrOpen': false,
          'qrToken': FieldValue.delete(),
          'qrTokenPrev': FieldValue.delete(),
        });
        _drop(b, dropCodes);
        if (tv != null) b.set(_tv.doc(tv.key), Fs.tvMap(tv.lecturerId, tv.slotId, tv.frame));
        return b.commit();
      });

  @override
  Future<void> createTv(TvWrite tv) => _run(() {
        final b = _db.batch();
        b.set(_tv.doc(tv.key), Fs.tvMap(tv.lecturerId, tv.slotId, tv.frame));
        b.update(_slots.doc(tv.slotId), {'tvKey': tv.key});
        return b.commit();
      });

  @override
  Future<void> pushTv(TvWrite tv) => _run(() => _tv.doc(tv.key).set(Fs.tvMap(tv.lecturerId, tv.slotId, tv.frame)));

  CollectionReference<Map<String, dynamic>> get _codes => _db.collection('qrCodes');
  CollectionReference<Map<String, dynamic>> get _tv => _db.collection('tv');

  void _drop(WriteBatch b, List<String> codes) {
    for (final c in codes) {
      b.delete(_codes.doc(c));
    }
  }

  Map<String, Object?> _copyOf(Slot s) => {
        'slotId': s.id,
        'lecturerId': s.lecturerId,
        'classId': s.classId,
        'subject': s.subject,
        'classCode': s.classCode,
        'term': s.term,
        'start': Timestamp.fromDate(s.start),
        'slotNo': s.slotNo,
        'room': s.room,
        'totalSlots': s.totalSlots,
      };

  @override
  Future<void> markManual(Slot slot, Student student, bool present) =>
      _run(() => _slots.doc(slot.id).collection('attendance').doc(student.code).set({
            ..._copyOf(slot),
            'studentCode': student.code,
            'studentName': student.name,
            'present': present,
            'source': AttendanceSource.manual.name,
            'final': false,
            'at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)));

  @override
  Future<void> closeSession(
    Slot slot,
    List<Student> roster,
    Map<String, AttendanceRecord> current, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final batch = _db.batch();
    var present = 0;
    for (final st in roster) {
      final rec = current[st.code];
      final isPresent = rec?.present ?? false;
      if (isPresent) present++;
      batch.set(
        _slots.doc(slot.id).collection('attendance').doc(st.code),
        {
          ..._copyOf(slot),
          'studentCode': st.code,
          'studentName': st.name,
          'present': isPresent,
          'source': (rec?.source ?? AttendanceSource.auto).name,
          'final': true,
        },
        SetOptions(merge: true),
      );
    }
    batch.update(_slots.doc(slot.id), {
      'closed': true,
      'closedAt': FieldValue.serverTimestamp(),
      'qrOpen': false,
      'qrToken': FieldValue.delete(),
      'qrTokenPrev': FieldValue.delete(),
      'presentCount': present,
      'absentCount': roster.length - present,
    });
    await _commit(batch, timeout);
  }

  @override
  Future<void> undoClose(Slot slot, List<Student> roster) async {
    final batch = _db.batch();
    for (final st in roster) {
      batch.set(_slots.doc(slot.id).collection('attendance').doc(st.code), {'final': false}, SetOptions(merge: true));
    }
    batch.update(_slots.doc(slot.id), {'closed': false, 'closedAt': FieldValue.delete()});
    await _commit(batch, const Duration(seconds: 8));
  }

  @override
  Future<void> waitForSync({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      await _db.waitForPendingWrites().timeout(timeout);
    } on TimeoutException {
      throw const SavedOfflineException();
    } catch (e) {
      throw Fs.error(e);
    }
  }

  Future<void> _commit(WriteBatch batch, Duration timeout) async {
    try {
      await batch.commit().timeout(timeout);
    } on TimeoutException {
      throw const SavedOfflineException();
    } catch (e) {
      throw Fs.error(e);
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
