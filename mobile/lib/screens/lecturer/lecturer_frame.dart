import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/config/app_config.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/widgets/brand.dart';
import 'package:attendo_core/widgets/widgets.dart';
import '../../viewmodels/account_viewmodels.dart';

/// Sections of the lecturer app on desktop. Phone keeps the 4 bottom tabs; desktop shows
/// every top-level place in the sidebar so nothing hides behind a pushed page.
enum LecturerSection {
  overview('Tổng quan', LucideIcons.layoutDashboard, '/overview'),
  schedule('Điểm danh', LucideIcons.qrCode, '/schedule'),
  classes('Lớp', LucideIcons.users, '/classes'),
  requests('Yêu cầu sửa', LucideIcons.messageSquareWarning, '/requests'),
  inbox('Hộp thư', LucideIcons.inbox, '/inbox'),
  account('Tài khoản', LucideIcons.settings, '/account');

  const LecturerSection(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;

  /// Bottom tab index (phone shell) → section.
  static LecturerSection ofTab(int i) => const [overview, schedule, classes, account][i];
}

/// Desktop frame of the lecturer app: sidebar on the left, page on the right.
/// On a phone it returns [child] unchanged.
class LecturerFrame extends ConsumerWidget {
  const LecturerFrame({super.key, required this.section, required this.child});

  final LecturerSection? section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.isDesktop) return child;
    final user = ref.watch(accountViewModelProvider).dataOrNull;
    const sections = LecturerSection.values;
    return Scaffold(
      body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppSideNav(
          dests: [for (final s in sections) NavDest(label: s.label, icon: s.icon, selectedIcon: s.icon)],
          index: section == null ? -1 : sections.indexOf(section!),
          onTap: (i) => context.go(sections[i].path),
          header: const Padding(padding: EdgeInsets.only(left: AppSpace.s4, top: AppSpace.s4), child: BrandWordmark(size: 22)),
          footer: user == null
              ? null
              : Container(
                  padding: const EdgeInsets.only(top: AppSpace.s12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.outlineVariant, width: AppSize.border))),
                  child: Row(children: [
                    InitialsAvatar(name: user.displayName, size: 32),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySm.copyWith(color: context.status.fgStrong, fontWeight: FontWeight.w500)),
                        Text('Giảng viên', style: context.text.caption),
                      ]),
                    ),
                  ]),
                ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

/// Page for a pushed lecturer route: on desktop no slide animation and the sidebar stays put.
Page<void> lecturerPage(BuildContext context, GoRouterState state, LecturerSection? section, Widget child) {
  if (!context.isDesktop || AppConfig.portal != UserRole.lecturer) return MaterialPage<void>(key: state.pageKey, child: child);
  return NoTransitionPage<void>(key: state.pageKey, child: LecturerFrame(section: section, child: child));
}
