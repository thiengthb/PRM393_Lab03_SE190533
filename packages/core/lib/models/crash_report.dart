import 'package:flutter/foundation.dart';

/// Loại sự cố app tự ghi để web admin xem. Chi tiết stack vẫn nằm ở Crashlytics.
enum CrashKind {
  testCrash('test_crash', 'Test crash'),
  nonFatal('non_fatal', 'Lỗi non-fatal'),
  flutterError('flutter_error', 'Lỗi giao diện');

  const CrashKind(this.id, this.label);
  final String id;
  final String label;

  static CrashKind from(String? id) => values.firstWhere((k) => k.id == id, orElse: () => nonFatal);
}

/// Bản tóm tắt một sự cố ở `crashReports/{id}`. Crashlytics không có API cho web client, nên
/// app ghi kèm bản tóm tắt này để Admin xem trên web; dev xem stack đầy đủ trên console.
@immutable
class CrashReport {
  const CrashReport({
    this.id = '',
    required this.uid,
    required this.role,
    required this.kind,
    required this.where,
    required this.message,
    required this.platform,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String role;
  final CrashKind kind;
  final String where;
  final String message;

  /// android | web | windows
  final String platform;
  final DateTime? createdAt;

  /// Giới hạn độ dài như Security Rules (message ≤ 500, where ≤ 80).
  static String clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';
}
