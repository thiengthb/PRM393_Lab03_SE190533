import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';
import '../../../viewmodels/classes_viewmodels.dart';
import '../classes_screens.dart';

/// GV-003 Lớp on desktop: class list on the left, the selected class (GV-103) on the right,
/// so switching classes never leaves the page.
class ClassesDesktop extends ConsumerStatefulWidget {
  const ClassesDesktop({super.key});

  @override
  ConsumerState<ClassesDesktop> createState() => _ClassesDesktopState();
}

class _ClassesDesktopState extends ConsumerState<ClassesDesktop> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(classesViewModelProvider);
    final vm = ref.read(classesViewModelProvider.notifier);
    final d = s.dataOrNull;
    final items = d?.items ?? const <ClassItem>[];
    final selected = items.any((i) => i.schoolClass.id == _selected) ? _selected : (items.isEmpty ? null : items.first.schoolClass.id);
    return DeskPage(
      title: 'Lớp',
      subtitle: d == null ? null : '${d.term} · ${items.length} lớp',
      actions: [
        if (d != null) TermDropdown(terms: d.terms, term: d.term, onSelect: vm.selectTerm),
        AppButton(label: 'Nhập lớp', icon: LucideIcons.fileUp, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: () => context.push('/import')),
      ],
      body: switch (s) {
        Loading() || Empty() => const SkeletonList(count: 6),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Ready(:final data) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final c in data.inReview) ...[
              ClassReviewCard(schoolClass: c, onResubmit: () => context.push('/import')),
              const SizedBox(height: AppSpace.s12),
            ],
            if (data.items.isEmpty)
              EmptyState(
                icon: LucideIcons.calendarX,
                message: data.term == data.currentTerm ? 'Chưa nhập lịch' : 'Kỳ này không có lớp',
                actionLabel: data.term == data.currentTerm ? 'Nhập' : null,
                actionIcon: LucideIcons.fileUp,
                onAction: () => context.push('/import'),
              )
            else
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 300,
                    child: DeskCard(
                      title: 'Lớp kỳ ${data.term}',
                      count: data.items.length,
                      expand: true,
                      child: ListView(children: [
                        for (final it in data.items)
                          _ClassListRow(item: it, selected: it.schoolClass.id == selected, onTap: () => setState(() => _selected = it.schoolClass.id)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s16),
                  Expanded(child: selected == null ? const SizedBox.shrink() : ClassDetailPane(key: ValueKey(selected), classId: selected)),
                ]),
              ),
          ]),
      },
    );
  }
}

class _ClassListRow extends StatelessWidget {
  const _ClassListRow({required this.item, required this.selected, required this.onTap});
  final ClassItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = item.schoolClass;
    final st = context.status;
    return Container(
      color: selected ? context.colors.primaryContainer : null,
      child: DeskListItem(
        icon: LucideIcons.users,
        iconColor: selected ? context.colors.primary : null,
        iconBackground: selected ? context.colors.surface : null,
        title: '${c.subject} · ${c.code}',
        subtitle: '${c.studentCount} sinh viên',
        trailing: item.attentionCount == 0
            ? null
            : Tooltip(
                message: '${item.attentionCount} em vắng nhiều',
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.triangleAlert, size: 14, color: st.warning),
                  const SizedBox(width: 2),
                  Text('${item.attentionCount}', style: context.text.caption.copyWith(color: st.warning, fontWeight: FontWeight.w600)),
                ]),
              ),
        onTap: onTap,
      ),
    );
  }
}

