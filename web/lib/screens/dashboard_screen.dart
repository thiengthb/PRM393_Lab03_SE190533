import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/view_state.dart';
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
      icon: Icons.space_dashboard_rounded,
      actions: [AppIconButton(icon: Icons.refresh_rounded, tooltip: 'Tải lại', onPressed: vm.load)],
      children: switch (s) {
        Loading() => const [SkeletonList(count: 1, height: 88), SkeletonList(count: 3, height: 48)],
        Failure(:final message) => [ErrorState(message: message, onRetry: vm.load)],
        Empty() => const [EmptyState(message: 'Chưa có dữ liệu', detail: 'Chờ giảng viên nhập lớp', icon: Icons.insights_outlined)],
        Ready(:final data) => [
            LayoutBuilder(builder: (context, c) {
              final f = data.figures;
              final tiles = [
                StatTile(
                  value: '${f.pendingClasses}',
                  label: 'lớp chờ duyệt',
                  icon: Icons.fact_check_outlined,
                  onTap: () => context.go('/review'),
                ),
                StatTile(value: '${f.approvedClasses}', label: 'lớp đã duyệt', icon: Icons.menu_book_outlined),
                StatTile(value: '${f.students}', label: 'sinh viên', icon: Icons.group_outlined),
                StatTile(
                  value: f.presentPercent == null ? null : '${f.presentPercent}%',
                  label: 'có mặt · ${f.closedSlots} buổi',
                  icon: Icons.check_circle_outline,
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
              const EmptyState(message: 'Chưa có buổi đã chốt', icon: Icons.bar_chart_rounded)
            else
              QaCard(child: RateBars(rows: data.rates)),
          ],
      },
    );
  }
}
