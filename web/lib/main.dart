import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/firebase/app_check_bootstrap.dart';
import 'package:quick_attend_core/firebase/config_service.dart';
import 'package:quick_attend_core/providers.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateAppCheck();

  final config = FirebaseConfigService(FirebaseRemoteConfig.instance);
  await config.init();

  runApp(ProviderScope(
    overrides: [configServiceProvider.overrideWithValue(config)],
    child: const AdminApp(),
  ));
}
