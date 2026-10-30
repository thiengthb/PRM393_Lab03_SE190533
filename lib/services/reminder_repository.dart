import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/calendar.dart';
import 'firestore_mappers.dart';

/// Lời nhắc giảng viên gửi sinh viên (GV-OV3). Mỗi sinh viên tối đa 1 lần mỗi ngày.
abstract class ReminderRepository {
  Future<bool> sentToday(String classId, String studentCode, DateTime now);
  Future<void> send({
    required String lecturerId,
    required String classId,
    required String studentCode,
    required String toEmail,
    required String message,
    required DateTime now,
  });
}

class FirestoreReminderRepository implements ReminderRepository {
  FirestoreReminderRepository(this._db);

  final FirebaseFirestore _db;

  String _id(String classId, String code, DateTime now) =>
      '${classId}_${code}_${now.year}${VnDate.two(now.month)}${VnDate.two(now.day)}';

  @override
  Future<bool> sentToday(String classId, String studentCode, DateTime now) async {
    try {
      final s = await _db.collection('reminders').doc(_id(classId, studentCode, now)).get();
      return s.exists;
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> send({
    required String lecturerId,
    required String classId,
    required String studentCode,
    required String toEmail,
    required String message,
    required DateTime now,
  }) async {
    try {
      await _db.collection('reminders').doc(_id(classId, studentCode, now)).set({
        'lecturerId': lecturerId,
        'classId': classId,
        'studentCode': studentCode,
        'toEmail': toEmail,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
