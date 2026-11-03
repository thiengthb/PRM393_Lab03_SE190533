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
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'router.dart' show isTvRoute;
import 'firebase/config_service.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Đường dẫn không có # để link màn chiếu gõ được: hereby-se190533.web.app/tv/<khoá>.
  // Hosting đã chuyển mọi đường về index.html (firebase.json).
  usePathUrlStrategy();
  final tv = kIsWeb && isTvRoute(Uri.base.path);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore giữ dữ liệu trên máy: chốt điểm danh lúc mất mạng vẫn không mất (GV-OV2).
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Chạy với Firebase Emulator (chụp màn, demo không đụng dữ liệu thật):
  // --dart-define=EMULATOR_HOST=localhost, cổng như firebase.json (auth 9099, firestore 8080).
  if (_emulatorHost.isNotEmpty) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  }

  if (!kIsWeb) {
    // Crashlytics: lỗi Flutter và lỗi async chưa bắt đều là fatal.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final config = FirebaseConfigService(FirebaseRemoteConfig.instance);
  await config.init();

  final container = ProviderContainer(overrides: [configServiceProvider.overrideWithValue(config)]);
  // Không chặn màn đầu tiên chờ quyền thông báo. Máy chiếu thì không xin quyền.
  if (!tv) unawaited(container.read(messagingServiceProvider).init());

  runApp(UncontrolledProviderScope(container: container, child: const HerebyApp()));
}
