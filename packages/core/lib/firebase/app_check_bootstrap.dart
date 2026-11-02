import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Bật App Check cho Firestore và AI Logic. Lỗi không chặn app: khi chưa bật
/// “Enforce” trên console, request không có token vẫn chạy; khi đã bật, Firestore trả
/// permission-denied và màn hiện trạng thái lỗi như mọi lỗi quyền khác.
Future<void> activateAppCheck() async {
  const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  try {
    if (kIsWeb && siteKey.isEmpty) {
      debugPrint('App Check: thiếu RECAPTCHA_SITE_KEY, web chạy không có token');
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaV3Provider(siteKey) : null,
      // Bản debug in debug token ra Logcat; dán token đó vào console → App Check.
      providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    );
  } catch (e) {
    debugPrint('App Check: $e');
  }
}
