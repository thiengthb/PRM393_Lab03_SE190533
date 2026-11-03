import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'viewmodels/app_viewmodel.dart';

class HerebyApp extends ConsumerWidget {
  const HerebyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chạm thông báo (FCM hoặc nhắc slot) → mở màn trong data.route.
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
