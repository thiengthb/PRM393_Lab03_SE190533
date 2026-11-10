import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Bật App Check cho Firestore và AI Logic. Lỗi không chặn app: khi chưa bật
/// “Enforce” trên console, request không có token vẫn chạy; khi đã bật, Firestore trả
/// permission-denied và màn hiện trạng thái lỗi như mọi lỗi quyền khác.
Future<void> activateAppCheck() async {
  const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  try {
    if (kIsWeb && siteKey.isEmpty) {
      debugPrint('App Check: thiếu RECAPTCHA_SITE_KEY, web chạy không có token');
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaV3Provider(siteKey) : null,
      // Decision 004: AI Logic requires App Check and a sideloaded APK fails Play Integrity, so
      // the demo build carries one debug token registered in the console (never in the repo).
      // Without it: debug builds print a random token to Logcat, release builds use Play Integrity.
      providerAndroid: debugToken.isNotEmpty
          ? AndroidDebugProvider(debugToken: debugToken)
          : (kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider()),
    );
  } catch (e) {
    debugPrint('App Check: $e');
  }
}
