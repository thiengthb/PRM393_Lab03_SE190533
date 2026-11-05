/// Lớp dữ liệu thuần Dart, dùng chung giữa service và ViewModel.
/// Không import Firebase ở đây: service chuyển Timestamp ↔ DateTime.
library;

/// `user`: tài khoản mới ở trang quản trị, chưa được cấp quyền. Chỉ Admin đổi vai trò.
enum UserRole {
  lecturer,
  student,
  staff,
  admin,
  user;

  bool get isStaff => this == UserRole.staff || this == UserRole.admin;

  String get label => switch (this) {
        UserRole.lecturer => 'Giảng viên',
        UserRole.student => 'Sinh viên',
        UserRole.staff => 'Giáo vụ',
        UserRole.admin => 'Quản trị',
        UserRole.user => 'Chưa cấp quyền',
      };
}

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
    this.lastInboxReadAt,
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String email;
  final String? studentCode;
  final bool reminderBeforeSlot;
  final bool reminderUnclosed;
  final DateTime? lastImportAt;

  /// Mốc đã đọc hộp thư: tin mới hơn mốc này là chưa đọc.
  final DateTime? lastInboxReadAt;

  /// "Nguyễn Minh Quân" → "Quân" (dùng ở GV-093 “Chào Quân”).
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
        lastInboxReadAt: lastInboxReadAt,
      );
}

/// pending → approved | rejected do giáo vụ duyệt; rejected → pending khi giảng viên nhập lại.
enum ClassStatus { pending, approved, rejected }

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.lecturerId,
    required this.term,
    required this.subject,
    required this.code,
    required this.studentCount,
    required this.totalSlots,
    this.status = ClassStatus.approved,
    this.rejectReason,
    this.lecturerName = '',
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String lecturerId;
  final String term;
  final String subject;
  final String code;
  final int studentCount;
  final int totalSlots;
  final ClassStatus status;
  final String? rejectReason;

  /// Tên giảng viên, chép vào lớp để hàng đợi duyệt không phải đọc `users`.
  final String lecturerName;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  bool get isApproved => status == ClassStatus.approved;

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

/// Một chấm dưới ngày trong lịch tháng GV-001 = một slot (Figma `239:4241`).
enum DayDot { closed, unclosed, live, upcoming }

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
    this.totalSlots = 0,
    this.closed = false,
    this.presentCount = 0,
    this.absentCount = 0,
    this.qrOpen = false,
    this.qrToken,
    this.qrExpiresAt,
    this.tvKey,
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
  final int totalSlots;
  final bool closed;
  final int presentCount;
  final int absentCount;
  final bool qrOpen;
  final String? qrToken;
  final DateTime? qrExpiresAt;

  /// Khoá link màn chiếu TV-001 của slot này, tạo khi giảng viên bấm Chiếu lên TV.
  final String? tvKey;

  String get classLabel => '$subject · $classCode';

  SlotPhase phaseAt(DateTime now) {
    if (closed) return SlotPhase.closed;
    if (now.isBefore(start)) return SlotPhase.upcoming;
    if (now.isBefore(end)) return SlotPhase.live;
    return SlotPhase.unclosed;
  }

  /// Còn mở lại mã QR được không: chỉ khi giờ học chưa kết thúc. Slot đã qua giờ
  /// (FL-2 “Chốt ngay”) chỉ chốt tay, sinh viên không còn ở lớp để quét.
  bool canReopenQrAt(DateTime now) => !closed && now.isBefore(end);
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

  /// Giống phía giảng viên: quá ngưỡng là fail (over), còn 1 hoặc 0 buổi được vắng là near.
  AbsenceLevel get level {
    if (remaining < 0) return AbsenceLevel.over;
    if (remaining <= 1 && absent > 0) return AbsenceLevel.near;
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

// ---------- Final: danh mục môn, thông báo, hộp thư, báo cáo ----------

enum CatalogStatus { active, archived }

/// Môn học do giáo vụ quản lý (web admin); app đọc để kiểm file nhập lớp.
class Subject {
  const Subject({required this.code, required this.name, this.status = CatalogStatus.active, this.updatedAt});
  final String code;
  final String name;
  final CatalogStatus status;
  final DateTime? updatedAt;

  bool get isActive => status == CatalogStatus.active;
}

enum AnnouncementAudience {
  all,
  lecturer,
  student;

  String get label => switch (this) {
        AnnouncementAudience.all => 'Tất cả',
        AnnouncementAudience.lecturer => 'Giảng viên',
        AnnouncementAudience.student => 'Sinh viên',
      };
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.archived,
    this.publishedAt,
  });
  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final bool archived;
  final DateTime? publishedAt;
}