/// GV-103 Chi tiết lớp body for desktop: summary card, then students or sessions as a table.
/// Used in the right pane of [ClassesDesktop] and as the body of `/class/:id`.
class ClassDetailPane extends ConsumerWidget {
  const ClassDetailPane({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(classDetailViewModelProvider(classId));
    final vm = ref.read(classDetailViewModelProvider(classId).notifier);
    ref.listen(classDetailViewModelProvider(classId).select((x) => x.export), (prev, next) {
      if (next is ExportDone && prev is! ExportDone) showExportSaved(context, next);
      if (next is ExportFailed && prev is! ExportFailed) AppToast.show(context, next.message, error: true);
    });
    final st = context.status;
    return switch (s.data) {
      Loading() || Empty() => const SkeletonList(count: 6),
      Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
      Ready(:final data) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DeskCard(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${data.schoolClass.subject} · ${data.schoolClass.code}', style: context.text.titleLg),
                    Text('${data.schoolClass.term} · ngưỡng vắng ${data.limit} buổi', style: context.text.bodySm),
                  ]),
                ),
                _Fact(label: 'Sĩ số', value: '${data.schoolClass.studentCount}'),
                _Fact(label: 'Đã học', value: '${data.held}/${data.schoolClass.totalSlots}'),
                _Fact(label: 'Vắng nhiều', value: '${data.students.where((a) => a.level != AbsenceLevel.ok).length}', color: st.warning),
                const SizedBox(width: AppSpace.s16),
                AppButton(
                  label: 'Xuất PDF',
                  icon: LucideIcons.download,
                  style: AppButtonStyle.outline,
                  size: AppButtonSize.small,
                  expand: false,
                  onPressed: s.export is ExportRunning ? null : vm.exportPdf,
                ),
              ]),
              if (s.export case ExportRunning(:final progress, :final step)) ...[
                const SizedBox(height: AppSpace.s12),
                Semantics(
                  liveRegion: true,
                  label: '$step ${(progress * 100).round()}%',
                  child: Row(children: [
                    Text('$step · ${(progress * 100).round()}%', style: context.text.caption),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(child: LinearProgressIndicator(value: progress == 0 ? null : progress, minHeight: 4, borderRadius: BorderRadius.circular(2))),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: AppSpace.s16),
          Expanded(
            child: DeskCard(
              expand: true,
              header: Row(children: [
                AppSegmented<ClassTab>(
                  options: [(ClassTab.students, 'Sinh viên ${data.students.length}'), (ClassTab.sessions, 'Buổi học ${data.sessions.length}')],
                  value: s.tab,
                  onChanged: vm.setTab,
                ),
                const Spacer(),
                if (s.tab == ClassTab.students) DeskSearchField(hint: 'Tìm tên hoặc MSSV', onChanged: vm.setQuery, width: 220),
              ]),
              child: s.tab == ClassTab.students
                  ? DeskTable<StudentAbsence>(
                      rows: s.visibleStudents,
                      emptyMessage: 'Không thấy sinh viên',
                      onTap: (a) => context.push('/student/$classId/${a.student.code}'),
                      rowLabel: (a) => '${a.student.name}, ${a.student.code}, vắng ${a.absent} trên ${a.limit}',
                      columns: [
                        DeskColumn(label: 'MSSV', width: 120, cell: (_, a) => Text(a.student.code), sortBy: (a) => a.student.code),
                        DeskColumn(label: 'Họ tên', flex: 3, cell: (_, a) => Text(a.student.name, style: const TextStyle(fontWeight: FontWeight.w500)), sortBy: (a) => a.student.name),
                        DeskColumn(label: 'Email', flex: 2, cell: (_, a) => Text(a.student.email ?? '–', style: context.text.caption, overflow: TextOverflow.ellipsis)),
                        DeskColumn(label: 'Vắng', width: 110, cell: (c, a) => _AbsenceChip(a: a), sortBy: (a) => a.absent),
                        DeskColumn(label: '', width: 40, cell: (c, _) => Icon(LucideIcons.chevronRight, size: 16, color: c.colors.onSurfaceVariant)),
                      ],
                    )
                  : DeskTable<Slot>(
                      rows: data.sessions,
                      emptyMessage: 'Chưa có buổi nào',
                      onTap: (slot) => context.push(slot.closed ? '/session/${slot.id}?edit=1' : '/session/${slot.id}'),
                      rowLabel: (slot) => '${VnDate.dayLabel(slot.start)}, slot ${slot.slotNo}, ${slot.closed ? '${slot.presentCount} trên ${slot.studentCount} có mặt' : 'chưa chốt'}',
                      columns: [
                        DeskColumn(label: 'Ngày', flex: 2, cell: (_, slot) => Text(VnDate.dayLabel(slot.start)), sortBy: (slot) => slot.start),
                        DeskColumn(label: 'Slot', width: 80, cell: (_, slot) => Text('${slot.slotNo}')),
                        DeskColumn(label: 'Giờ', width: 130, cell: (_, slot) => Text(VnDate.range(slot.start, slot.end), style: context.text.caption)),
                        DeskColumn(label: 'Phòng', width: 90, cell: (_, slot) => Text(slot.room)),
                        DeskColumn(
                          label: 'Có mặt',
                          width: 120,
                          cell: (c, slot) => slot.closed
                              ? Text('${slot.presentCount} / ${slot.studentCount}', style: const TextStyle(fontWeight: FontWeight.w600))
                              : const StatusBadge(StatusBadgeKind.unclosed),
                          sortBy: (slot) => slot.closed ? slot.presentCount : -1,
                        ),
                        DeskColumn(label: '', width: 70, cell: (c, slot) => Text(slot.closed ? 'Sửa' : 'Chốt', style: c.text.caption.copyWith(color: c.colors.primary, fontWeight: FontWeight.w600))),
                      ],
                    ),
            ),
          ),
        ]),
    };
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpace.s24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: context.text.caption),
          Text(value, style: context.text.title.copyWith(color: color ?? context.status.fgStrong)),
        ]),
      );
}

class _AbsenceChip extends StatelessWidget {
  const _AbsenceChip({required this.a});
  final StudentAbsence a;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final c = context.colors;
    final (Color fg, Color bg) = switch (a.level) {
      AbsenceLevel.over => (st.danger, st.dangerSoft),
      AbsenceLevel.near => (st.warning, st.warningSoft),
      AbsenceLevel.ok => (c.onSurfaceVariant, c.surfaceContainerHighest),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text('${a.absent}/${a.limit}${a.level == AbsenceLevel.over ? ' · fail' : ''}', style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// `/class/:id` on desktop (opened from a notification or a link).
class ClassDetailDesktop extends ConsumerWidget {
  const ClassDetailDesktop({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(classDetailViewModelProvider(classId)).data.dataOrNull;
    return DeskPage(
      title: d == null ? 'Lớp' : '${d.schoolClass.subject} · ${d.schoolClass.code}',
      onBack: () => context.canPop() ? context.pop() : context.go('/classes'),
      body: ClassDetailPane(classId: classId),
    );
  }
}
