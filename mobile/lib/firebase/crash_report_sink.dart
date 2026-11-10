import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/crash_report.dart';
import 'package:attendo_core/providers.dart';

/// Ghi bản tóm tắt một sự cố vào `crashReports` để Admin xem trên web.
/// Crashlytics vẫn giữ stack đầy đủ; bản tóm tắt chỉ có nơi xảy ra và câu lỗi.
typedef CrashReportSink = Future<void> Function(CrashKind kind, String where, String message);

/// Tối đa số bản ghi mỗi lần chạy app, để một lỗi giao diện lặp lại không ghi hàng trăm tài liệu.
const maxCrashReportsPerRun = 20;

/// android | web | windows, khớp danh sách trong Security Rules.
String crashPlatformId() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.windows ? 'windows' : 'android';
}

/// Ghi khi có người đăng nhập, không chờ quá 3 giây, nuốt mọi lỗi: báo cáo sự cố không được
/// gây thêm sự cố.
final crashReportSinkProvider = Provider<CrashReportSink>((ref) {
  var sent = 0;
  return (kind, where, message) async {
    if (sent >= maxCrashReportsPerRun) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    sent++;
    try {
      await ref
          .read(crashReportRepositoryProvider)
          .add(CrashReport(
            uid: user.uid,
            role: user.role.name,
            kind: kind,
            where: where,
            message: message,
            platform: crashPlatformId(),
          ))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('crash report not saved: $e');
    }
  };
});
