/// Lớp dữ liệu thuần Dart, dùng chung giữa service và ViewModel.
/// Không import Firebase ở đây: service chuyển Timestamp ↔ DateTime.
library;

enum UserRole { lecturer, student }

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.email,
    this.studentCode,
    this.reminderBeforeSlot = true,
    this.reminderUnclosed = true,
    this.lastImportAt,
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String email;
  final String? studentCode;
  final bool reminderBeforeSlot;
  final bool reminderUnclosed;
  final DateTime? lastImportAt;

  /// "Nguyễn Minh Quân" → "Quân" (dùng ở GV-093 “Chào thầy Quân”).
  String get givenName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? displayName : parts.last;
  }

  AppUser copyWith({bool? reminderBeforeSlot, bool? reminderUnclosed, DateTime? lastImportAt}) => AppUser(
        uid: uid,
        role: role,
        displayName: displayName,
        email: email,
        studentCode: studentCode,
        reminderBeforeSlot: reminderBeforeSlot ?? this.reminderBeforeSlot,
        reminderUnclosed: reminderUnclosed ?? this.reminderUnclosed,
        lastImportAt: lastImportAt ?? this.lastImportAt,
      );
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.lecturerId,
    required this.term,
    required this.subject,
    required this.code,
    required this.studentCount,
    required this.totalSlots,
  });

  final String id;
  final String lecturerId;
  final String term;
  final String subject;
  final String code;
  final int studentCount;
  final int totalSlots;

  /// "PRM393 · SE1801"
  String get label => '$subject · $code';
}

class Student {
  const Student({required this.code, required this.name, this.email});
  final String code; // MSSV
  final String name;
  final String? email;
}

enum SlotPhase { upcoming, live, unclosed, closed }

class Slot {
  const Slot({
    required this.id,
    required this.lecturerId,
    required this.classId,
    required this.subject,
    required this.classCode,
    required this.term,
    required this.start,
    required this.end,
    required this.slotNo,
    required this.room,
    required this.studentCount,
    this.closed = false,
    this.presentCount = 0,
    this.absentCount = 0,
    this.qrOpen = false,
    this.qrToken,
    this.qrExpiresAt,
  });

  final String id;
  final String lecturerId;
  final String classId;
  final String subject;
  final String classCode;
  final String term;
  final DateTime start;
  final DateTime end;
  final int slotNo;
  final String room;
  final int studentCount;
  final bool closed;
  final int presentCount;
  final int absentCount;
  final bool qrOpen;
  final String? qrToken;
  final DateTime? qrExpiresAt;

  String get classLabel => '$subject · $classCode';

  SlotPhase phaseAt(DateTime now) {
    if (closed) return SlotPhase.closed;
    if (now.isBefore(start)) return SlotPhase.upcoming;
    if (now.isBefore(end)) return SlotPhase.live;
    return SlotPhase.unclosed;
  }
}

enum AttendanceSource { scan, manual, auto, correction }

class AttendanceRecord {
  const AttendanceRecord({
    required this.slotId,
    required this.studentCode,
    required this.studentName,
    required this.present,
    required this.source,
    required this.isFinal,
    this.classId = '',
    this.subject = '',
    this.classCode = '',
    this.term = '',
    this.start,
    this.slotNo = 0,
    this.room = '',
    this.lecturerId = '',
    this.totalSlots = 0,
    this.at,
  });

  final String slotId;
  final String studentCode;
  final String studentName;
  final bool present;
  final AttendanceSource source;
  final bool isFinal;
  final String classId;
  final String subject;
  final String classCode;
  final String term;
  final DateTime? start;
  final int slotNo;
  final String room;
  final String lecturerId;

  /// Tổng số slot của lớp trong kỳ (để sinh viên tính ngưỡng vắng).
  final int totalSlots;
  final DateTime? at;
}

enum RequestStatus { pending, approved, rejected }

class CorrectionRequest {
  const CorrectionRequest({
    required this.id,
    required this.studentUid,
    required this.studentCode,
    required this.studentName,
    required this.lecturerId,
    required this.slotId,
    required this.classId,
    required this.subject,
    required this.slotStart,
    required this.slotNo,
    required this.reason,
    required this.note,
    required this.status,
    this.rejectReason,
  });

  final String id;
  final String studentUid;
  final String studentCode;
  final String studentName;
  final String lecturerId;
  final String slotId;
  final String classId;
  final String subject;
  final DateTime slotStart;
  final int slotNo;
  final String reason;
  final String note;
  final RequestStatus status;
  final String? rejectReason;
}

/// Một sinh viên với số buổi vắng trong một lớp (GV-001 Chú ý, GV-103, GV-104, GV-201).
class StudentAbsence {
  const StudentAbsence({
    required this.student,
    required this.schoolClass,
    required this.absent,
    required this.limit,
  });

  final Student student;
  final SchoolClass schoolClass;
  final int absent;
  final int limit;

  AbsenceLevel get level {
    if (absent > limit) return AbsenceLevel.over;
    if (absent >= limit - 1 && absent > 0) return AbsenceLevel.near;
    return AbsenceLevel.ok;
  }
}

enum AbsenceLevel { ok, near, over }

/// Một môn của sinh viên (SV-001, SV-002).
class SubjectAttendance {
  const SubjectAttendance({
    required this.classId,
    required this.subject,
    required this.classCode,
    required this.term,
    required this.sessions,
    required this.limit,
  });

  final String classId;
  final String subject;
  final String classCode;
  final String term;

  /// Buổi đã chốt, mới nhất trước.
  final List<AttendanceRecord> sessions;
  final int limit;

  int get attended => sessions.where((s) => s.present).length;
  int get held => sessions.length;
  int get absent => held - attended;

  /// Số buổi còn được vắng trước khi quá ngưỡng.
  int get remaining => limit - absent;

  AbsenceLevel get level {
    if (remaining < 0 || remaining == 0) return AbsenceLevel.over;
    if (remaining == 1) return AbsenceLevel.near;
    return AbsenceLevel.ok;
  }
}

class ReceivedNotification {
  const ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.appState,
    this.route,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// foreground, background, terminated (đề Lab 3: nhận ở cả 3 trạng thái).
  final String appState;

  /// Route mở khi chạm (data.route trong tin FCM), ví dụ /requests.
  final String? route;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'appState': appState,
        'route': route,
      };

  static ReceivedNotification fromJson(Map<String, Object?> j) => ReceivedNotification(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        receivedAt: DateTime.tryParse(j['receivedAt'] as String? ?? '') ?? DateTime.now(),
        appState: j['appState'] as String? ?? 'foreground',
        route: j['route'] as String?,
      );
}
