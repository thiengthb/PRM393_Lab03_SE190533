import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/tokens.dart';

/// Lò xo nhấn theo `seam` của thienui: 0 = nhả, 1 = nhấn. Nhấn dùng lò xo `press` (gần như tức
/// thì, không nảy), nhả dùng `snappy`. Chạm rất nhanh vẫn thấy nút lún một nhịp rồi mới bật lên.
/// Tắt chuyển động trong cài đặt máy thì nhảy thẳng tới giá trị cuối.
class PressSpring {
  PressSpring(TickerProvider vsync) : controller = AnimationController.unbounded(vsync: vsync);

  final AnimationController controller;
  bool _down = false;

  double get value => controller.value.clamp(0.0, 1.0);

  void set(bool pressed, {required bool reduceMotion}) {
    if (pressed == _down) return;
    _down = pressed;
    if (reduceMotion) {
      controller.value = pressed ? 1 : 0;
      return;
    }
    if (pressed) {
      controller.animateWith(SpringSimulation(AppMotion.pressSpring, controller.value, 1, controller.velocity));
      return;
    }
    if (controller.value < 0.6) {
      // Chạm nhanh: lún hết một nhịp ngắn rồi mới nhả, để tay thấy nút đã ăn.
      controller.animateTo(1, duration: const Duration(milliseconds: 60), curve: AppMotion.standard).then((_) {
        if (!_down) _release();
      });
      return;
    }
    _release();
  }

  void _release() =>
      controller.animateWith(SpringSimulation(AppMotion.snappySpring, controller.value, 0, controller.velocity));

  void dispose() => controller.dispose();
}

/// Hàng hoặc thẻ bấm được: lún nhẹ (scale 0,97 của thienui) theo lò xo khi giữ tay, không gợn
/// sóng Material. Trong danh sách cuộn, nhấn chỉ hiện khi cử chỉ là chạm (InkWell báo), nên kéo
/// danh sách không làm hàng lún theo.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.scale = AppMotion.pressedScale,
    this.highlight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scale;

  /// Nền phủ khi nhấn (thường là --accent). null: chỉ lún, không đổi nền.
  final Color? highlight;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late final PressSpring _spring = PressSpring(this);

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _spring.controller,
      builder: (context, child) {
        final t = _spring.value;
        return Transform.scale(
          scale: 1 - (1 - widget.scale) * t,
          // Luôn có DecoratedBox (trong suốt khi nhả) để cây không đổi hình dạng giữa chừng.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.highlight?.withValues(alpha: widget.highlight!.a * t) ?? const Color(0x00000000),
              borderRadius: widget.borderRadius,
            ),
            child: child,
          ),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onHighlightChanged: widget.onTap == null ? null : (v) => _spring.set(v, reduceMotion: reduce),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hiện lần lượt một lần khi màn mở: mờ dần và trượt lên 8px, mỗi phần tử trễ hơn phần tử trước
/// [AppMotion.stagger]. Đã hiện rồi thì dựng lại không chạy nữa. Chữ không chạy riêng; cả khối
/// cùng hiện. Tắt chuyển động trong cài đặt máy thì hiện ngay.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = AppMotion.stagger * widget.index.clamp(0, AppMotion.staggerMax);
    final total = delay + AppMotion.slow;
    _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppMotion.enter),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Cây widget giữ nguyên hình dạng suốt và sau chuyển động (luôn Opacity + Transform), nếu không
  // phần tử con bị dựng lại từ đầu lúc chạy xong và mất trạng thái (ô nhập mất focus).
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        alwaysIncludeSemantics: true,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, child) => Transform.translate(offset: Offset(0, 8 * (1 - _t.value)), child: child),
          child: widget.child,
        ),
      );
}

/// Cuộn mượt cho cả app: có quán tính và nảy nhẹ ở mép (kiểu iOS) trên mọi nền tảng, kéo được bằng
/// bàn di chuột; chuột thường vẫn cuộn bằng con lăn.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
