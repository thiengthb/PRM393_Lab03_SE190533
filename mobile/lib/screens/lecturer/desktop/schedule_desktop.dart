import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';
import '../../../viewmodels/schedule_viewmodel.dart';

/// GV-002 Điểm danh on desktop: the week as a grid (slot 1-6 × Monday-Sunday). Arrow keys
/// change week. Clicking a slot that has started opens the session.
class ScheduleDesktop extends ConsumerWidget {
  const ScheduleDesktop({super.key});

  static const _starts = ['07:00', '09:30', '12:30', '15:00', '17:30', '20:00'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scheduleViewModelProvider);
    final vm = ref.read(scheduleViewModelProvider.notifier);
    final d = s.dataOrNull;
    return DeskShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => vm.shiftWeek(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => vm.shiftWeek(1),
      },
      child: DeskPage(
        title: d == null ? 'Điểm danh' : 'Tuần ${VnDate.weekRange(d.weekStart)}',
        subtitle: d?.term,
        actions: [
          AppButton(label: 'Tuần trước', icon: LucideIcons.chevronLeft, style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, onPressed: () => vm.shiftWeek(-1)),
          AppButton(label: 'Hôm nay', style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: vm.thisWeek),
          AppButton(label: 'Tuần sau', trailingArrow: true, style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, onPressed: () => vm.shiftWeek(1)),
        ],
        body: switch (s) {
          Loading() || Empty() => const SkeletonList(count: 6),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Ready(:final data) => !data.hasClasses
              ? EmptyState(
                  icon: LucideIcons.calendar,
                  message: 'Chưa có lịch',
                  detail: 'Hãy nhập danh sách lớp',
                  actionLabel: 'Nhập',
                  actionIcon: LucideIcons.fileUp,
                  onAction: () => context.push('/import'),
                )
              : _Grid(data: data),
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.data});
  final ScheduleData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final c = context.colors;
    final line = BorderSide(color: c.outlineVariant.withValues(alpha: 0.7), width: AppSize.border);
    final bySlot = <(int, int), List<Slot>>{};
    for (final s in d.weekSlots) {
      bySlot.putIfAbsent((s.start.weekday - 1, s.slotNo), () => []).add(s);
    }
    // Slots outside 1-6 (demo data puts "now" anywhere) go to the nearest row.
    int row(int no) => no.clamp(1, 6);
    final cells = <(int, int), List<Slot>>{};
    for (final e in bySlot.entries) {
      cells.putIfAbsent((e.key.$1, row(e.key.$2)), () => []).addAll(e.value);
    }
    return DeskCard(
      expand: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 40,
          decoration: BoxDecoration(border: Border(bottom: line)),
          child: Row(children: [
            const SizedBox(width: 72),
            for (final day in d.week)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
                  child: Text(
                    '${VnDate.dayLabel(day).split(',').first} ${VnDate.dm(day)}',
                    style: context.text.caption.copyWith(
                      color: VnDate.sameDay(day, d.now) ? c.primary : null,
                      fontWeight: VnDate.sameDay(day, d.now) ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: Column(children: [
            for (var no = 1; no <= 6; no++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: no < 6 ? Border(bottom: line) : null),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 72,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.s8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Slot $no', style: context.text.caption.copyWith(fontWeight: FontWeight.w600)),
                          Text(ScheduleDesktop._starts[no - 1], style: context.text.caption),
                        ]),
                      ),
                    ),
                    for (var day = 0; day < 7; day++)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(left: line),
                            color: VnDate.sameDay(d.week[day], d.now) ? c.primaryContainer.withValues(alpha: 0.25) : null,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Column(children: [
                            for (final s in cells[(day, no)] ?? const <Slot>[]) Expanded(child: _SlotTile(slot: s, now: d.now)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

}

class _SlotTile extends StatefulWidget {
  const _SlotTile({required this.slot, required this.now});
  final Slot slot;
  final DateTime now;

  @override
  State<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends State<_SlotTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.slot;
    final c = context.colors;
    final st = context.status;
    final phase = s.phaseAt(widget.now);
    final (Color bg, Color edge, String? tag, Color tagColor) = switch (phase) {
      SlotPhase.live => (c.primaryContainer, st.primarySoftEdge, 'Đang diễn ra', st.danger),
      SlotPhase.unclosed => (st.warningSoft, st.warningSoftEdge, 'Chưa chốt', st.warning),
      SlotPhase.closed => (c.surface, c.outlineVariant, '${s.presentCount}/${s.studentCount} có mặt', c.onSurfaceVariant),
      SlotPhase.upcoming => (c.surface, c.outlineVariant, null, c.onSurfaceVariant),
    };
    final open = phase != SlotPhase.upcoming;
    final tile = AnimatedContainer(
      duration: AppMotion.fast,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: _hover && open ? c.primary : edge, width: AppSize.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(s.classLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption.copyWith(color: st.fgStrong, fontWeight: FontWeight.w600)),
        Text('${s.room} · ${VnDate.hm(s.start)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
        if (tag != null) Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption.copyWith(color: tagColor, fontWeight: FontWeight.w500)),
      ]),
    );
    final label = '${s.classLabel}, ${VnDate.dayLabel(s.start)}, ${VnDate.range(s.start, s.end)}, phòng ${s.room}${tag == null ? '' : ', $tag'}';
    if (!open) return Semantics(label: label, child: ExcludeSemantics(child: tile));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label: label,
        onTap: () => context.push('/session/${s.id}'),
        child: ExcludeSemantics(child: GestureDetector(onTap: () => context.push('/session/${s.id}'), child: tile)),
      ),
    );
  }
}
