import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/widgets/widgets.dart';

import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/rate_bars.dart';

/// Tổng quan: trả lời “có gì cần làm và lớp nào đáng lo?”.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(dashboardViewModelProvider);
    final vm = ref.read(dashboardViewModelProvider.notifier);
    return DeskPage(
      title: 'Tổng quan',
      subtitle: 'Việc cần làm và lớp nào đáng lo',
      actions: [AppButton(label: 'Tải lại', icon: LucideIcons.refreshCw, style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, onPressed: vm.load)],
      scroll: true,
      maxWidth: 1400,
      body: switch (s) {
        Loading() => const Column(children: [SkeletonList(count: 1, height: 88), SkeletonList(count: 3, height: 48)]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.load),
        Empty() => const EmptyState(message: 'Chưa có dữ liệu', detail: 'Chờ giảng viên nhập lớp', icon: LucideIcons.chartLine),
        Ready(:final data) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Lead area: the one thing an admin acts on today.
            _PendingLead(count: data.figures.pendingClasses),
            const SizedBox(height: AppSpace.s16),
            Row(children: [
              Expanded(child: StatTile(value: '${data.figures.approvedClasses}', label: 'lớp đã duyệt', icon: LucideIcons.bookOpen)),
              const SizedBox(width: AppSpace.s12),
              Expanded(child: StatTile(value: '${data.figures.students}', label: 'sinh viên', icon: LucideIcons.users)),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: StatTile(
                  value: data.figures.presentPercent == null ? null : '${data.figures.presentPercent}%',
                  label: 'có mặt · ${data.figures.closedSlots} buổi',
                  icon: LucideIcons.circleCheck,
                ),
              ),
            ]),
            const SizedBox(height: AppSpace.s16),
            DeskCard(
              title: 'Có mặt theo môn',
              padding: const EdgeInsets.all(AppSpace.s16),
              child: data.rates.isEmpty
                  ? const EmptyState(message: 'Chưa có buổi đã chốt', icon: LucideIcons.chartColumn, boxed: false)
                  : RateBars(rows: data.rates),
            ),
          ]),
      },
    );
  }
}

class _PendingLead extends StatelessWidget {
  const _PendingLead({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final c = context.colors;
    final has = count > 0;
    return DeskCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s20, vertical: AppSpace.s16),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: has ? st.warningSoft : st.successSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Icon(has ? LucideIcons.clipboardCheck : LucideIcons.circleCheck, size: 20, color: has ? st.warning : st.success),
        ),
        const SizedBox(width: AppSpace.s16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(has ? '$count lớp chờ duyệt' : '0 lớp chờ duyệt', style: context.text.titleLg),
            Text(has ? 'Giảng viên đang chờ để bắt đầu điểm danh' : 'Đã xử lý hết', style: context.text.bodySm.copyWith(color: c.onSurfaceVariant)),
          ]),
        ),
        if (has) AppButton(label: 'Mở hàng đợi', icon: LucideIcons.arrowRight, size: AppButtonSize.medium, expand: false, onPressed: () => context.go('/review')),
      ]),
    );
  }
}
