import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase/fcm_token_sync.dart';
import 'router.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'viewmodels/app_viewmodel.dart';

class HerebyApp extends ConsumerWidget {
  const HerebyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chạm thông báo (FCM hoặc nhắc slot) → mở màn trong data.route.
    // Lưu FCM token của máy cho người đang đăng nhập (Android).
    ref.watch(fcmTokenSyncProvider);
    ref.listen(notificationRouteViewModelProvider, (_, next) {
      if (next != null) ref.read(routerProvider).push(next.$1);
    });
    return MaterialApp.router(
      title: 'Hereby',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(ref.watch(paletteViewModelProvider)),
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
