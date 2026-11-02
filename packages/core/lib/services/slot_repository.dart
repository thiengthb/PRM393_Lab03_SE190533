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

abstract class SlotRepository {
  Stream<List<Slot>> watchSlots(String lecturerId);
  Stream<Slot?> watchSlot(String slotId);
  Stream<List<AttendanceRecord>> watchAttendance(String slotId);

  /// Mọi bản ghi điểm danh của giảng viên (collection group), để đếm buổi vắng.
  Stream<List<AttendanceRecord>> watchLecturerRecords(String lecturerId);

  Future<void> openQr(String slotId, String token, DateTime expiresAt);
  Future<void> closeQr(String slotId);
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
  Future<void> openQr(String slotId, String token, DateTime expiresAt) => _run(() => _slots.doc(slotId).update({
        'qrOpen': true,
        'qrToken': token,
        'qrExpiresAt': Timestamp.fromDate(expiresAt),
      }));

  @override
  Future<void> closeQr(String slotId) => _run(() => _slots.doc(slotId).update({
        'qrOpen': false,
        'qrToken': FieldValue.delete(),
      }));

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
