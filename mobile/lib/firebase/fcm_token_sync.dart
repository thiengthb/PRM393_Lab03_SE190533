import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Ghi FCM token của máy này vào `users/{uid}/fcmTokens` mỗi khi có người đăng nhập,
/// và ghi lại khi Firebase cấp token mới. Chỉ chạy trên Android: web cần VAPID key và
/// hỏi quyền trước khi có token, Windows không có FCM.
///
/// Luồng đầy đủ (docs/fcm.md): Firebase cấp token cho app → app lưu vào Firestore →
/// script `tool/fcm/send.mjs` (Admin SDK, có service account) đọc token theo email người
/// nhận rồi gọi FCM HTTP v1 → máy nhận thông báo, chạm vào thì mở `route` trong data.
final fcmTokenSyncProvider = Provider<void>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return;
  final messaging = ref.read(messagingServiceProvider);
  final repo = ref.read(fcmTokenRepositoryProvider);
  final crash = ref.read(crashServiceProvider);

  Future<void> save(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await repo.save(uid, token, platform: 'android');
    } catch (e, st) {
      // Không có mạng thì Firestore giữ lệnh ghi và gửi sau; lỗi khác chỉ ghi non-fatal.
      await crash.recordNonFatal(e, st, where: 'fcm_token_save');
    }
  }

  unawaited(messaging.token().then(save));
  final sub = messaging.tokenRefresh.listen(save, onError: (Object _) {});
  ref.onDispose(sub.cancel);
});
