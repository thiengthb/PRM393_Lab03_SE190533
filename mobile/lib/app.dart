import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase/fcm_token_sync.dart';
import 'router.dart';
import 'package:attendo_core/config/app_config.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/widgets/form_factor.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/widgets/layout.dart';
import 'package:attendo_core/widgets/motion.dart';
import 'viewmodels/app_viewmodel.dart';

class AttendoApp extends ConsumerWidget {
  const AttendoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chạm thông báo (FCM hoặc nhắc slot) → mở màn trong data.route.
    // Lưu FCM token của máy cho người đang đăng nhập (Android).
    ref.watch(fcmTokenSyncProvider);
    ref.listen(notificationRouteViewModelProvider, (_, next) {
      if (next != null) ref.read(routerProvider).push(next.$1);
    });
    final palette = ref.watch(paletteViewModelProvider);
    return MaterialApp.router(
      title: 'Attendo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      themeMode: ref.watch(themeModeViewModelProvider),
      themeAnimationDuration: AppMotion.slow,
      themeAnimationCurve: AppMotion.standard,
      // Layout family by platform (Windows = desktop, Android = phone, student web = width),
      // then the desktop text step (AppLayout.wideTextScale).
      builder: (context, child) => FormFactorScope.of(
        AppConfig.portal == UserRole.student ? FormFactorPolicy.byWidth : FormFactorPolicy.lecturerApp,
        child: WideTextScale(child: child!),
      ),
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
