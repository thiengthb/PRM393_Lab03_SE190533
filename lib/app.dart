import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class QuickAttendApp extends ConsumerStatefulWidget {
  const QuickAttendApp({super.key});

  @override
  ConsumerState<QuickAttendApp> createState() => _QuickAttendAppState();
}

class _QuickAttendAppState extends ConsumerState<QuickAttendApp> {
  StreamSubscription<String>? _routes;

  @override
  void initState() {
    super.initState();
    // Chạm thông báo (FCM hoặc nhắc slot) → mở màn trong data.route.
    _routes = ref.read(messagingServiceProvider).openRoutes.listen((route) {
      ref.read(routerProvider).push(route);
    });
  }

  @override
  void dispose() {
    _routes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quick Attend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
