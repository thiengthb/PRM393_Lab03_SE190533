import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'brand.dart';

/// Màn rộng (≥ [AppLayout.wide]): bản Windows, trình duyệt laptop.
extension WideContext on BuildContext {
  bool get isWide => AppLayout.isWide(MediaQuery.sizeOf(this).width);
}

/// Đặt ở `MaterialApp.builder` của cả ba app: trên màn rộng chữ to hơn một bậc
/// (15 → 16, 13 → 14) để không bị nhỏ khi ngồi xa màn laptop. Vẫn giữ cỡ chữ người dùng chọn.
class WideTextScale extends StatelessWidget {
  const WideTextScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (!AppLayout.isWide(mq.size.width)) return child;
    final base = mq.textScaler.scale(100) / 100;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(base * AppLayout.wideTextScale)),
      child: child,
    );
  }
}

/// Hai cột khi đủ rộng ([AppLayout.twoColumns]), còn lại xếp chồng: [main] trước, [side] sau.
/// Dùng trong [ScreenBody] với `maxWidth: AppLayout.page`.
class TwoColumns extends StatelessWidget {
  const TwoColumns({super.key, required this.main, required this.side, this.mainFlex = 3, this.sideFlex = 2});

  final List<Widget> main;
  final List<Widget> side;
  final int mainFlex;
  final int sideFlex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        Widget col(List<Widget> children) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children);
        if (c.maxWidth < AppLayout.twoColumns) {
          return col([...main, const SizedBox(height: AppSpace.group), ...side]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: mainFlex, child: col(main)),
          const SizedBox(width: AppSpace.group),
          Expanded(flex: sideFlex, child: col(side)),
        ]);
      });
}

/// Một mục của thanh bên.
class NavDest {
  const NavDest({required this.label, required this.icon, required this.selectedIcon});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Thanh bên dùng chung cho màn rộng: app giảng viên bản Windows và web admin.
/// Rộng [AppLayout.rail] có chữ; [collapsed] thì còn [AppLayout.railCollapsed], chỉ icon kèm tooltip.
/// Kiểu `sidebar.tsx` thienui: nền --sidebar (muted), mục chọn nền --sidebar-accent, chữ mực đậm 500.
class AppSideNav extends StatelessWidget {
  const AppSideNav({
    super.key,
    required this.dests,
    required this.index,
    required this.onTap,
    this.header,
    this.footer,
    this.collapsed = false,
  });

  final List<NavDest> dests;

  /// -1 khi trang hiện tại không thuộc mục nào.
  final int index;
  final ValueChanged<int> onTap;
  final Widget? header;
  final Widget? footer;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(right: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: collapsed ? AppLayout.railCollapsed : AppLayout.rail,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (header != null) ...[header!, const SizedBox(height: AppSpace.s24)],
              for (var i = 0; i < dests.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _SideNavItem(dest: dests[i], selected: i == index, collapsed: collapsed, onTap: () => onTap(i)),
                ),
              const Spacer(),
              ?footer,
            ]),
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.dest, required this.selected, required this.collapsed, required this.onTap});
  final NavDest dest;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = Icon(selected ? dest.selectedIcon : dest.icon, size: AppSize.icon20, color: selected ? c.primary : c.onSurfaceVariant);
    return Semantics(
      label: dest.label,
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: collapsed
                ? Tooltip(message: dest.label, child: Center(child: icon))
                : Row(children: [
                    const SizedBox(width: AppSpace.s12),
                    icon,
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Text(
                        dest.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.label.copyWith(
                          color: selected ? context.status.fgStrong : c.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Lưới thẻ: trên điện thoại một cột, màn rộng chia đều thành nhiều cột, mỗi cột tối thiểu [minItemWidth].
/// Dùng cho danh sách thẻ (lớp, slot) để màn rộng không còn cột hẹp giữa khoảng trống.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children, this.minItemWidth = 360, this.spacing = AppSpace.s12});

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = ((c.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, 4);
        if (cols == 1) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: spacing), children[i]],
          ]);
        }
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [for (final x in children) SizedBox(width: w, child: x)]);
      });
}

/// Khung các màn đăng nhập, đăng ký, quên mật khẩu (app giảng viên, web sinh viên, web admin).
/// Điện thoại: logo, tiêu đề lớn, rồi form. Màn rộng: nửa trái là dải màu thương hiệu có logo và
/// [tagline], nửa phải là form căn giữa trong cột 400.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.tagline = 'Điểm danh bằng mã QR, chốt buổi trong một chạm.',
    this.points = const ['Sinh viên quét mã, không cần gọi tên', 'Nhắc khi còn slot chưa chốt', 'Báo cáo lớp xuất PDF'],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String tagline;
  final List<String> points;

  /// Nút quay lại (màn con như Quên mật khẩu).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
      if (!wide) ...[
        const SizedBox(height: AppSpace.s16),
        const BrandRow(),
        const SizedBox(height: AppSpace.s32),
      ],
      Semantics(header: true, child: Text(title, style: context.text.display)),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpace.s8),
        Text(subtitle!, style: context.text.body.copyWith(color: context.colors.onSurfaceVariant)),
      ],
      const SizedBox(height: AppSpace.s24),
      ...children,
    ]);
    if (!wide) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.s20, AppSpace.s8, AppSpace.s20, AppSpace.s24),
            children: [form],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Row(children: [
        Expanded(flex: 5, child: _BrandPanel(tagline: tagline, points: points)),
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.s32),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: form),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.tagline, required this.points});
  final String tagline;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    // Nửa trái kiểu khối đăng nhập shadcn: nền --muted phẳng, chữ mực, điểm nhấn teal nhỏ.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        border: Border(right: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const BrandMark(size: 32),
            const SizedBox(width: AppSpace.s8),
            Text('Hereby', style: context.text.title),
          ]),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(tagline, style: context.text.display.copyWith(fontSize: 30, height: 1.2, letterSpacing: -0.8)),
          ),
          const SizedBox(height: AppSpace.s24),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: Row(children: [
                Icon(LucideIcons.circleCheck, size: 18, color: c.primary),
                const SizedBox(width: AppSpace.s12),
                Flexible(child: Text(p, style: context.text.body.copyWith(color: st.fgStrong))),
              ]),
            ),
          const Spacer(),
          Text('FPT University · PRM393', style: context.text.bodySm),
        ]),
      ),
    );
  }
}

