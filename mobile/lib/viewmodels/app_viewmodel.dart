import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'package:quick_attend_core/theme/tokens.dart';

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

/// Bảng màu đang dùng. Mở app dùng Teal, đọc xong lựa chọn đã lưu thì đổi theo.
final paletteViewModelProvider = NotifierProvider<PaletteViewModel, AppPalette>(PaletteViewModel.new);

class PaletteViewModel extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    unawaited(_load());
    return AppPalette.teal;
  }

  Future<void> _load() async {
    final id = await ref.read(paletteStoreProvider).read();
    if (ref.mounted && id != null) state = AppPalette.byId(id);
  }

  Future<void> select(AppPalette p) async {
    state = p;
    await ref.read(paletteStoreProvider).write(p.id);
  }
}
