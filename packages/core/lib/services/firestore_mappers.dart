import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../utils/app_exception.dart';

/// Chuyển document Firestore ↔ model. Chỉ service dùng file này.
abstract final class Fs {
  static String str(Map<String, dynamic> d, String k, [String def = '']) => (d[k] as String?) ?? def;
  static int integer(Map<String, dynamic> d, String k, [int def = 0]) => (d[k] as num?)?.toInt() ?? def;
  static bool boolean(Map<String, dynamic> d, String k, [bool def = false]) => (d[k] as bool?) ?? def;
  static DateTime? time(Map<String, dynamic> d, String k) => (d[k] as Timestamp?)?.toDate();

  static AppUser user(String uid, Map<String, dynamic> d) => AppUser(
        uid: uid,
        role: UserRole.values.asNameMap()[str(d, 'role')] ?? UserRole.user,
        displayName: str(d, 'displayName'),
        email: str(d, 'email'),
        studentCode: d['studentCode'] as String?,
        reminderBeforeSlot: boolean(d, 'reminderBeforeSlot', true),
        reminderUnclosed: boolean(d, 'reminderUnclosed', true),
        lastImportAt: time(d, 'lastImportAt'),
        lastInboxReadAt: time(d, 'lastInboxReadAt'),
      );

  static SchoolClass schoolClass(String id, Map<String, dynamic> d) => SchoolClass(
        id: id,
        lecturerId: str(d, 'lecturerId'),
        term: str(d, 'term'),
        subject: str(d, 'subject'),
        code: str(d, 'code'),
        studentCount: integer(d, 'studentCount'),
        totalSlots: integer(d, 'totalSlots'),
        status: ClassStatus.values.asNameMap()[str(d, 'status', 'pending')] ?? ClassStatus.pending,
        rejectReason: d['rejectReason'] as String?,
        lecturerName: str(d, 'lecturerName'),
        submittedAt: time(d, 'submittedAt'),
        reviewedAt: time(d, 'reviewedAt'),
      );

  static Subject subject(String id, Map<String, dynamic> d) => Subject(
        code: str(d, 'code', id),
        name: str(d, 'name'),
        status: str(d, 'status') == 'archived' ? CatalogStatus.archived : CatalogStatus.active,
        updatedAt: time(d, 'updatedAt'),
      );

  static Announcement announcement(String id, Map<String, dynamic> d) => Announcement(
        id: id,
        title: str(d, 'title'),
        body: str(d, 'body'),
        audience: AnnouncementAudience.values.asNameMap()[str(d, 'audience')] ?? AnnouncementAudience.all,
        archived: str(d, 'status') == 'archived',
        publishedAt: time(d, 'publishedAt'),
      );

  static InboxItem inbox(String id, Map<String, dynamic> d) => InboxItem(
        id: id,
        title: str(d, 'title'),
        body: str(d, 'body'),
        at: time(d, 'createdAt') ?? DateTime.now(),
        route: d['route'] as String?,
        personal: true,
      );

  static Student student(String id, Map<String, dynamic> d) =>
      Student(code: str(d, 'studentCode', id), name: str(d, 'name'), email: d['email'] as String?);

  static Slot slot(String id, Map<String, dynamic> d) => Slot(
        id: id,
        lecturerId: str(d, 'lecturerId'),
        classId: str(d, 'classId'),
        subject: str(d, 'subject'),
        classCode: str(d, 'classCode'),
        term: str(d, 'term'),
        start: time(d, 'start') ?? DateTime.fromMillisecondsSinceEpoch(0),
        end: time(d, 'end') ?? DateTime.fromMillisecondsSinceEpoch(0),
        slotNo: integer(d, 'slotNo'),
        room: str(d, 'room'),
        studentCount: integer(d, 'studentCount'),
        totalSlots: integer(d, 'totalSlots'),
        closed: boolean(d, 'closed'),
        presentCount: integer(d, 'presentCount'),
        absentCount: integer(d, 'absentCount'),
        qrOpen: boolean(d, 'qrOpen'),
        qrToken: d['qrToken'] as String?,
        qrExpiresAt: time(d, 'qrExpiresAt'),
        qrLeaseUntil: time(d, 'qrLeaseUntil'),
        tvKey: d['tvKey'] as String?,
      );

