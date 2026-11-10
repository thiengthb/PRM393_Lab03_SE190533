import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/firebase/app_check_bootstrap.dart';
import 'package:attendo_core/firebase/config_service.dart';
import 'package:attendo_core/providers.dart';

import 'app.dart';
import 'firebase_options.dart';

const _emulatorHost = String.fromEnvironment('EMULATOR_HOST');
const _emulatorLogin = String.fromEnvironment('EMULATOR_LOGIN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateAppCheck();

  // Chạy với Firebase Emulator để chụp màn, giống app: --dart-define=EMULATOR_HOST=localhost.
  if (_emulatorHost.isNotEmpty) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    // Web admin chỉ có nút Google. Chụp màn trên emulator thì đăng nhập sẵn tài khoản mẫu:
    // --dart-define=EMULATOR_LOGIN=admin@fe.edu.vn (mật khẩu mẫu của seed-demo.mjs).
    if (_emulatorLogin.isNotEmpty) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emulatorLogin, password: 'Demo@123');
    }
  }

  final config = FirebaseConfigService(FirebaseRemoteConfig.instance);
  await config.init();

  runApp(ProviderScope(
    overrides: [configServiceProvider.overrideWithValue(config)],
    child: const AdminApp(),
  ));
}
