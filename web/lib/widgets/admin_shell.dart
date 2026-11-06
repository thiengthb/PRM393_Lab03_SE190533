import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/brand.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/admin_auth_viewmodel.dart';

/// Kích thước bố cục màn rộng, chỉ dùng ở web admin (handoff Lab 2 không có màn này).
abstract final class AdminSize {
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
  _Dest('/dashboard', 'Tổng quan', LucideIcons.layoutDashboard, LucideIcons.layoutDashboard),
  _Dest('/review', 'Duyệt lớp', LucideIcons.clipboardCheck, LucideIcons.clipboardCheck),
  _Dest('/subjects', 'Môn học', LucideIcons.bookOpen, LucideIcons.bookOpen),
  _Dest('/announcements', 'Thông báo', LucideIcons.megaphone, LucideIcons.megaphone),
];
const _adminDests = [
  _Dest('/users', 'Người dùng', LucideIcons.userCog, LucideIcons.userCog),
  _Dest('/crashes', 'Sự cố', LucideIcons.bug, LucideIcons.bug),
];

/// Khung màn rộng: thanh bên dùng chung với app giảng viên bản Windows ([AppSideNav]),
/// thu về thanh icon 72 khi cửa sổ hẹp hơn [AppLayout.wide].
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(adminUserProvider);
    final dests = [..._dests, if (user?.role == UserRole.admin) ..._adminDests];
    final wide = context.isWide;
    return Scaffold(
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppSideNav(
          collapsed: !wide,
          dests: [for (final d in dests) NavDest(label: d.label, icon: d.outlined, selectedIcon: d.filled)],
          index: dests.indexWhere((d) => d.path == location),
          onTap: (i) => context.go(dests[i].path),
          header: wide ? const BrandRow() : const Center(child: BrandMark(size: 32)),
          footer: user == null ? null : _UserBlock(user: user, wide: wide),
        ),
        Expanded(child: child),
      ]),
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
      padding: EdgeInsets.zero,
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
          icon: LucideIcons.logOut,
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

/// Nội dung trang rộng: lề 24, tối đa [AppLayout.page], đặt giữa.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.title, required this.icon, required this.children, this.actions = const []});

  final String title;
  final IconData icon;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: QaAppBar.top(title: title, icon: icon, actions: actions),
        body: ScreenBody(maxWidth: AppLayout.page, children: children),
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
              Semantics(header: true, namesRoute: true, child: Text(title, style: ctx.text.title)),
              const SizedBox(height: AppSpace.s16),
              builder(ctx),
            ]),
          ),
        ),
      ),
    );
