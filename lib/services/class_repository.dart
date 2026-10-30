import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/import_models.dart';
import '../models/models.dart';
import '../utils/calendar.dart';
import 'firestore_mappers.dart';

abstract class ClassRepository {
  Stream<List<SchoolClass>> watchClasses(String lecturerId);
  Stream<List<Student>> watchStudents(String classId);
  Future<List<Student>> students(String classId);

  /// Ghi lớp, sinh viên và slot của cả kỳ. [onProgress] nhận số lớp đã ghi.
  Future<void> importClasses(
    String lecturerId,
    ImportPreview preview, {
    required DateTime now,
    void Function(int done, int total)? onProgress,
  });
}

class FirestoreClassRepository implements ClassRepository {
  FirestoreClassRepository(this._db);

  final FirebaseFirestore _db;

  static String classIdOf(String lecturerId, String term, String subject, String code) =>
      '${lecturerId}_${term.replaceAll(' ', '')}_${subject}_$code'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');

  @override
  Stream<List<SchoolClass>> watchClasses(String lecturerId) => Fs.guard(
        _db.collection('classes').where('lecturerId', isEqualTo: lecturerId).snapshots().map(
              (q) => q.docs.map((d) => Fs.schoolClass(d.id, d.data())).toList()
                ..sort((a, b) => a.label.compareTo(b.label)),
            ),
      );

  @override
  Stream<List<Student>> watchStudents(String classId) => Fs.guard(
        _db.collection('classes').doc(classId).collection('students').snapshots().map(
              (q) => q.docs.map((d) => Fs.student(d.id, d.data())).toList()..sort((a, b) => a.code.compareTo(b.code)),
            ),
      );

  @override
  Future<List<Student>> students(String classId) async {
    try {
      final q = await _db.collection('classes').doc(classId).collection('students').get();
      return q.docs.map((d) => Fs.student(d.id, d.data())).toList()..sort((a, b) => a.code.compareTo(b.code));
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> importClasses(
    String lecturerId,
    ImportPreview preview, {
    required DateTime now,
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      var done = 0;
      for (final c in preview.classes) {
        var batch = _db.batch();
        var ops = 0;
        Future<void> flushIfFull() async {
          if (ops >= 450) {
            await batch.commit();
            batch = _db.batch();
            ops = 0;
          }
        }

        final classId = classIdOf(lecturerId, preview.term, c.subject, c.code);
        final start = VnDate.mondayOf(c.termStart ?? Term.startOf(now));
        final slots = <(DateTime, DateTime, WeeklySlot)>[];
        for (var w = 0; w < preview.weeks; w++) {
          for (final ws in c.weekly) {
            final day = start.add(Duration(days: w * 7 + ws.weekday - 1));
            final (s, e) = SlotTimes.on(day, ws.slotNo);
            slots.add((s, e, ws));
          }
        }

        batch.set(
          _db.collection('classes').doc(classId),
          {
            'lecturerId': lecturerId,
            'term': preview.term,
            'subject': c.subject,
            'code': c.code,
            'studentCount': c.students.length,
            'totalSlots': slots.length,
            'importedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        ops++;

        for (final s in c.students) {
          batch.set(_db.collection('classes').doc(classId).collection('students').doc(s.code), {
            'studentCode': s.code,
            'name': s.name,
            if (s.email != null) 'email': s.email,
            'lecturerId': lecturerId,
          });
          ops++;
          await flushIfFull();
        }

        for (final (s, e, ws) in slots) {
          final id = '${classId}_${s.year}${VnDate.two(s.month)}${VnDate.two(s.day)}_s${ws.slotNo}';
          // merge: nhập lại không xóa kết quả điểm danh đã chốt.
          batch.set(
            _db.collection('slots').doc(id),
            {
              'lecturerId': lecturerId,
              'classId': classId,
              'subject': c.subject,
              'classCode': c.code,
              'term': preview.term,
              'start': Timestamp.fromDate(s),
              'end': Timestamp.fromDate(e),
              'slotNo': ws.slotNo,
              'room': ws.room,
              'studentCount': c.students.length,
              'totalSlots': slots.length,
            },
            SetOptions(merge: true),
          );
          ops++;
          await flushIfFull();
        }
        await batch.commit();
        done++;
        onProgress?.call(done, preview.classes.length);
      }
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
