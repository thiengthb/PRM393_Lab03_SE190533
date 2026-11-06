import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/firebase/app_check_bootstrap.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'router.dart' show isTvRoute;
import 'package:quick_attend_core/firebase/config_service.dart';
import 'package:quick_attend_core/utils/platform.dart';
import 'package:quick_attend_core/models/crash_report.dart';
import 'firebase/crash_report_sink.dart';
import 'firebase/messaging_service.dart';
import 'firebase_options.dart';
import 'providers.dart';

/// Nhận tin FCM khi app chạy nền hoặc đã tắt: lưu vào trung tâm thông báo.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationStore.add(NotificationStore.fromMessage(message, 'background'));
}

const _emulatorHost = String.fromEnvironment('EMULATOR_HOST');

/// Remote Config. Bản Windows dùng SDK C++ của Firebase: lỗi hoặc treo thì dùng giá trị
/// mặc định trong app để màn đầu vẫn mở được; Gợi ý AI luôn tắt trên desktop.
Future<ConfigService> _initConfig() async {
  final rc = FirebaseConfigService(FirebaseRemoteConfig.instance, forceAiOff: isDesktop);
  if (!isDesktop) {
    await rc.init();
    return rc;
  }
  try {
    await rc.init().timeout(const Duration(seconds: 15));
    return rc;
  } catch (e) {
    debugPrint('Remote Config trên desktop: $e');
    return const StaticConfigService();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Đường dẫn không có # để link màn chiếu gõ được: hereby-se190533.web.app/tv/<khoá>.
  // Hosting đã chuyển mọi đường về index.html (firebase.json).
  usePathUrlStrategy();
  final tv = kIsWeb && isTvRoute(Uri.base.path);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check phải bật trước lần gọi Firestore / AI Logic đầu tiên. Windows chỉ có debug provider
  // (không có chứng thực thiết bị như Play Integrity), nên bản desktop không bật App Check.
  if (!isDesktop) await activateAppCheck();

  // Firestore giữ dữ liệu trên máy: chốt điểm danh lúc mất mạng vẫn không mất (GV-OV2).
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Chạy với Firebase Emulator (chụp màn, demo, ARTEMIS không đụng dữ liệu thật):
  // --dart-define=EMULATOR_HOST=localhost (web) hoặc 127.0.0.1 (Android, kèm `adb reverse`),
  // cổng như firebase.json (auth 9099, firestore 8080). Tắt tự đổi sang 10.0.2.2 để
  // điện thoại thật qua `adb reverse` cũng chạy được.
  if (_emulatorHost.isNotEmpty) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099, automaticHostMapping: false);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080, automaticHostMapping: false);
  }

  if (!kIsWeb && !isDesktop) {
    // Crashlytics: lỗi Flutter và lỗi async chưa bắt đều là fatal.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final config = await _initConfig();

  final container = ProviderContainer(overrides: [configServiceProvider.overrideWithValue(config)]);
  if (!kIsWeb && !isDesktop) {
    // Ghi kèm bản tóm tắt cho web admin (trang Sự cố). Crashlytics vẫn nhận bản đầy đủ.
    final report = container.read(crashReportSinkProvider);
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      unawaited(report(CrashKind.flutterError, details.library ?? 'flutter', details.exceptionAsString()));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      unawaited(report(CrashKind.flutterError, 'uncaught_async', '$error'));
      return true;
    };
  }
  // Không chặn màn đầu tiên chờ quyền thông báo. Máy chiếu thì không xin quyền.
  // Windows không có FCM.
  if (!tv && !isDesktop) unawaited(container.read(messagingServiceProvider).init());

  runApp(UncontrolledProviderScope(container: container, child: const AttendoApp()));
}
