import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import '../utils/calendar.dart';

/// Thông báo cục bộ: hiện tin FCM khi app đang mở, và nhắc slot
/// (“Trước slot · 10 phút”, “Slot chưa chốt · Khi hết giờ”, GV-004).
abstract class LocalNotificationService {
  Future<void> init(void Function(String route) onTap);
  Future<bool> requestPermission();
  Future<void> show({required int id, required String title, required String body, String? route});
  Future<void> scheduleSlotReminders(List<Slot> slots, {required bool beforeSlot, required bool unclosed, required DateTime now});
  Future<String?> launchRoute();
}

class FlnLocalNotificationService implements LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'quick_attend',
    'Quick Attend',
    channelDescription: 'Nhắc điểm danh và thông báo',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> init(void Function(String route) onTap) async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.isNotEmpty) onTap(p);
      },
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> show({required int id, required String title, required String body, String? route}) async {
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _channel),
      payload: route,
    );
  }

  @override
  Future<void> scheduleSlotReminders(
    List<Slot> slots, {
    required bool beforeSlot,
    required bool unclosed,
    required DateTime now,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAllPendingNotifications();
    // Chỉ lên lịch 2 ngày tới: đủ cho nhắc, không chạm giới hạn 500 báo thức của Android.
    final horizon = now.add(const Duration(days: 2));
    var id = 1000;
    for (final s in slots.where((s) => !s.closed && s.end.isAfter(now) && s.start.isBefore(horizon))) {
      final before = s.start.subtract(const Duration(minutes: 10));
      if (beforeSlot && before.isAfter(now)) {
        await _schedule(id++, before, '${s.classLabel} · Slot ${s.slotNo}', 'Bắt đầu lúc ${VnDate.hm(s.start)} · ${s.room}',
            '/slot/${s.id}');
      }
      if (unclosed) {
        await _schedule(id++, s.end, '${s.classLabel} chưa chốt', 'Slot ${s.slotNo} đã hết giờ', '/session/${s.id}');
      }
    }
  }

  Future<void> _schedule(int id, DateTime at, String title, String body, String route) async {
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(android: _channel),
      // Không cần quyền báo thức chính xác (Android 14): lệch vài phút vẫn đủ để nhắc.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: route,
    );
  }

  @override
  Future<String?> launchRoute() async {
    if (!_ready) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d?.didNotificationLaunchApp ?? false) return d?.notificationResponse?.payload;
    return null;
  }
}
