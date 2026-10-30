import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore giữ dữ liệu trên máy: chốt điểm danh lúc mất mạng vẫn không mất (GV-OV2).
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

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
  // Không chặn màn đầu tiên chờ quyền thông báo.
  unawaited(container.read(messagingServiceProvider).init());

  runApp(UncontrolledProviderScope(container: container, child: const QuickAttendApp()));
}
