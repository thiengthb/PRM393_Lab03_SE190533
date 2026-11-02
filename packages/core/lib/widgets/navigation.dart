import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// App bar (Figma 5:95). Top: icon đặc + tiêu đề. Nested: quay lại + tiêu đề + icon.
class QaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QaAppBar.top({super.key, required this.title, this.icon, this.actions = const []}) : nested = false;

  const QaAppBar.nested({super.key, required this.title, this.icon, this.actions = const []}) : nested = true;

  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final bool nested;

  @override
  Size get preferredSize => Size.fromHeight(nested ? 56 : 64);

  @override
  Widget build(BuildContext context) {
    final titleStyle = nested ? context.text.title : context.text.titleLg;
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      titleSpacing: nested ? 0 : AppSpace.screen,
      leading: nested
          ? IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Semantics(
        header: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: nested ? AppSize.icon20 : AppSize.icon24, color: context.colors.primary),
              const SizedBox(width: AppSpace.s8),
            ],
            Flexible(child: Text(title, style: titleStyle, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      actions: [...actions, const SizedBox(width: AppSpace.s4)],
    );
  }
}

/// Bottom navigation (Figma 5:220): chỉ icon; tab chọn là icon đặc trong ô primary-soft.
class QaBottomNav extends StatelessWidget {
  const QaBottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const tabs = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Tổng quan'),
    (Icons.calendar_today_outlined, Icons.calendar_today_outlined, 'Lịch'),
    (Icons.group_outlined, Icons.group_rounded, 'Lớp'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    label: tabs[i].$3,
                    selected: i == index,
                    button: true,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 40,
                          decoration: BoxDecoration(
                            color: i == index ? context.colors.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            // Lịch luôn dùng icon nét (luật Final UI: mọi icon lịch là nét).
                            i == index ? tabs[i].$2 : tabs[i].$1,
                            size: AppSize.icon24,
                            color: i == index ? context.colors.primary : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented control (Figma 5:242): nền muted-surface bo 10, đệm 4; ô chọn trắng bo 8 có bóng nhẹ, chữ cam.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                label: label,
                selected: v == value,
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: AppSize.buttonInCard,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? context.colors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: v == value
                          ? [BoxShadow(color: context.colors.shadow.withValues(alpha: 0.10), blurRadius: 3, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: context.text.label.copyWith(
                        color: v == value ? context.colors.primary : context.colors.onSurfaceVariant,
                        fontWeight: v == value ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip (Figma 91:156): bo 8, không viền; off nền muted-surface.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: selected ? context.colors.primaryContainer : context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.buttonInCard, minWidth: AppSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: selected ? context.colors.onPrimaryContainer : context.colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh nút đáy: đệm 12, nằm trên SafeArea.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.s12),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ),
      );
}
