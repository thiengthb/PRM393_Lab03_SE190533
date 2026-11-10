import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendo_core/models/models.dart';
import '../providers.dart';

/// Trạng thái màn chiếu TV-001.
sealed class TvState {
  const TvState();
}

class TvLoading extends TvState {
  const TvLoading();
}

/// .E Chưa mở điểm danh: khoá sai hoặc link đã hết hạn.
class TvIdle extends TvState {
  const TvIdle();
}

/// .D đang mở mã.
class TvLive extends TvState {
  const TvLive(this.frame, {required this.rotateIn, required this.remaining});
  final TvFrame frame;
  final int rotateIn;
  final Duration remaining;
}

/// .D1 Đã đóng mã: giữ số đã quét.
class TvClosed extends TvState {
  const TvClosed(this.frame);
  final TvFrame frame;
}

final tvFrameProvider = StreamProvider.autoDispose.family<TvFrame?, String>(
  (ref, key) => ref.watch(tvRepositoryProvider).watch(key),
);

final _tvTickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (i) => i),
);

final tvViewModelProvider = NotifierProvider.autoDispose.family<TvViewModel, TvState, String>(TvViewModel.new);

/// Đếm ngược Đổi mã và Còn mm:ss chạy trên máy chiếu theo rotatedAt và endsAt,
/// nên chỉ cần một lần ghi mỗi chu kỳ đổi mã.
class TvViewModel extends Notifier<TvState> {
  TvViewModel(this.key);
  final String key;

  @override
  TvState build() {
    ref.watch(_tvTickProvider);
    final v = ref.watch(tvFrameProvider(key));
    if (v.isLoading && !v.hasValue) return const TvLoading();
    return compute(v.value, ref.read(clockProvider)());
  }

  static TvState compute(TvFrame? f, DateTime now) {
    if (f == null || !now.isBefore(f.validUntil)) return const TvIdle();
    // Tài liệu TV chỉ được tạo khi mã đang mở, nên open false nghĩa là đã đóng mã.
    if (!f.open || f.qr == null) return TvClosed(f);
    final since = f.rotatedAt == null ? 0 : now.difference(f.rotatedAt!).inSeconds;
    final period = f.rotateSeconds <= 0 ? 12 : f.rotateSeconds;
    final rotateIn = (period - since).clamp(0, period);
    final remaining = f.endsAt == null ? Duration.zero : f.endsAt!.difference(now);
    return TvLive(f, rotateIn: rotateIn, remaining: remaining.isNegative ? Duration.zero : remaining);
  }
}
