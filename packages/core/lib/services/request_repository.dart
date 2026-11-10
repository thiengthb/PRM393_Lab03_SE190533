import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

/// Yêu cầu sửa (báo sai) từ sinh viên: SV-102 tạo, GV-105 duyệt hoặc từ chối.
abstract class RequestRepository {
  Stream<List<CorrectionRequest>> watchPending(String lecturerId);
  Stream<List<CorrectionRequest>> watchMine(String studentUid);
  Future<void> create({
    required String studentUid,
    required String studentCode,
    required String studentName,
    required AttendanceRecord session,
    required String reason,
    required String note,
  });
  Future<void> approve(CorrectionRequest r);
  Future<void> undoApprove(CorrectionRequest r);
  Future<void> reject(CorrectionRequest r, {required String reason, required String note});
}

class FirestoreRequestRepository implements RequestRepository {
  FirestoreRequestRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('requests');

  @override
  Stream<List<CorrectionRequest>> watchPending(String lecturerId) => Fs.guard(
        _col
            .where('lecturerId', isEqualTo: lecturerId)
            .where('status', isEqualTo: RequestStatus.pending.name)
            .snapshots()
            .map((q) => q.docs.map((d) => Fs.request(d.id, d.data())).toList()
              ..sort((a, b) => b.slotStart.compareTo(a.slotStart))),
      );

  @override
  Stream<List<CorrectionRequest>> watchMine(String studentUid) => Fs.guard(
        _col
            .where('studentUid', isEqualTo: studentUid)
            .snapshots()
            .map((q) => q.docs.map((d) => Fs.request(d.id, d.data())).toList()),
      );

  @override
  Future<void> create({
    required String studentUid,
    required String studentCode,
    required String studentName,
    required AttendanceRecord session,
    required String reason,
    required String note,
  }) async {
    try {
      // Một yêu cầu cho mỗi buổi: id cố định, gửi lại thì ghi đè.
      await _col.doc('${session.slotId}_$studentCode').set({
        'studentUid': studentUid,
        'studentCode': studentCode,
        'studentName': studentName,
        'lecturerId': session.lecturerId,
        'slotId': session.slotId,
        'classId': session.classId,
        'subject': session.subject,
        'slotStart': session.start == null ? null : Timestamp.fromDate(session.start!),
        'slotNo': session.slotNo,
        'reason': reason,
        'note': note,
        'status': RequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  DocumentReference<Map<String, dynamic>> _att(CorrectionRequest r) =>
      _db.collection('slots').doc(r.slotId).collection('attendance').doc(r.studentCode);

  // CR-26: đổi số đếm của slot chỉ khi present thật sự đổi. Trước đây duyệt đơn sau khi giảng
  // viên đã sửa tay em đó thành có mặt thì presentCount tính em hai lần. Transaction đọc bản ghi
  // điểm danh trước khi ghi.
  @override
  Future<void> approve(CorrectionRequest r) async {
    try {
      await _db.runTransaction((t) async {
        final att = await t.get(_att(r));
        final wasPresent = att.data()?['present'] == true;
        t.update(_col.doc(r.id), {'status': RequestStatus.approved.name, 'reviewedAt': FieldValue.serverTimestamp()});
        if (wasPresent) return;
        t.update(_att(r), {'present': true, 'source': AttendanceSource.correction.name});
        t.update(_db.collection('slots').doc(r.slotId), {
          'presentCount': FieldValue.increment(1),
          'absentCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  /// Chỉ trả về vắng nếu chính lần duyệt đơn đã đổi thành có mặt (nguồn `correction`).
  @override
  Future<void> undoApprove(CorrectionRequest r) async {
    try {
      await _db.runTransaction((t) async {
        final att = (await t.get(_att(r))).data();
        final byCorrection = att?['present'] == true && att?['source'] == AttendanceSource.correction.name;
        t.update(_col.doc(r.id), {'status': RequestStatus.pending.name, 'reviewedAt': FieldValue.delete()});
        if (!byCorrection) return;
        t.update(_att(r), {'present': false, 'source': AttendanceSource.auto.name});
        t.update(_db.collection('slots').doc(r.slotId), {
          'presentCount': FieldValue.increment(-1),
          'absentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> reject(CorrectionRequest r, {required String reason, required String note}) async {
    try {
      await _col.doc(r.id).update({
        'status': RequestStatus.rejected.name,
        'rejectReason': reason,
        'rejectNote': note,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
