import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../utils/app_exception.dart';
import 'firestore_mappers.dart';

/// Nội dung mã QR (CR-01): "qa2|slotId|token|lecturerId|classId|subject|classCode|term|startMs|slotNo|room|totalSlots".
/// Sinh viên không đọc được slot, nên thông tin slot đi kèm mã; Security Rules
/// đối chiếu từng trường với slot thật bằng get() trước khi cho ghi.
class QrPayload {
  const QrPayload({
    required this.slotId,
    required this.token,
    this.lecturerId = '',
    this.classId = '',
    this.subject = '',
    this.classCode = '',
    this.term = '',
    this.startMs = 0,
    this.slotNo = 0,
    this.room = '',
    this.totalSlots = 0,
  });

  factory QrPayload.forSlot(Slot s, String token) => QrPayload(
        slotId: s.id,
        token: token,
        lecturerId: s.lecturerId,
        classId: s.classId,
        subject: s.subject,
        classCode: s.classCode,
        term: s.term,
        startMs: s.start.millisecondsSinceEpoch,
        slotNo: s.slotNo,
        room: s.room,
        totalSlots: s.totalSlots,
      );

  final String slotId;
  final String token;
  final String lecturerId;
  final String classId;
  final String subject;
  final String classCode;
  final String term;
  final int startMs;
  final int slotNo;
  final String room;
  final int totalSlots;

  static const prefix = 'qa2';

  String encode() => [
        prefix, slotId, token, lecturerId, classId, subject, classCode, term, '$startMs', '$slotNo', room, '$totalSlots',
      ].map((x) => x.replaceAll('|', '/')).join('|');

  static QrPayload? tryParse(String raw) {
    final p = raw.trim().split('|');
    if (p.length != 12 || p[0] != prefix || p[1].isEmpty || p[2].isEmpty) return null;
    final start = int.tryParse(p[8]);
    final slotNo = int.tryParse(p[9]);
    final total = int.tryParse(p[11]);
    if (start == null || slotNo == null || total == null) return null;
    return QrPayload(
      slotId: p[1],
      token: p[2],
      lecturerId: p[3],
      classId: p[4],
      subject: p[5],
      classCode: p[6],
      term: p[7],
      startMs: start,
      slotNo: slotNo,
      room: p[10],
      totalSlots: total,
    );
  }

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startMs);
}

enum ScanFailure { invalid, expired, notInClass, network, alreadyClosed }

class ScanException implements Exception {
  const ScanException(this.reason);
  final ScanFailure reason;
}

class ScanResult {
  const ScanResult({required this.slot, required this.at});
  final Slot slot;
  final DateTime at;
}

abstract class StudentAttendanceRepository {
  /// Mọi bản ghi của một MSSV (collection group), cả chưa chốt.
  Stream<List<AttendanceRecord>> watchMine(String studentCode);

  /// Ghi có mặt từ mã QR. Security Rules kiểm token và hạn mã.
  Future<ScanResult> scan(QrPayload payload, {required String studentCode, required String studentName, required String uid});
}

class FirestoreStudentAttendanceRepository implements StudentAttendanceRepository {
  FirestoreStudentAttendanceRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<AttendanceRecord>> watchMine(String studentCode) => Fs.guard(
        _db
            .collectionGroup('attendance')
            .where('studentCode', isEqualTo: studentCode)
            .snapshots()
            .map((q) => q.docs.map((d) => Fs.attendance(d.reference.parent.parent?.id ?? '', d.id, d.data())).toList()),
      );

  @override
  Future<ScanResult> scan(QrPayload payload,
      {required String studentCode, required String studentName, required String uid}) async {
    final now = DateTime.now();
    try {
      // Một lần ghi; Security Rules kiểm token, hạn mã, lớp có MSSV này, và
      // mọi trường sao chép khớp slot thật (firebase/firestore.rules, validScan).
      await _db.collection('slots').doc(payload.slotId).collection('attendance').doc(studentCode).set({
        'slotId': payload.slotId,
        'lecturerId': payload.lecturerId,
        'classId': payload.classId,
        'subject': payload.subject,
        'classCode': payload.classCode,
        'term': payload.term,
        'start': Timestamp.fromMillisecondsSinceEpoch(payload.startMs),
        'slotNo': payload.slotNo,
        'room': payload.room,
        'totalSlots': payload.totalSlots,
        'studentCode': studentCode,
        'studentName': studentName,
        'scannerUid': uid,
        'present': true,
        'source': AttendanceSource.scan.name,
        'final': false,
        'token': payload.token,
        'at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const ScanException(ScanFailure.network);
    } catch (e) {
      final err = Fs.error(e);
      // permission-denied gộp: mã hết hạn, sai lớp, slot đã chốt (luật không nói lý do).
      throw ScanException(switch (err.kind) {
        AppErrorKind.network => ScanFailure.network,
        AppErrorKind.permission => ScanFailure.expired,
        _ => ScanFailure.invalid,
      });
    }
    final slot = Slot(
      id: payload.slotId,
      lecturerId: payload.lecturerId,
      classId: payload.classId,
      subject: payload.subject,
      classCode: payload.classCode,
      term: payload.term,
      start: payload.start,
      end: payload.start,
      slotNo: payload.slotNo,
      room: payload.room,
      studentCount: 0,
      totalSlots: payload.totalSlots,
    );
    return ScanResult(slot: slot, at: now);
  }
}
