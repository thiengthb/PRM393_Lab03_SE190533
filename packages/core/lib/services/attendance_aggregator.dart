import '../models/models.dart';
import '../utils/calendar.dart';

/// Tính số buổi vắng, ngưỡng và danh sách Chú ý từ bản ghi đã chốt.
/// Logic thuần (không Firebase) nên có unit test ở test/attendance_aggregator_test.dart.
class AttendanceAggregator {
  const AttendanceAggregator();

  /// Số buổi vắng theo (classId, MSSV), chỉ tính bản ghi đã chốt.
  Map<(String, String), int> absentCounts(Iterable<AttendanceRecord> records) {
    final out = <(String, String), int>{};
    for (final r in records) {
      if (!r.isFinal) continue;
      final k = (r.classId, r.studentCode);
      out[k] = (out[k] ?? 0) + (r.present ? 0 : 1);
    }
    return out;
  }

  /// Sinh viên sắp chạm hoặc vượt ngưỡng của mọi lớp, vượt trước, nhiều buổi vắng trước.
  List<StudentAbsence> attention(
    List<SchoolClass> classes,
    Iterable<AttendanceRecord> records, {
    required int percent,
  }) {
    final byId = {for (final c in classes) c.id: c};
    final names = <(String, String), String>{};
    for (final r in records) {
      names[(r.classId, r.studentCode)] = r.studentName;
    }
    final out = <StudentAbsence>[];
    absentCounts(records).forEach((k, absent) {
      final c = byId[k.$1];
      if (c == null || absent == 0) return;
      final a = StudentAbsence(
        student: Student(code: k.$2, name: names[k] ?? k.$2),
        schoolClass: c,
        absent: absent,
        limit: AttendanceMath.limit(c.totalSlots, percent),
      );
      if (a.level != AbsenceLevel.ok) out.add(a);
    });
    out.sort((a, b) {
      final byLevel = b.level.index.compareTo(a.level.index);
      if (byLevel != 0) return byLevel;
      final byAbsent = b.absent.compareTo(a.absent);
      return byAbsent != 0 ? byAbsent : a.student.name.compareTo(b.student.name);
    });
    return out;
  }

  /// Cả lớp với số buổi vắng (GV-103 tab Sinh viên), vắng nhiều trước.
  List<StudentAbsence> roster(
    SchoolClass c,
    List<Student> students,
    Iterable<AttendanceRecord> records, {
    required int percent,
  }) {
    final counts = absentCounts(records.where((r) => r.classId == c.id));
    final limit = AttendanceMath.limit(c.totalSlots, percent);
    final out = [
      for (final s in students) StudentAbsence(student: s, schoolClass: c, absent: counts[(c.id, s.code)] ?? 0, limit: limit),
    ];
    out.sort((a, b) {
      final d = b.absent.compareTo(a.absent);
      return d != 0 ? d : a.student.code.compareTo(b.student.code);
    });
    return out;
  }

  /// Gom bản ghi của một sinh viên theo môn (SV-001).
  List<SubjectAttendance> bySubject(Iterable<AttendanceRecord> mine, {required int percent}) {
    final groups = <String, List<AttendanceRecord>>{};
    for (final r in mine.where((r) => r.isFinal)) {
      groups.putIfAbsent(r.classId, () => []).add(r);
    }
    final out = <SubjectAttendance>[];
    groups.forEach((classId, list) {
      list.sort((a, b) => (b.start ?? DateTime(0)).compareTo(a.start ?? DateTime(0)));
      final first = list.first;
      out.add(SubjectAttendance(
        classId: classId,
        subject: first.subject,
        classCode: first.classCode,
        term: first.term,
        sessions: list,
        limit: AttendanceMath.limit(first.totalSlots, percent),
      ));
    });
    out.sort((a, b) {
      final t = Term.sortKey(b.term).compareTo(Term.sortKey(a.term));
      return t != 0 ? t : a.subject.compareTo(b.subject);
    });
    return out;
  }
}
