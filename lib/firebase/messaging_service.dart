import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'local_notification_service.dart';

/// Lưu tin FCM nhận được vào máy (trung tâm thông báo). Dùng chung cho
/// isolate nền (main.dart) và app.
abstract final class NotificationStore {
  static const _key = 'received_notifications';
  static const _max = 50;

  static List<ReceivedNotification> _decode(List<String> raw) => raw
      .map((s) {
        try {
          return ReceivedNotification.fromJson((jsonDecode(s) as Map).cast<String, Object?>());
        } catch (_) {
          return null;
        }
      })
      .whereType<ReceivedNotification>()
      .toList();

  static Future<List<ReceivedNotification>> read() async {
    final p = await SharedPreferences.getInstance();
    await p.reload(); // đọc cả tin isolate nền vừa ghi
    return _decode(p.getStringList(_key) ?? const []);
  }

  /// CR-04: kiểm trùng theo trường id đã giải mã, không so chuỗi JSON.
  static Future<void> add(ReceivedNotification n) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final list = _decode(p.getStringList(_key) ?? const []);
    if (list.any((x) => x.id == n.id)) return;
    final next = [n, ...list].take(_max).map((x) => jsonEncode(x.toJson())).toList();
    await p.setStringList(_key, next);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  static ReceivedNotification fromMessage(RemoteMessage m, String appState) => ReceivedNotification(
        id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: m.notification?.title ?? (m.data['title'] as String?) ?? 'Quick Attend',
        body: m.notification?.body ?? (m.data['body'] as String?) ?? '',
        receivedAt: m.sentTime ?? DateTime.now(),
        appState: appState,
        route: m.data['route'] as String?,
      );
}

abstract class MessagingService {
  /// Route cần mở khi người dùng chạm thông báo.
  Stream<String> get openRoutes;
  Stream<List<ReceivedNotification>> watchInbox();
  Future<void> init();
  Future<bool> requestPermission();
  Future<String?> token();
  Future<void> clearInbox();
}

class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService(this._m, this._local);

  final FirebaseMessaging _m;
  final LocalNotificationService _local;
  final _routes = StreamController<String>.broadcast();
  final _inbox = StreamController<List<ReceivedNotification>>.broadcast();
  String? _pendingRoute;

  @override
  Stream<String> get openRoutes async* {
    final p = _pendingRoute;
    if (p != null) {
      _pendingRoute = null;
      yield p;
    }
    yield* _routes.stream;
  }

  @override
  Stream<List<ReceivedNotification>> watchInbox() async* {
    yield await NotificationStore.read();
    yield* _inbox.stream;
  }

  Future<void> _store(RemoteMessage m, String state) async {
    await NotificationStore.add(NotificationStore.fromMessage(m, state));
    _inbox.add(await NotificationStore.read());
  }

  void _open(RemoteMessage m) {
    final r = m.data['route'] as String?;
    if (r == null || r.isEmpty) return;
    if (_routes.hasListener) {
      _routes.add(r);
    } else {
      _pendingRoute = r;
    }
  }

  @override
  Future<void> init() async {
    await _local.init((route) => _routes.add(route));
    // App mở khi chạm thông báo lúc đã tắt hẳn.
    try {
      final initial = await _m.getInitialMessage();
      if (initial != null) {
        await _store(initial, 'terminated');
        _open(initial);
      }
    } catch (_) {}
    final localRoute = await _local.launchRoute();
    if (localRoute != null) _pendingRoute = localRoute;

    FirebaseMessaging.onMessage.listen((m) async {
      await _store(m, 'foreground');
      final n = m.notification;
      if (n != null) {
        await _local.show(id: m.hashCode & 0x7fffffff, title: n.title ?? 'Quick Attend', body: n.body ?? '', route: m.data['route'] as String?);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) async {
      await _store(m, 'background');
      _open(m);
    });
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final s = await _m.requestPermission();
      await _local.requestPermission();
      return s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> token() async {
    try {
      return await _m.getToken(vapidKey: kIsWeb ? const String.fromEnvironment('FCM_VAPID_KEY') : null);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearInbox() async {
    await NotificationStore.clear();
    _inbox.add(const []);
  }
}
