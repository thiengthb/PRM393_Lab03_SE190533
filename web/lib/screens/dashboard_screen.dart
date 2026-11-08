import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/admin_shell.dart';
import '../widgets/rate_bars.dart';

/// Tổng quan: trả lời “có gì cần làm và lớp nào đáng lo?”.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(dashboardViewModelProvider);
    final vm = ref.read(dashboardViewModelProvider.notifier);
    return AdminPage(
      title: 'Tổng quan',
      icon: LucideIcons.layoutDashboard,
      actions: [AppIconButton(icon: LucideIcons.refreshCw, tooltip: 'Tải lại', onPressed: vm.load)],
      children: switch (s) {
        Loading() => const [SkeletonList(count: 1, height: 88), SkeletonList(count: 3, height: 48)],
        Failure(:final message) => [ErrorState(message: message, onRetry: vm.load)],
        Empty() => const [EmptyState(message: 'Chưa có dữ liệu', detail: 'Chờ giảng viên nhập lớp', icon: LucideIcons.chartLine)],
        Ready(:final data) => [
            LayoutBuilder(builder: (context, c) {
              final f = data.figures;
              final tiles = [
                StatTile(
                  value: '${f.pendingClasses}',
                  label: 'lớp chờ duyệt',
                  icon: LucideIcons.clipboardCheck,
                  onTap: () => context.go('/review'),
                ),
                StatTile(value: '${f.approvedClasses}', label: 'lớp đã duyệt', icon: LucideIcons.bookOpen),
                StatTile(value: '${f.students}', label: 'sinh viên', icon: LucideIcons.users),
                StatTile(
                  value: f.presentPercent == null ? null : '${f.presentPercent}%',
                  label: 'có mặt · ${f.closedSlots} buổi',
                  icon: LucideIcons.circleCheck,
                ),
              ];
              final perRow = c.maxWidth >= 720 ? 4 : 2;
              final w = (c.maxWidth - AppSpace.s12 * (perRow - 1)) / perRow;
              return Wrap(
                spacing: AppSpace.s12,
                runSpacing: AppSpace.s12,
                children: [for (final t in tiles) SizedBox(width: w, child: t)],
              );
            }),
            const SizedBox(height: AppSpace.group),
            Text('Có mặt theo môn', style: context.text.section),
            const SizedBox(height: AppSpace.s8),
            if (data.rates.isEmpty)
              const EmptyState(message: 'Chưa có buổi đã chốt', icon: LucideIcons.chartColumn)
            else
              QaCard(child: RateBars(rows: data.rates)),
          ],
      },
    );
  }
}
