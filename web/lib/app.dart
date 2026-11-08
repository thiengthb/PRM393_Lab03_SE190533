import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/widgets/form_factor.dart';
import 'package:attendo_core/widgets/layout.dart';
import 'package:attendo_core/widgets/motion.dart';

import 'router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Attendo · Quản trị',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Trang quản trị theo chế độ sáng/tối của máy.
      themeMode: ThemeMode.system,
      // Màn rộng: chữ lớn hơn một bậc (AppLayout.wideTextScale).
      // Web admin is laptop-only: always the desktop layout family.
      builder: (context, child) => FormFactorScope(value: FormFactor.desktop, child: WideTextScale(child: child!)),
      routerConfig: ref.watch(adminRouterProvider),
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