  static TvFrame tv(Map<String, dynamic> d) => TvFrame(
        title: str(d, 'title'),
        subtitle: str(d, 'subtitle'),
        open: boolean(d, 'open'),
        present: integer(d, 'present'),
        total: integer(d, 'total'),
        qr: d['qr'] as String?,
        code: d['code'] as String?,
        rotatedAt: time(d, 'rotatedAt'),
        rotateSeconds: integer(d, 'rotateSeconds', 12),
        endsAt: time(d, 'endsAt'),
        validUntil: time(d, 'validUntil') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  static Map<String, Object?> tvMap(String lecturerId, String slotId, TvFrame f) => {
        'lecturerId': lecturerId,
        'slotId': slotId,
        'title': f.title,
        'subtitle': f.subtitle,
        'open': f.open,
        'present': f.present,
        'total': f.total,
        'qr': f.qr,
        'code': f.code,
        'rotatedAt': f.rotatedAt == null ? null : Timestamp.fromDate(f.rotatedAt!),
        'rotateSeconds': f.rotateSeconds,
        'endsAt': f.endsAt == null ? null : Timestamp.fromDate(f.endsAt!),
        'validUntil': Timestamp.fromDate(f.validUntil),
      };

  static AttendanceRecord attendance(String slotId, String id, Map<String, dynamic> d) => AttendanceRecord(
        slotId: str(d, 'slotId', slotId),
        studentCode: str(d, 'studentCode', id),
        studentName: str(d, 'studentName'),
        present: boolean(d, 'present'),
        source: AttendanceSource.values.asNameMap()[str(d, 'source', 'scan')] ?? AttendanceSource.scan,
        isFinal: boolean(d, 'final'),
        classId: str(d, 'classId'),
        subject: str(d, 'subject'),
        classCode: str(d, 'classCode'),
        term: str(d, 'term'),
        start: time(d, 'start'),
        slotNo: integer(d, 'slotNo'),
        room: str(d, 'room'),
        lecturerId: str(d, 'lecturerId'),
        totalSlots: integer(d, 'totalSlots'),
        at: time(d, 'at'),
      );

  static CorrectionRequest request(String id, Map<String, dynamic> d) => CorrectionRequest(
        id: id,
        studentUid: str(d, 'studentUid'),
        studentCode: str(d, 'studentCode'),
        studentName: str(d, 'studentName'),
        lecturerId: str(d, 'lecturerId'),
        slotId: str(d, 'slotId'),
        classId: str(d, 'classId'),
        subject: str(d, 'subject'),
        slotStart: time(d, 'slotStart') ?? DateTime.fromMillisecondsSinceEpoch(0),
        slotNo: integer(d, 'slotNo'),
        reason: str(d, 'reason'),
        note: str(d, 'note'),
        status: RequestStatus.values.asNameMap()[str(d, 'status', 'pending')] ?? RequestStatus.pending,
        rejectReason: d['rejectReason'] as String?,
      );

  /// Đổi lỗi Firebase thành AppException để ViewModel hiện câu ngắn.
  static AppException error(Object e) {
    if (e is AppException) return e;
    // Ghi lỗi gốc ra console (cả bản release): lỗi chỉ có trên Firebase thật, như thiếu chỉ mục, mới đọc được
    // mã và link tạo chỉ mục, vì màn hình chỉ hiện câu chung.
    debugPrint('Firestore error: $e');
    // On web, some calls (aggregation queries) surface the raw JS FirebaseError instead of a
    // FirebaseException; its text carries the code as "[code=failed-precondition]".
    final code = e is FirebaseException ? e.code : _webCode(e);
    if (code != null) {
      return switch (code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
          AppException(AppErrorKind.network, 'Mất kết nối mạng', cause: e),
        'permission-denied' || 'unauthorized' || 'unauthenticated' =>
          AppException(AppErrorKind.permission, 'Không có quyền truy cập', cause: e),
        'not-found' || 'object-not-found' => AppException(AppErrorKind.notFound, 'Không tìm thấy dữ liệu', cause: e),
        'resource-exhausted' || 'quota-exceeded' => AppException(AppErrorKind.quota, 'Hệ thống đang quá tải', cause: e),
        'canceled' || 'cancelled' => AppException(AppErrorKind.cancelled, 'Đã hủy', cause: e),
        'failed-precondition' => AppException(AppErrorKind.invalid, 'Thiếu chỉ mục dữ liệu', cause: e),
        _ => AppException(AppErrorKind.unknown, 'Có lỗi, hãy thử lại', cause: e),
      };
    }
    return AppException(AppErrorKind.unknown, 'Có lỗi, hãy thử lại', cause: e);
  }

  static final _codePattern = RegExp(r'code=([a-z-]+)|\b(?:cloud_firestore|firestore)/([a-z-]+)');

  static String? _webCode(Object e) {
    final m = _codePattern.firstMatch(e.toString());
    return m == null ? null : (m.group(1) ?? m.group(2));
  }

  /// Bọc stream Firestore: lỗi đổi thành AppException.
  static Stream<T> guard<T>(Stream<T> s) => s.handleError((Object e) => throw error(e));
}
