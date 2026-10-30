import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../widgets/widgets.dart';

/// GV-002 Lịch.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scheduleViewModelProvider);
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final view = s.dataOrNull?.view ?? ScheduleView.today;
    return Scaffold(
      appBar: const QaAppBar.top(title: 'Lịch', icon: Icons.calendar_today_outlined),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s8, AppSpace.screen, 0),
            child: AppSegmented<ScheduleView>(
              options: const [(ScheduleView.today, 'Hôm nay'), (ScheduleView.week, 'Tuần'), (ScheduleView.month, 'Tháng')],
              value: view,
              onChanged: vm.setView,
            ),
          ),
          Expanded(
            child: switch (s) {
              Loading() => const ScreenBody(children: [SkeletonList()]),
              Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
              Ready(:final data) => _Body(data: data, vm: vm),
              Empty() => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.vm});
  final ScheduleData data;
  final ScheduleViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final header = switch (d.view) {
      ScheduleView.today => DateHeader(left: d.term, right: VnDate.dayLabel(d.now)),
      ScheduleView.week => _Pager(label: VnDate.weekRange(d.anchor), onShift: vm.shift),
      ScheduleView.month => _Pager(label: VnDate.month(d.anchor), onShift: vm.shift),
    };
    return ScreenBody(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s16, AppSpace.screen, AppSpace.s24),
      children: [
        header,
        if (d.view == ScheduleView.month) ...[
          const SizedBox(height: AppSpace.s8),
          _MonthGrid(data: d, onSelect: vm.selectDay),
        ],
        const SizedBox(height: AppSpace.s16),
        if (!d.hasClasses)
          EmptyState(
            icon: Icons.calendar_today_outlined,
            message: 'Chưa có lịch',
            actionLabel: 'Nhập',
            actionIcon: Icons.upload_file_outlined,
            onAction: () => context.push('/import'),
          )
        else if (d.isEmpty)
          const EmptyState(icon: Icons.event_busy_outlined, message: 'Lịch trống')
        else
          for (final day in d.days) ...[
            if (d.view != ScheduleView.today)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: Row(children: [
                  Text(VnDate.dayLabel(day.day), style: context.text.section),
                  if (VnDate.sameDay(day.day, d.now)) ...[
                    const SizedBox(width: AppSpace.s8),
                    Text('Hôm nay', style: context.text.label.copyWith(color: context.colors.primary)),
                  ],
                ]),
              ),
            for (final slot in day.slots) ...[
              SlotCard(
                slot: slot,
                phase: slot.phaseAt(d.now),
                isNextUpcoming: slot.id == d.nextUpcomingId,
                onTap: () => context.push('/slot/${slot.id}'),
                onAction: () => context.push('/session/${slot.id}'),
              ),
              const SizedBox(height: AppSpace.s12),
            ],
            const SizedBox(height: AppSpace.s8),
          ],
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.label, required this.onShift});
  final String label;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: context.text.section)),
          AppIconButton(icon: Icons.chevron_left, tooltip: 'Trước', onPressed: () => onShift(-1)),
          AppIconButton(icon: Icons.chevron_right, tooltip: 'Sau', onPressed: () => onShift(1)),
        ],
      );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.data, required this.onSelect});
  final ScheduleData data;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = data.anchor;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    return Column(
      children: [
        Row(children: [
          for (final w in VnDate.shortWeekdays)
            Expanded(child: Center(child: Text(w, style: context.text.caption))),
        ]),
        const SizedBox(height: AppSpace.s4),
        for (var r = 0; r < rows; r++)
          Row(children: [
            for (var c = 0; c < 7; c++)
              Expanded(child: _cell(context, r * 7 + c - lead + 1, daysInMonth)),
          ]),
      ],
    );
  }

  Widget _cell(BuildContext context, int day, int max) {
    if (day < 1 || day > max) return const SizedBox(height: 44);
    final date = DateTime(data.anchor.year, data.anchor.month, day);
    final selected = VnDate.sameDay(date, data.selectedDay);
    final today = VnDate.sameDay(date, data.now);
    final has = data.daysWithSlots.contains(day);
    return Semantics(
      label: 'Ngày $day${has ? ', có slot' : ''}',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onSelect(date),
        child: Container(
          height: 44,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? context.colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: context.text.label.copyWith(
                  color: selected
                      ? context.colors.onPrimary
                      : today
                          ? context.colors.primary
                          : context.colors.onSurface,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: has ? (selected ? context.colors.onPrimary : context.colors.primary) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
