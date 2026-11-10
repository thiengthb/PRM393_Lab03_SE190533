// Bản Windows (desktop giảng viên): Remote Config cố định và thanh tab dọc cho màn rộng.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendo_core/firebase/config_service.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/widgets/widgets.dart';

void main() {
  test('StaticConfigService: giá trị mặc định, tắt AI, nguồn static', () async {
    const c = StaticConfigService();
    expect(c.current.aiReminderEnabled, isFalse);
    expect(c.current.source, 'static');
    expect(c.current.qrRotateSeconds, 12);
    expect(c.current.reportCloudUpload, isTrue);
    expect(await c.watch().first, same(c.current));
  });

  testWidgets('QaSideNav: đủ 4 tab có chữ, chạm tab gọi onTap đúng chỉ số', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Row(children: [QaSideNav(index: 0, onTap: (i) => tapped = i)])),
    ));
    for (final t in QaBottomNav.tabs) {
      expect(find.text(t.$3), findsOneWidget);
    }
    await tester.tap(find.text('Lớp'));
    expect(tapped, 2);
  });

  test('LOI-21: lecturer web uses the desktop layout only from 1100 px', () {
    FormFactor f(FormFactorPolicy p, double w, {bool web = true, TargetPlatform os = TargetPlatform.android}) =>
        resolveFormFactor(p, w, isWeb: web, platform: os);
    expect(f(FormFactorPolicy.lecturerApp, 1099), FormFactor.phone);
    expect(f(FormFactorPolicy.lecturerApp, 1100), FormFactor.desktop);
    expect(f(FormFactorPolicy.lecturerApp, 800, web: false, os: TargetPlatform.windows), FormFactor.desktop);
    expect(f(FormFactorPolicy.lecturerApp, 1400, web: false), FormFactor.phone);
    // Student web keeps the shared breakpoint.
    expect(f(FormFactorPolicy.byWidth, 1000), FormFactor.desktop);
  });
}
