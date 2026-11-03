import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/lecturer_feed.dart';
import '../../viewmodels/overview_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
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

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({required this.data});
  final OverviewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final vm = ref.read(overviewViewModelProvider.notifier);
    final offline = ref.watch(lecturerOfflineViewModelProvider);
    String? v(int n) => d.hasClasses ? '$n' : null;
    return ScreenBody(
      children: [
        // .X mất mạng: dữ liệu bên dưới là bản lưu trên máy.
        if (offline != null) ...[
          OfflineBanner(
            title: 'Mất mạng',
            detail: switch (offline.lastSync) {
              null => 'Đang xem dữ liệu trên máy',
              final t => 'Dữ liệu lúc ${VnDate.hm(t)}${VnDate.sameDay(t, d.today) ? '' : ' ${VnDate.dm(t)}'}',
            },
            onRetry: ref.read(lecturerOfflineViewModelProvider.notifier).retry,
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        _TodayHeader(today: d.today, term: d.term),
        const SizedBox(height: AppSpace.s12),
        Row(children: [
          Expanded(child: StatTile(value: v(d.classCount), label: 'lớp đang dạy', icon: Icons.menu_book_outlined)),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: StatTile(value: v(d.studentCount), label: 'sinh viên', icon: Icons.group_outlined)),
        ]),
        const SizedBox(height: AppSpace.s8),
        Row(children: [
          Expanded(
            child: StatTile(
              value: d.hasClasses ? (d.presentPercent == null ? '—' : '${d.presentPercent}%') : null,
              label: 'có mặt tuần này',
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: StatTile(value: v(d.pendingCount), label: 'yêu cầu sửa', icon: Icons.edit_outlined, onTap: () => context.push('/requests')),
          ),
        ]),
        const SizedBox(height: AppSpace.s16),
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
          // .D3 một slot quên chốt, .D4 nhiều slot quên chốt (mở OV6).
          if (d.unclosed.length == 1) ...[
            _UnclosedStrip(
              title: d.unclosed.single.classLabel,
              detail: '${VnDate.hm(d.unclosed.single.start)}${VnDate.sameDay(d.unclosed.single.start, d.today) ? '' : ' ${VnDate.dm(d.unclosed.single.start)}'} chưa chốt',
              actionLabel: 'Chốt ngay',
              onAction: () => context.push('/session/${d.unclosed.single.id}'),
            ),
            const SizedBox(height: AppSpace.s16),
          ] else if (d.unclosed.length > 1) ...[
            _UnclosedStrip(
              title: '${d.unclosed.length} slot chưa chốt',
              detail: 'Mới nhất ${VnDate.hm(d.unclosed.first.start)} ${VnDate.dm(d.unclosed.first.start)}',
              actionLabel: 'Xem',
              onAction: () => context.push('/unclosed'),
            ),
            const SizedBox(height: AppSpace.s16),
          ],
          if (d.card != null) ...[
            SlotCard(
              slot: d.card!,
              phase: d.cardPhase!,
              isNextUpcoming: true,
              onTap: d.cardPhase == SlotPhase.upcoming ? null : () => context.push('/session/${d.card!.id}'),
              onAction: () => context.push('/session/${d.card!.id}'),
            ),
            const SizedBox(height: AppSpace.group),
          ],
          SectionHeader(
            title: 'Vắng nhiều',
            actionLabel: 'Xem tất cả',
            onAction: () => context.push('/attention'),
          ),
          if (d.attention.isEmpty)
            const EmptyState(message: 'Chưa có ai vắng nhiều', icon: Icons.check_circle_outline)
          else
            for (final a in d.attention) ...[
              AttentionRow(
                item: a,
                onTap: () => context.push('/student/${a.schoolClass.id}/${a.student.code}'),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
          const SizedBox(height: AppSpace.group),
          MonthCalendar(
            month: d.month,
            today: d.today,
            dots: d.monthDots,
            slotCount: d.monthSlotCount,
            onShift: vm.shiftMonth,
            onSelect: (day) {
              ref.read(scheduleViewModelProvider.notifier).showDay(day);
              context.go('/schedule');
            },
          ),
        ],
      ],
    );
  }
}

/// Hàng ngày v2: icon lịch + thứ, ngày đậm bên trái, kỳ bên phải.
class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.today, required this.term});
  final DateTime today;
  final String term;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(Icons.calendar_today_outlined, size: AppSize.icon20, color: context.status.fgStrong),
        const SizedBox(width: AppSpace.s8),
        Expanded(child: Text(VnDate.dayLabel(today), style: context.text.section)),
        Text(term, style: context.text.bodySm),
      ]);
}

/// Dải quên chốt (`262:4655`): nền vàng nhạt, luôn có chữ, nút chính bên phải.
class _UnclosedStrip extends StatelessWidget {
  const _UnclosedStrip({required this.title, required this.detail, required this.actionLabel, required this.onAction});
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, AppSpace.s4, AppSpace.s8, AppSpace.s4),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: st.warningSoft,
          border: Border.all(color: st.warningSoftEdge),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Icon(Icons.warning_rounded, size: AppSize.icon20, color: st.warning),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w700)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          AppButton(label: actionLabel, size: AppButtonSize.medium, expand: false, onPressed: onAction),
        ]),
      ),
    );
  }
}

/// GV-OV6 (`307:4982`): danh sách slot chưa chốt, mới nhất trước.
class UnclosedSlotsScreen extends ConsumerWidget {
  const UnclosedSlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(overviewViewModelProvider);
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Slot chưa chốt', icon: Icons.warning_rounded),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: ref.read(overviewViewModelProvider.notifier).retry),
        Ready(:final data) => ScreenBody(children: [
            if (data.unclosed.isEmpty) const EmptyState(icon: Icons.check_circle_outline, message: 'Đã chốt hết'),
            for (final slot in data.unclosed) ...[
              Text(VnDate.dayLabel(slot.start), style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              SlotCard(
                slot: slot,
                phase: SlotPhase.unclosed,
                onTap: () => context.push('/session/${slot.id}'),
                onAction: () => context.push('/session/${slot.id}'),
              ),
              const SizedBox(height: AppSpace.s16),
            ],
          ]),
      },
    );
  }
}
