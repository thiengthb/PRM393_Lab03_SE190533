import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Route cần mở khi người dùng chạm thông báo (FCM hoặc nhắc slot).
/// CR-03: widget gốc chỉ nghe ViewModel này, không gọi MessagingService trực tiếp.
/// State là (route, số thứ tự) để hai lần chạm cùng một route vẫn mở hai lần.
final notificationRouteViewModelProvider =
    NotifierProvider<NotificationRouteViewModel, (String, int)?>(NotificationRouteViewModel.new);

class NotificationRouteViewModel extends Notifier<(String, int)?> {
  var _seq = 0;

  @override
  (String, int)? build() {
    final StreamSubscription<String> sub =
        ref.watch(messagingServiceProvider).openRoutes.listen((r) => state = (r, ++_seq));
    ref.onDispose(sub.cancel);
    return null;
  }
}
