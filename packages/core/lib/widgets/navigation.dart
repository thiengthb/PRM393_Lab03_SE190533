import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'layout.dart';

/// App bar: chỉ chữ, cùng màu nền trang. Top: tiêu đề lớn. Nested: quay lại + tiêu đề.
/// [icon] giữ cho tương thích, không còn vẽ (bớt chi tiết thừa trên thanh tiêu đề).
class QaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QaAppBar.top({super.key, required this.title, this.icon, this.actions = const []}) : nested = false;

  const QaAppBar.nested({super.key, required this.title, this.icon, this.actions = const []}) : nested = true;

  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final bool nested;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final titleStyle = nested ? context.text.title : context.text.titleLg;
    return AppBar(
      toolbarHeight: preferredSize.height,
      // Thanh đầu trang kiểu shadcn: nền thẻ, kẻ một đường dưới.
      backgroundColor: context.colors.surface,
      shape: Border(bottom: BorderSide(color: context.colors.outlineVariant, width: AppSize.border)),
      automaticallyImplyLeading: false,
      titleSpacing: nested ? 0 : AppSpace.screen,
      leading: nested
          ? IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 28),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Semantics(
        header: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(title, style: titleStyle, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      actions: [...actions, const SizedBox(width: AppSpace.s4)],
    );
  }
}

/// Thanh tab dọc cho màn rộng (bản Windows, trình duyệt laptop): cùng 4 tab với
/// [QaBottomNav], có chữ bên cạnh icon vì màn rộng đủ chỗ.
class QaSideNav extends StatelessWidget {
  const QaSideNav({super.key, required this.index, required this.onTap, this.header, this.footer});

  final int index;
  final ValueChanged<int> onTap;
  final Widget? header;
  final Widget? footer;

  /// Từ bề rộng này trở lên dùng [QaSideNav] thay cho [QaBottomNav].
  static const breakpoint = AppLayout.wide;

  @override
  Widget build(BuildContext context) => AppSideNav(
        dests: [for (final t in QaBottomNav.tabs) NavDest(label: t.$3, icon: t.$1, selectedIcon: t.$2)],
        index: index,
        onTap: onTap,
        header: header,
        footer: footer,
      );
}

/// Thanh tab đáy: nền trắng viền trên 1, icon trong viên thuốc 56x32 + nhãn 12.
/// Tab chọn: viên thuốc --accent trung tính, icon primary, nhãn mực (cùng luật thanh bên).
class QaBottomNav extends StatelessWidget {
  const QaBottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const tabs = [
    (LucideIcons.layoutDashboard, LucideIcons.layoutDashboard, 'Tổng quan'),
    (LucideIcons.qrCode, LucideIcons.qrCode, 'Điểm danh'),
    (LucideIcons.users, LucideIcons.users, 'Lớp'),
    (LucideIcons.settings, LucideIcons.settings, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
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
                      splashFactory: NoSplash.splashFactory,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == index ? c.secondaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Icon(
                              i == index ? tabs[i].$2 : tabs[i].$1,
                              size: AppSize.icon24,
                              color: i == index ? c.primary : c.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            tabs[i].$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.caption.copyWith(
                              color: i == index ? context.status.fgStrong : c.onSurfaceVariant,
                              fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
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

/// Segmented control = Tabs của shadcn: nền --muted bo 6, đệm 3; ô chọn trắng bo 4 bóng mảnh, chữ mực.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                    height: AppSize.buttonInDialog,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? context.colors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: v == value ? const [AppShadow.hairline] : null,
                    ),
                    child: Text(
                      label,
                      style: context.text.label.copyWith(
                        color: v == value ? context.status.fgStrong : context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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

/// Chip = Toggle shadcn bo 6: tắt = trắng viền 1, chữ phụ; bật = nền --accent, viền --input, chữ mực.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: selected ? c.outline : c.outlineVariant, width: AppSize.border),
    );
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.secondaryContainer : c.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.buttonInDialog, minWidth: AppSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: selected ? context.status.fgStrong : c.onSurfaceVariant,
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