/// Một dòng trong hộp thư: thông báo chung hoặc tin riêng (kết quả duyệt lớp).
class InboxItem {
  const InboxItem({required this.id, required this.title, required this.body, required this.at, this.route, this.personal = false});
  final String id;
  final String title;
  final String body;
  final DateTime at;
  final String? route;
  final bool personal;
}

/// Metadata một lần xuất PDF, ghi vào `reports/{id}` (file ở trên máy và trên Cloudinary).
class ReportRecord {
  const ReportRecord({
    required this.fileName,
    required this.classId,
    required this.sizeKb,
    this.destination = 'device',
    this.url,
  });
  final String fileName;
  final String classId;
  final int sizeKb;

  /// `cloudinary` khi đã tải lên (D-L3-18), `device` khi chỉ lưu trên máy.
  final String destination;

  /// Link Cloudinary; null khi chỉ lưu trên máy.
  final String? url;
}

/// Một khung màn chiếu TV-001, lưu ở `tv/{khoá}`. Máy chiếu không đăng nhập, chỉ đọc đúng
/// tài liệu này nên mọi thứ cần hiện phải nằm sẵn trong đó.
class TvFrame {
  const TvFrame({
    required this.title,
    required this.subtitle,
    required this.open,
    required this.present,
    required this.total,
    required this.validUntil,
    this.qr,
    this.code,
    this.rotatedAt,
    this.rotateSeconds = 12,
    this.endsAt,
  });

  /// "PRM393 · SE1801".
  final String title;

  /// "P.305 · 07:00 – 09:15".
  final String subtitle;

  /// false: .D1 Đã đóng mã.
  final bool open;
  final int present;
  final int total;

  /// Nội dung QR (QrPayload.encode) và mã số đang dùng; null khi đã đóng mã.
  final String? qr;
  final String? code;
  final DateTime? rotatedAt;
  final int rotateSeconds;

  /// Hết giờ mở mã, cho dòng "Còn mm:ss".
  final DateTime? endsAt;

  /// Sau thời điểm này link không đọc được nữa (luật Firestore).
  final DateTime validUntil;
}

// ---------- AI: gợi ý lời nhắc (đề Final mục 8, mức 2) ----------

/// Dữ liệu gửi cho AI: chỉ có số liệu và mã môn, không có tên, email, MSSV.
class ReminderInput {
  const ReminderInput({required this.subject, required this.absent, required this.limit, required this.held, required this.total});
  final String subject;
  final int absent;
  final int limit;
  final int held;
  final int total;
}

/// Kết quả có cấu trúc từ AI. [parse] từ chối JSON thiếu trường hoặc sai kiểu.
class ReminderDraft {
  const ReminderDraft({required this.tone, required this.message, required this.nextStep});

  /// gentle | firm | urgent.
  final String tone;
  final String message;
  final String nextStep;

  static const tones = {'gentle', 'firm', 'urgent'};
  static const maxLength = 300;

  /// Câu đầy đủ điền vào ô soạn, người dùng còn sửa được.
  String get fullText => nextStep.isEmpty ? message : '$message $nextStep';

  static ReminderDraft? parse(Map<String, Object?> j) {
    final tone = j['tone'];
    final message = j['message'];
    final nextStep = j['next_step'];
    if (tone is! String || message is! String || nextStep is! String) return null;
    final m = message.trim();
    final n = nextStep.trim();
    if (!tones.contains(tone) || m.isEmpty) return null;
    if ('$m $n'.length > maxLength) return null;
    return ReminderDraft(tone: tone, message: m, nextStep: n);
  }
}
