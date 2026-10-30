import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Giá trị Remote Config app dùng. Mặc định trong app = firebase/remote-config-defaults.json.
@immutable
class AppRemoteConfig {
  const AppRemoteConfig({
    this.absenceLimitPercent = 20,
    this.qrRotateSeconds = 12,
    this.attentionPreviewCount = 2,
    this.sessionMinutes = 5,
    this.source = 'default',
    this.fetchedAt,
  });

  /// Ngưỡng vắng (% số buổi). 20 → 4/20 buổi.
  final int absenceLimitPercent;

  /// Chu kỳ đổi mã QR ở GV-102 (chip “Đổi mã 12s”).
  final int qrRotateSeconds;

  /// Số hàng Chú ý ở Tổng quan.
  final int attentionPreviewCount;

  /// Thời gian mở mã (“Còn 04:12”).
  final int sessionMinutes;

  /// default | remote | cached.
  final String source;
  final DateTime? fetchedAt;

  static const defaults = <String, Object>{
    'absence_limit_percent': 20,
    'qr_rotate_seconds': 12,
    'attention_preview_count': 2,
    'session_minutes': 5,
  };
}

abstract class ConfigService {
  AppRemoteConfig get current;
  Stream<AppRemoteConfig> watch();
  Future<void> refresh();
}

class FirebaseConfigService implements ConfigService {
  FirebaseConfigService(this._rc);

  final FirebaseRemoteConfig _rc;
  final _ctrl = StreamController<AppRemoteConfig>.broadcast();
  AppRemoteConfig _current = const AppRemoteConfig();
  StreamSubscription<RemoteConfigUpdate>? _sub;

  @override
  AppRemoteConfig get current => _current;

  /// Gọi một lần lúc khởi động (main.dart). Lỗi mạng thì dùng giá trị mặc định.
  Future<void> init() async {
    try {
      await _rc.setDefaults(AppRemoteConfig.defaults);
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(minutes: 5),
      ));
      _emit();
      await _rc.fetchAndActivate();
      _emit();
    } catch (_) {
      _emit();
    }
    // Cập nhật thời gian thực: đổi giá trị trên console, app đổi theo không cần build lại.
    try {
      _sub = _rc.onConfigUpdated.listen((_) async {
        await _rc.activate();
        _emit();
      }, onError: (Object _) {});
    } catch (_) {
      // Web chưa hỗ trợ cập nhật thời gian thực: nút “Tải lại” ở khu demo.
    }
  }

  void _emit() {
    int i(String k, int def) {
      final v = _rc.getInt(k);
      return v <= 0 ? def : v;
    }

    final src = _rc.getValue('qr_rotate_seconds').source;
    _current = AppRemoteConfig(
      absenceLimitPercent: i('absence_limit_percent', 20),
      qrRotateSeconds: i('qr_rotate_seconds', 12).clamp(5, 60),
      attentionPreviewCount: i('attention_preview_count', 2).clamp(1, 10),
      sessionMinutes: i('session_minutes', 5).clamp(1, 30),
      source: switch (src) {
        ValueSource.valueRemote => 'remote',
        ValueSource.valueDefault => 'default',
        ValueSource.valueStatic => 'static',
      },
      fetchedAt: _rc.lastFetchTime,
    );
    _ctrl.add(_current);
  }

  @override
  Stream<AppRemoteConfig> watch() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  @override
  Future<void> refresh() async {
    try {
      await _rc.fetchAndActivate();
    } finally {
      _emit();
    }
  }

  void dispose() {
    _sub?.cancel();
    _ctrl.close();
  }
}
