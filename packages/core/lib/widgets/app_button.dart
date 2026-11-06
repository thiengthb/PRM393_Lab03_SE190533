import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
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

/// Nút theo `button.tsx` của thienui (shadcn): bo 6, chữ 14 đậm 500, cao 44 / 36 / 32 (vùng bấm vẫn 48).
/// default = nền teal solid chữ mực; outline = viền --border nền trắng; ghost = trong suốt;
/// destructive = nền đỏ nhạt chữ đỏ (destructive/10). Nhấn thì đậm thêm một bậc; tắt thì mờ 50%.
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
        AppButtonSize.large => 44,
        AppButtonSize.medium => AppSize.buttonInDialog,
        AppButtonSize.small => 32,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final (Color bg, Color pressedBg, Color fg, Color? border) = switch (widget.style) {
      AppButtonStyle.primary => (st.fill, st.fillPressed, st.onFill, null),
      AppButtonStyle.destructive => (st.dangerSoft, Color.lerp(st.dangerSoft, st.danger, 0.12)!, st.danger, null),
      AppButtonStyle.outline => (c.surface, c.surfaceContainerHigh, st.fgStrong, c.outlineVariant),
      AppButtonStyle.onPrimary => (c.surface, c.primaryContainer, c.primary, null),
      AppButtonStyle.ghost => (Colors.transparent, c.surfaceContainerHigh, c.primary, null),
    };
    final disabled = !_enabled && !widget.loading;
    final effBg = _pressed ? pressedBg : bg;
    final effFg = fg;

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
    final Widget visual = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: effBg,
        borderRadius: radius,
        border: border == null ? null : Border.all(color: border, width: AppSize.border),
        boxShadow: widget.style == AppButtonStyle.outline ? const [AppShadow.hairline] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: st.fgStrong.withValues(alpha: 0.05),
          onTap: _enabled ? widget.onPressed : null,
          onHighlightChanged: _enabled ? (v) => setState(() => _pressed = v) : null,
          child: SizedBox(
            height: _height,
            width: widget.expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
              child: content,
            ),
          ),
        ),
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
      child: _height >= AppSize.touch
          ? shown
          // Nút 40 và 36 giữ hình như Figma, vùng bấm vô hình mở rộng lên 48 (đề Lab 3, trợ năng).
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
