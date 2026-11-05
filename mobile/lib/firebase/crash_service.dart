import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_attend_core/models/crash_report.dart';

import 'crash_report_sink.dart';

/// Crashlytics chỉ có trên Android/iOS; trên web và Windows chỉ in ra console.
/// Mọi nền tảng đều ghi kèm bản tóm tắt vào Firestore (nếu có [CrashReportSink]) cho web admin.
abstract class CrashService {
  Future<void> setUser(String? uid, {String? role, String? term});
  Future<void> recordNonFatal(Object error, StackTrace? stack, {required String where});
  void log(String message);
  Future<void> testCrash();
}

class FirebaseCrashService implements CrashService {
  FirebaseCrashService(this._c, {CrashReportSink? report}) : _report = report;

  final FirebaseCrashlytics? _c;
  final CrashReportSink? _report;

  @override
  Future<void> setUser(String? uid, {String? role, String? term}) async {
    final c = _c;
    if (c == null) return;
    await c.setUserIdentifier(uid ?? '');
    if (role != null) await c.setCustomKey('role', role);
    if (term != null) await c.setCustomKey('term', term);
  }

  @override
  Future<void> recordNonFatal(Object error, StackTrace? stack, {required String where}) async {
    await _report?.call(CrashKind.nonFatal, where, '$error');
    final c = _c;
    if (c == null) {
      debugPrint('non-fatal [$where]: $error');
      return;
    }
    await c.setCustomKey('last_error_where', where);
    await c.recordError(error, stack, reason: where, fatal: false);
  }

  @override
  void log(String message) => _c?.log(message);

  @override
  Future<void> testCrash() async {
    // Ghi tóm tắt trước: sau c.crash() tiến trình chết ngay.
    await _report?.call(CrashKind.testCrash, 'demo_test_crash', 'Test crash từ Khu demo');
    final c = _c;
    if (c == null) throw StateError('Test crash (web: Crashlytics không hỗ trợ)');
    c.crash();
  }
}
