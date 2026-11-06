import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'motion.dart';

enum AppButtonStyle { primary, outline, ghost, destructive, onPrimary }

enum AppButtonSize {
  /// 40: nút chính dưới ô nhập, thanh nút đáy.
  large,

  /// 36: nút trong thẻ và ô trống (cỡ điều khiển điện thoại của thienui). Vùng bấm vẫn 48.
  medium,

  /// 30: nút trong hộp thoại, hàng công cụ. Vùng bấm vẫn 48.
  small,
}

/// Nút theo `button.tsx` của thienui và UI-TASTE.md: bo 8, chữ 14 đậm 500, cao 40 / 36 / 30 (vùng
/// bấm vẫn 48), nổi bằng một gờ dưới 2px đặc. Chính = nền xanh ngọc chữ mực, gờ màu --press;
/// viền = nền trắng viền --border, gờ cùng màu viền; ghost = trong suốt, không gờ; destructive =
/// nền đỏ nhạt chữ đỏ. Nhấn: nút lún xuống bằng gờ theo lò xo `press`, nhả bật lại theo `snappy`.
/// Tắt thì mờ 50%.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingArrow = false,
    this.loading = false,
    this.expand = true,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final IconData? icon;
  final bool trailingArrow;
  final bool loading;
  final bool expand;
  final String? semanticsLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final PressSpring _spring = PressSpring(this);

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.loading;

  double get _height => switch (widget.size) {
        AppButtonSize.large => 40,
        AppButtonSize.medium => 36,
        AppButtonSize.small => 30,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final dangerEdge = Color.lerp(st.dangerSoft, st.danger, 0.28)!;
    final (Color bg, Color pressedBg, Color fg, Color? border, Color? edge) = switch (widget.style) {
      AppButtonStyle.primary => (st.fill, st.fillPressed, st.onFill, null, st.primaryEdge),
      AppButtonStyle.destructive => (st.dangerSoft, Color.lerp(st.dangerSoft, st.danger, 0.12)!, st.danger, null, dangerEdge),
      AppButtonStyle.outline => (c.surface, c.surfaceContainerHigh, st.fgStrong, c.outlineVariant, c.outlineVariant),
      AppButtonStyle.onPrimary => (c.surface, c.primaryContainer, c.primary, null, st.primaryEdge),
      AppButtonStyle.ghost => (Colors.transparent, c.surfaceContainerHigh, c.primary, null, null),
    };
    final disabled = !_enabled && !widget.loading;
    final effFg = fg;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final labelStyle = context.text.label.copyWith(color: effFg, fontWeight: FontWeight.w500);
    const iconSize = 16.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: effFg),
          ),
          const SizedBox(width: AppSpace.s8),
        ] else if (widget.icon != null) ...[
          // Icon lấy màu theo chữ của nút (luật Final UI).
          Icon(widget.icon, size: iconSize, color: effFg),
          const SizedBox(width: AppSpace.s8),
        ],
        Flexible(child: Text(widget.label, style: labelStyle, overflow: TextOverflow.ellipsis)),
        if (widget.trailingArrow && !widget.loading) ...[
          const SizedBox(width: AppSpace.s4),
          Icon(LucideIcons.chevronRight, size: iconSize, color: effFg),
        ],
      ],
    );

    final radius = BorderRadius.circular(AppRadius.md);
    final lift = edge == null ? 0.0 : AppSize.lift;
    final tap = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: st.fgStrong.withValues(alpha: 0.05),
        onTap: _enabled ? widget.onPressed : null,
        onHighlightChanged: _enabled ? (v) => _spring.set(v, reduceMotion: reduce) : null,
        child: SizedBox(
          height: _height,
          width: widget.expand ? double.infinity : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
            child: content,
          ),
        ),
      ),
    );
    // Gờ dưới đặc 2px; nhấn thì thân nút lún xuống đúng bằng gờ, gờ thu lại (kiểu nút nổi).
    final Widget visual = Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: AnimatedBuilder(
        animation: _spring.controller,
        builder: (context, child) {
          final t = _spring.value;
          final down = lift * t;
          return Transform.translate(
            offset: Offset(0, down),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(bg, pressedBg, t),
                borderRadius: radius,
                border: border == null ? null : Border.all(color: border, width: AppSize.border),
                boxShadow: lift == 0 ? null : [BoxShadow(color: edge!, offset: Offset(0, lift - down))],
              ),
              child: child,
            ),
          );
        },
        child: tap,
      ),
    );

    final shown = disabled ? Opacity(opacity: 0.5, child: visual) : visual;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel ?? widget.label,
      container: true,
      // Không có onTap ở đây thì node chỉ có cờ button, không có hành động: trình đọc màn hình
      // và bàn phím (Tab, Enter trên web) không bấm được vì InkWell bên dưới đã bị loại khỏi cây.
      onTap: _enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: _height + lift >= AppSize.touch
          ? shown
          // Nút 40, 36, 30 giữ hình gọn, vùng bấm vô hình mở rộng lên 48 (đề Lab 3, trợ năng).
          // Chạm trong phần đệm vẫn bấm nút; chạm trúng nút thì InkWell thắng nên không bấm hai lần.
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? widget.onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSize.touch, minWidth: AppSize.touch),
                child: Center(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: shown),
              ),
            ),
    );
  }
}

/// Nút icon tròn 48 có tooltip (đọc màn hình).
class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: AppSize.icon24, color: color ?? context.colors.onSurface),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: AppSize.touch, height: AppSize.touch),
      );
}
