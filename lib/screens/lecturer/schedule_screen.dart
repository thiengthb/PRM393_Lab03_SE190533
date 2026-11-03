import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../widgets/widgets.dart';

/// GV-002 Điểm danh v2 (Figma `266:4364`): chuyển tuần, dải T2 đến CN, slot của ngày đang chọn.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scheduleViewModelProvider);
    final vm = ref.read(scheduleViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.top(title: 'Điểm danh', icon: Icons.qr_code_2_outlined),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList(count: 1, height: 100), SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Ready(:final data) => _Body(data: data, vm: vm),
        Empty() => const SizedBox.shrink(),
      },
    );
  }
}

/// Đích khi bấm thẻ slot (GV-101 đã bỏ ở v2): slot sắp tới không bấm được,
/// slot đang diễn ra hoặc chưa chốt mở GV-102, slot đã chốt mở GV-102 .S.
VoidCallback? openSlot(BuildContext context, Slot slot, DateTime now) =>
    slot.phaseAt(now) == SlotPhase.upcoming ? null : () => context.push('/session/${slot.id}');

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.vm});
  final ScheduleData data;
  final ScheduleViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return ScreenBody(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s4, AppSpace.screen, AppSpace.s24),
      children: [
        _WeekPager(weekStart: d.weekStart, onShift: vm.shiftWeek),
        const SizedBox(height: AppSpace.s8),
        Row(children: [
          for (final (i, day) in d.week.indexed)
            Expanded(
              child: _DayCell(
                day: day,
                selected: VnDate.sameDay(day, d.selectedDay),
                today: VnDate.sameDay(day, d.now),
                hasSlots: d.daysWithSlots.contains(i),
                onTap: () => vm.selectDay(day),
              ),
            ),
        ]),
        const SizedBox(height: AppSpace.s16),
        if (!d.hasClasses)
          EmptyState(
            icon: Icons.calendar_today_outlined,
            message: 'Chưa có lịch',
            detail: 'Hãy nhập danh sách lớp',
            actionLabel: 'Nhập',
            actionIcon: Icons.upload_file_outlined,
            onAction: () => context.push('/import'),
          )
        else ...[
          Semantics(header: true, child: Text(VnDate.dayLabel(d.selectedDay), style: context.text.section)),
          const SizedBox(height: AppSpace.s12),
          if (d.isEmpty)
            const EmptyState(icon: Icons.event_busy_outlined, message: 'Không có slot')
          else
            for (final slot in d.slots) ...[
              SlotCard(
                slot: slot,
                phase: slot.phaseAt(d.now),
                isNextUpcoming: slot.id == d.nextUpcomingId,
                onTap: openSlot(context, slot, d.now),
                onAction: () => context.push('/session/${slot.id}'),
              ),
              const SizedBox(height: AppSpace.s12),
            ],
        ],
      ],
    );
  }
}

class _WeekPager extends StatelessWidget {
  const _WeekPager({required this.weekStart, required this.onShift});
  final DateTime weekStart;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final fg = context.status.fgStrong;
    return Row(children: [
      IconButton(
        icon: Icon(Icons.chevron_left, color: fg),
        tooltip: 'Tuần trước',
        onPressed: () => onShift(-1),
        constraints: const BoxConstraints.tightFor(width: AppSize.touch, height: AppSize.touch),
      ),
      Expanded(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: 2),
            decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(VnDate.weekRange(weekStart), style: context.text.title.copyWith(color: fg)),
          ),
        ),
      ),
      IconButton(
        icon: Icon(Icons.chevron_right, color: fg),
        tooltip: 'Tuần sau',
        onPressed: () => onShift(1),
        constraints: const BoxConstraints.tightFor(width: AppSize.touch, height: AppSize.touch),
      ),
    ]);
  }
}

/// Ô ngày v2 (`266:4363`): thường, đang chọn (ô primary), hôm nay không chọn (ô primary-soft).
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.today, required this.hasSlots, required this.onTap});
  final DateTime day;
  final bool selected;
  final bool today;
  final bool hasSlots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color? box, Color numColor, Color label) = selected
        ? (c.primary, c.onPrimary, c.primary)
        : today
            ? (c.primaryContainer, c.onPrimaryContainer, c.onPrimaryContainer)
            : (null, context.status.fgStrong, c.onSurfaceVariant);
    return Semantics(
      label: '${VnDate.dayLabel(day)}${today ? ', hôm nay' : ''}${hasSlots ? ', có slot' : ', không có slot'}',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
          child: Column(children: [
            Text(VnDate.shortWeekdays[day.weekday - 1], style: context.text.bodySm.copyWith(color: label, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpace.s4),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: box, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text(
                '${day.day}',
                style: context.text.section.copyWith(
                  color: numColor,
                  fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
