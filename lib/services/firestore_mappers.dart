import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/models.dart';
import '../utils/app_exception.dart';

/// Chuyển document Firestore ↔ model. Chỉ service dùng file này.
abstract final class Fs {
  static String str(Map<String, dynamic> d, String k, [String def = '']) => (d[k] as String?) ?? def;
  static int integer(Map<String, dynamic> d, String k) => (d[k] as num?)?.toInt() ?? 0;
  static bool boolean(Map<String, dynamic> d, String k, [bool def = false]) => (d[k] as bool?) ?? def;
  static DateTime? time(Map<String, dynamic> d, String k) => (d[k] as Timestamp?)?.toDate();

  static AppUser user(String uid, Map<String, dynamic> d) => AppUser(
        uid: uid,
        role: str(d, 'role') == 'student' ? UserRole.student : UserRole.lecturer,
        displayName: str(d, 'displayName'),
        email: str(d, 'email'),
        studentCode: d['studentCode'] as String?,
        reminderBeforeSlot: boolean(d, 'reminderBeforeSlot', true),
        reminderUnclosed: boolean(d, 'reminderUnclosed', true),
        lastImportAt: time(d, 'lastImportAt'),
      );

  static SchoolClass schoolClass(String id, Map<String, dynamic> d) => SchoolClass(
        id: id,
        lecturerId: str(d, 'lecturerId'),
        term: str(d, 'term'),
        subject: str(d, 'subject'),
        code: str(d, 'code'),
        studentCount: integer(d, 'studentCount'),
        totalSlots: integer(d, 'totalSlots'),
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
      );

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
    if (e is FirebaseException) {
      return switch (e.code) {
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

  /// Bọc stream Firestore: lỗi đổi thành AppException.
  static Stream<T> guard<T>(Stream<T> s) => s.handleError((Object e) => throw error(e));
}
