import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum AppButtonStyle { primary, outline, ghost, destructive, onPrimary }

enum AppButtonSize {
  /// 48: nút chính dưới ô nhập, thanh nút đáy.
  large,

  /// 40: nút trong thẻ và ô trống. Vùng bấm vẫn 48.
  medium,

  /// 36: nút trong hộp thoại. Vùng bấm vẫn 48.
  small,
}

/// Nút phẳng bo 8 (bản thiết kế lại 11/2026, theo thienui): nút chính nền [StatusColors.fill],
/// viền 1 cho nút viền, nhấn thì đậm màu. Trạng thái: default, pressed, disabled, loading.
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

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  double get _height => switch (widget.size) {
        AppButtonSize.large => AppSize.touch,
        AppButtonSize.medium => AppSize.buttonInCard,
        AppButtonSize.small => AppSize.buttonInDialog,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final (Color bg, Color pressedBg, Color fg, Color? border) = switch (widget.style) {
      AppButtonStyle.primary => (st.fill, st.fillPressed, st.onFill, null),
      AppButtonStyle.destructive => (st.danger, Color.lerp(st.danger, st.fgStrong, 0.18)!, c.onError, null),
      AppButtonStyle.outline => (c.surface, c.surfaceContainerHighest, st.fgStrong, Color.lerp(c.outlineVariant, c.outline, 0.3)),
      AppButtonStyle.onPrimary => (c.surface, c.primaryContainer, c.primary, null),
      AppButtonStyle.ghost => (Colors.transparent, c.primaryContainer, c.primary, null),
    };
    final disabled = !_enabled && !widget.loading;
    final effBg = disabled && widget.style != AppButtonStyle.ghost
        ? c.surfaceContainerHighest
        : (_pressed ? pressedBg : bg);
    final effFg = disabled ? st.fgDisabled : fg;

    final labelStyle = context.text.label.copyWith(color: effFg);
    final iconSize = widget.size == AppButtonSize.small ? AppSize.icon20 - 2 : AppSize.icon20;

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
          Icon(Icons.chevron_right, size: iconSize, color: effFg),
        ],
      ],
    );

    final radius = BorderRadius.circular(AppRadius.md);
    final Widget visual = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: effBg,
        borderRadius: radius,
        border: border == null || disabled ? null : Border.all(color: border, width: AppSize.border),
        boxShadow: widget.style == AppButtonStyle.outline && !disabled ? const [AppShadow.hairline] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: st.fgStrong.withValues(alpha: 0.04),
          onTap: _enabled ? widget.onPressed : null,
          onHighlightChanged: _enabled ? (v) => setState(() => _pressed = v) : null,
          child: SizedBox(
            height: _height,
            width: widget.expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
              child: content,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel ?? widget.label,
      excludeSemantics: true,
      child: _height >= AppSize.touch
          ? visual
          // Nút 40 và 36 giữ hình như Figma, vùng bấm vô hình mở rộng lên 48 (đề Lab 3, trợ năng).
          // Chạm trong phần đệm vẫn bấm nút; chạm trúng nút thì InkWell thắng nên không bấm hai lần.
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? widget.onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSize.touch, minWidth: AppSize.touch),
                child: Center(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: visual),
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
