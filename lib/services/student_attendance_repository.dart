import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../utils/app_exception.dart';
import 'firestore_mappers.dart';

/// Nội dung mã QR: "qa1|<slotId>|<token>".
class QrPayload {
  const QrPayload(this.slotId, this.token);
  final String slotId;
  final String token;

  static const prefix = 'qa1';

  String encode() => '$prefix|$slotId|$token';

  static QrPayload? tryParse(String raw) {
    final p = raw.trim().split('|');
    if (p.length != 3 || p[0] != prefix || p[1].isEmpty || p[2].isEmpty) return null;
    return QrPayload(p[1], p[2]);
  }
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
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db.collection('slots').doc(payload.slotId).get();
    } catch (e) {
      final err = Fs.error(e);
      throw ScanException(err.kind == AppErrorKind.network ? ScanFailure.network : ScanFailure.invalid);
    }
    if (!snap.exists) throw const ScanException(ScanFailure.invalid);
    final slot = Fs.slot(snap.id, snap.data()!);
    if (slot.closed) throw const ScanException(ScanFailure.alreadyClosed);
    final now = DateTime.now();
    if (!slot.qrOpen || slot.qrToken != payload.token || (slot.qrExpiresAt?.isBefore(now) ?? true)) {
      throw const ScanException(ScanFailure.expired);
    }
    final enrolled = await _db
        .collection('classes')
        .doc(slot.classId)
        .collection('students')
        .doc(studentCode)
        .get()
        .then((s) => s.exists)
        .catchError((Object _) => false);
    if (!enrolled) throw const ScanException(ScanFailure.notInClass);
    try {
      await _db.collection('slots').doc(slot.id).collection('attendance').doc(studentCode).set({
        'slotId': slot.id,
        'lecturerId': slot.lecturerId,
        'classId': slot.classId,
        'subject': slot.subject,
        'classCode': slot.classCode,
        'term': slot.term,
        'start': Timestamp.fromDate(slot.start),
        'slotNo': slot.slotNo,
        'room': slot.room,
        'totalSlots': slot.totalSlots,
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
      throw ScanException(switch (err.kind) {
        AppErrorKind.network => ScanFailure.network,
        AppErrorKind.permission => ScanFailure.expired,
        _ => ScanFailure.invalid,
      });
    }
    return ScanResult(slot: slot, at: now);
  }
}
