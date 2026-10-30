import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/overview_viewmodel.dart';
import '../../widgets/widgets.dart';

/// GV-001 Tổng quan.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(overviewViewModelProvider);
    final vm = ref.read(overviewViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.top(title: 'Tổng quan', icon: Icons.space_dashboard_rounded),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList(count: 1, height: 28), SkeletonList(count: 2, height: 80), SkeletonList(count: 3)]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Ready(:final data) => _OverviewBody(data: data),
        Empty() => const SizedBox.shrink(),
      },
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.data});
  final OverviewData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    String? v(int n) => d.hasClasses ? '$n' : null;
    return ScreenBody(
      children: [
        DateHeader(left: d.term, right: VnDate.dayLabel(d.today)),
        const SizedBox(height: AppSpace.s12),
        Row(children: [
          Expanded(child: StatTile(value: v(d.classCount), label: 'lớp đang dạy', onTap: () => context.go('/classes'))),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: StatTile(value: v(d.studentCount), label: 'sinh viên')),
        ]),
        const SizedBox(height: AppSpace.s8),
        Row(children: [
          Expanded(
            child: StatTile(
              value: d.hasClasses ? (d.presentPercent == null ? '—' : '${d.presentPercent}%') : null,
              label: 'có mặt tuần này',
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: StatTile(value: v(d.pendingCount), label: 'yêu cầu sửa', onTap: () => context.push('/requests')),
          ),
        ]),
        const SizedBox(height: AppSpace.group),
        if (!d.hasClasses)
          // .E2 kỳ chưa có lớp.
          EmptyState(
            icon: Icons.calendar_today_outlined,
            message: 'Chưa có lịch',
            detail: 'Hãy nhập danh sách lớp',
            actionLabel: 'Nhập',
            actionIcon: Icons.upload_file_outlined,
            onAction: () => context.push('/import'),
          )
        else ...[
          if (d.card != null) ...[
            SlotCard(
              slot: d.card!,
              phase: d.cardPhase!,
              isNextUpcoming: true,
              onTap: () => context.push('/slot/${d.card!.id}'),
              onAction: () => context.push('/session/${d.card!.id}'),
            ),
            const SizedBox(height: AppSpace.group),
          ],
          SectionHeader(
            title: 'Chú ý',
            icon: Icons.warning_rounded,
            iconColor: context.status.warning,
            actionLabel: 'Xem tất cả',
            onAction: () => context.push('/attention'),
          ),
          if (d.attention.isEmpty)
            const EmptyState(message: 'Trống', icon: Icons.check_circle_outline)
          else
            for (final a in d.attention) ...[
              AttentionRow(
                item: a,
                onTap: () => context.push('/student/${a.schoolClass.id}/${a.student.code}'),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
        ],
      ],
    );
  }
}

