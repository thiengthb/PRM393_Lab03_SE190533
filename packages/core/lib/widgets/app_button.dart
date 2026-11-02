import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum AppButtonStyle { primary, outline, ghost, destructive, onPrimary }

enum AppButtonSize {
  /// 48: nút chính dưới ô nhập, thanh nút đáy.
  large,

  /// 40: nút trong thẻ và ô trống.
  medium,

  /// 36: nút trong hộp thoại.
  small,
}

/// Component Button (Figma 3:42): nổi khối, gờ đáy 2, bo 8.
/// Trạng thái: default, pressed (dịch xuống 2, mất gờ), disabled, loading.
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
    final (Color bg, Color fg, Color? border, Color? ledge) = switch (widget.style) {
      AppButtonStyle.primary => (c.primary, c.onPrimary, null, st.primaryEdge),
      AppButtonStyle.destructive => (c.error, c.onError, null, st.danger),
      AppButtonStyle.outline => (c.surface, c.onSurface, c.outlineVariant, c.outlineVariant),
      AppButtonStyle.onPrimary => (c.surface, c.primary, null, st.primaryEdge),
      AppButtonStyle.ghost => (Colors.transparent, c.primary, null, null),
    };
    final disabled = !_enabled && !widget.loading;
    final effBg = disabled && widget.style != AppButtonStyle.ghost ? c.surfaceContainerHighest : bg;
    final effFg = disabled ? st.fgDisabled : fg;
    final showLedge = !_pressed && !disabled;

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
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel ?? widget.label,
      excludeSemantics: true,
      child: Padding(
        // Chừa chỗ cho gờ để kích thước không nhảy khi nhấn.
        padding: EdgeInsets.only(top: _pressed ? AppSize.ledge : 0, bottom: _pressed ? 0 : AppSize.ledge),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: effBg,
            borderRadius: radius,
            border: border == null ? null : Border.all(color: border, width: AppSize.border),
            boxShadow: (showLedge && ledge != null)
                ? [BoxShadow(color: ledge, offset: const Offset(0, AppSize.ledge))]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: _enabled ? (v) => setState(() => _pressed = v) : null,
              child: SizedBox(
                height: _height - AppSize.ledge,
                width: widget.expand ? double.infinity : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                  child: content,
                ),
              ),
            ),
          ),
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
