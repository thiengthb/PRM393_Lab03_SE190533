import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics chỉ có trên Android/iOS; trên web chỉ in ra console.
abstract class CrashService {
  Future<void> setUser(String? uid, {String? role, String? term});
  Future<void> recordNonFatal(Object error, StackTrace? stack, {required String where});
  void log(String message);
  void testCrash();
}

class FirebaseCrashService implements CrashService {
  FirebaseCrashService(this._c);

  final FirebaseCrashlytics? _c;

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
  void testCrash() {
    final c = _c;
    if (c == null) throw StateError('Test crash (web: Crashlytics không hỗ trợ)');
    c.crash();
  }
}
