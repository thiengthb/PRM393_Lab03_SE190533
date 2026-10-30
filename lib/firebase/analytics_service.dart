import 'package:firebase_analytics/firebase_analytics.dart';

/// Kế hoạch sự kiện: docs/analytics-plan.md. Không gửi email, tên hay MSSV.
abstract class AnalyticsService {
  Future<void> setUser(String? uid, {String? role});
  Future<void> login(String method);
  Future<void> signUp(String method, String role);
  Future<void> logout();
  Future<void> importClasses({required int classCount, required int studentCount, required int rowErrors});
  Future<void> sessionOpen({required String classId, required String subject, required int slotNo});
  Future<void> attendanceClose({
    required String classId,
    required int present,
    required int absent,
    required int manual,
    required int durationSec,
    required bool offline,
  });
  Future<void> viewClass({required String classId, required String subject});
  Future<void> viewStudent({required String classId, required int absent, required int limit});
  Future<void> reminderSend({required String classId, required int absent});
  Future<void> qrScan({required String result});
  Future<void> correctionSubmit({required String subject, required String reason});
  Future<void> correctionReview({required String decision, String? reason});
  Future<void> exportReport({required String classId, required int fileSizeKb});
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._a);

  final FirebaseAnalytics _a;

  Future<void> _log(String name, Map<String, Object> p) async {
    try {
      await _a.logEvent(name: name, parameters: p);
    } catch (_) {
      // Analytics không được làm hỏng luồng chính.
    }
  }

  @override
  Future<void> setUser(String? uid, {String? role}) async {
    try {
      await _a.setUserId(id: uid);
      if (role != null) await _a.setUserProperty(name: 'role', value: role);
    } catch (_) {}
  }

  @override
  Future<void> login(String method) async {
    try {
      await _a.logLogin(loginMethod: method);
    } catch (_) {}
  }

  @override
  Future<void> signUp(String method, String role) async {
    try {
      await _a.logSignUp(signUpMethod: method, parameters: {'role': role});
    } catch (_) {}
  }

  @override
  Future<void> logout() => _log('logout', {});

  @override
  Future<void> importClasses({required int classCount, required int studentCount, required int rowErrors}) =>
      _log('import_classes', {'class_count': classCount, 'student_count': studentCount, 'row_errors': rowErrors});

  @override
  Future<void> sessionOpen({required String classId, required String subject, required int slotNo}) =>
      _log('attendance_session_open', {'class_id': classId, 'subject': subject, 'slot_no': slotNo});

  @override
  Future<void> attendanceClose({
    required String classId,
    required int present,
    required int absent,
    required int manual,
    required int durationSec,
    required bool offline,
  }) =>
      _log('attendance_close', {
        'class_id': classId,
        'present_count': present,
        'absent_count': absent,
        'manual_count': manual,
        'duration_sec': durationSec,
        'offline': offline ? 1 : 0,
      });

  @override
  Future<void> viewClass({required String classId, required String subject}) =>
      _log('view_class', {'class_id': classId, 'subject': subject});

  @override
  Future<void> viewStudent({required String classId, required int absent, required int limit}) =>
      _log('view_student', {'class_id': classId, 'absent_count': absent, 'absence_limit': limit});

  @override
  Future<void> reminderSend({required String classId, required int absent}) =>
      _log('reminder_send', {'class_id': classId, 'absent_count': absent});

  @override
  Future<void> qrScan({required String result}) => _log('qr_scan', {'result': result});

  @override
  Future<void> correctionSubmit({required String subject, required String reason}) =>
      _log('correction_submit', {'subject': subject, 'reason': reason});

  @override
  Future<void> correctionReview({required String decision, String? reason}) =>
      _log('correction_review', {'decision': decision, 'reason': ?reason});

  @override
  Future<void> exportReport({required String classId, required int fileSizeKb}) =>
      _log('export_report', {'class_id': classId, 'file_size_kb': fileSizeKb});
}
