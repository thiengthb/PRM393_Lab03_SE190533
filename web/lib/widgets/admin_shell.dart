import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/brand.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/admin_auth_viewmodel.dart';

/// Kích thước bố cục màn rộng, chỉ dùng ở web admin (handoff Lab 2 không có màn này).
abstract final class AdminSize {
  static const rail = 240.0;
  static const railCollapsed = 72.0;
  static const wideBreakpoint = 900.0;
  static const pageMax = 1100.0;
  static const formDialog = 480.0;
  static const filterField = 280.0;
  static const searchField = 320.0;
  static const segmentedWide = 420.0;
  static const codeColumn = 112.0;
  static const rateValue = 96.0;
}

class _Dest {
  const _Dest(this.path, this.label, this.outlined, this.filled);
  final String path;
  final String label;
  final IconData outlined;
  final IconData filled;
}

const _dests = [
  _Dest('/dashboard', 'Tổng quan', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Dest('/review', 'Duyệt lớp', Icons.fact_check_outlined, Icons.fact_check_rounded),
  _Dest('/subjects', 'Môn học', Icons.menu_book_outlined, Icons.menu_book_rounded),
  _Dest('/announcements', 'Thông báo', Icons.campaign_outlined, Icons.campaign_rounded),
];
const _adminDests = [
  _Dest('/users', 'Người dùng', Icons.manage_accounts_outlined, Icons.manage_accounts_rounded),
  _Dest('/crashes', 'Sự cố', Icons.bug_report_outlined, Icons.bug_report_rounded),
];

/// Khung màn rộng: thanh bên 240 (≥ 900) hoặc thanh icon 72 (màn hẹp), nội dung bên phải.
/// Quy tắc chọn trên thanh bên giống tab Lab 2: icon đặc trong ô primary-soft, không viền.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(adminUserProvider);
    final dests = [..._dests, if (user?.role == UserRole.admin) ..._adminDests];
    final wide = MediaQuery.sizeOf(context).width >= AdminSize.wideBreakpoint;
    return Scaffold(
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          width: wide ? AdminSize.rail : AdminSize.railCollapsed,
          decoration: BoxDecoration(border: Border(right: BorderSide(color: context.colors.outlineVariant))),
          child: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.s16),
                child: wide ? const BrandRow() : const Center(child: BrandMark(size: 32)),
              ),
              const SizedBox(height: AppSpace.s8),
              for (final d in dests)
                _NavItem(dest: d, selected: location == d.path, wide: wide, onTap: () => context.go(d.path)),
              const Spacer(),
              if (user != null) _UserBlock(user: user, wide: wide),
            ]),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.dest, required this.selected, required this.wide, required this.onTap});
  final _Dest dest;
  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s4),
      child: Semantics(
        label: dest.label,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child: Material(
          color: selected ? context.colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: SizedBox(
              height: AppSize.touch,
              child: Row(
                mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  if (wide) const SizedBox(width: AppSpace.s12),
                  Tooltip(
                    message: wide ? '' : dest.label,
                    child: Icon(selected ? dest.filled : dest.outlined, size: AppSize.icon24, color: color),
                  ),
                  if (wide) ...[
                    const SizedBox(width: AppSpace.s12),
                    Text(dest.label, style: context.text.label.copyWith(color: selected ? context.colors.onPrimaryContainer : context.colors.onSurface)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBlock extends ConsumerWidget {
  const _UserBlock({required this.user, required this.wide});
  final AppUser user;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Row(mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
        if (wide) ...[
          InitialsAvatar(name: user.displayName),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName, style: context.text.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(user.role.label, style: context.text.bodySm),
            ]),
          ),
        ],
        AppIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Đăng xuất',
          onPressed: () async {
            final ok = await AppDialog.confirm(context, title: 'Đăng xuất?', message: user.email, confirmLabel: 'Đăng xuất', destructive: true);
            if (ok) await ref.read(adminAuthViewModelProvider.notifier).signOut();
          },
        ),
      ]),
    );
  }
}

/// Nội dung trang rộng: lề 24, tối đa 1100.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.title, required this.icon, required this.children, this.actions = const []});

  final String title;
  final IconData icon;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: QaAppBar.top(title: title, icon: icon, actions: actions),
        body: ScreenBody(
          maxWidth: AdminSize.pageMax,
          padding: const EdgeInsets.fromLTRB(AppSpace.s24, AppSpace.s8, AppSpace.s24, AppSpace.s32),
          children: children,
        ),
      );
}

/// Hộp thoại form rộng tối đa 480, dùng token như Dialog Lab 2.
Future<T?> showAdminForm<T>(BuildContext context, {required String title, required WidgetBuilder builder}) => showDialog<T>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpace.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AdminSize.formDialog),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: ctx.text.title),
              const SizedBox(height: AppSpace.s16),
              builder(ctx),
            ]),
          ),
        ),
      ),
    );
