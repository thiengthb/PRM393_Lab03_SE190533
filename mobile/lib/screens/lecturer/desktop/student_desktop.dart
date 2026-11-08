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
import '../../../viewmodels/lecturer_viewmodels.dart';
import '../student_screens.dart';

Widget _absenceChip(BuildContext context, StudentAbsence a) {
  final st = context.status;
  final c = context.colors;
  final (Color fg, Color bg, String suffix) = switch (a.level) {
    AbsenceLevel.over => (st.danger, st.dangerSoft, ' · đã fail'),
    AbsenceLevel.near => (st.warning, st.warningSoft, ' · sắp chạm'),
    AbsenceLevel.ok => (c.onSurfaceVariant, c.surfaceContainerHighest, ''),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text('${a.absent}/${a.limit}$suffix', style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
  );
}

/// GV-104 Vắng nhiều on desktop: filters in the card header, students as a table.
class AttentionDesktop extends ConsumerWidget {
  const AttentionDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(attentionViewModelProvider);
    final vm = ref.read(attentionViewModelProvider.notifier);
    final d = s.dataOrNull;
    return DeskPage(
      title: 'Vắng nhiều',
      subtitle: 'Sinh viên đã quá hoặc sắp chạm ngưỡng vắng kỳ này',
      onBack: () => context.canPop() ? context.pop() : context.go('/overview'),
      actions: [DeskSearchField(hint: 'Tìm tên hoặc MSSV', onChanged: vm.setQuery, width: 240)],
      body: DeskCard(
        expand: true,
        header: Row(children: [
          AppSegmented<AttentionFilter>(
            options: const [(AttentionFilter.all, 'Tất cả'), (AttentionFilter.over, 'Vượt'), (AttentionFilter.near, 'Sắp chạm')],
            value: d?.filter ?? AttentionFilter.all,
            onChanged: vm.setFilter,
          ),
          const SizedBox(width: AppSpace.s12),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(onPressed: () => vm.setClass(null), child: const Text('Tất cả lớp')),
              for (final c in d?.classes ?? const <SchoolClass>[]) MenuItemButton(onPressed: () => vm.setClass(c.id), child: Text(c.label)),
            ],
            builder: (context, controller, _) => AppButton(
              label: d?.classChipLabel ?? 'Lớp',
              icon: LucideIcons.listFilter,
              style: AppButtonStyle.outline,
              size: AppButtonSize.small,
              expand: false,
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ]),
        child: switch (s) {
          Loading() || Empty() => const Padding(padding: EdgeInsets.all(AppSpace.s16), child: SkeletonList(count: 6, height: 40)),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Ready(:final data) => DeskTable<StudentAbsence>(
              rows: data.items,
              emptyMessage: 'Trống',
              emptyIcon: LucideIcons.circleCheck,
              onTap: (a) => context.push('/student/${a.schoolClass.id}/${a.student.code}'),
              rowLabel: (a) => '${a.student.name}, ${a.schoolClass.label}, vắng ${a.absent} trên ${a.limit}',
              columns: [
                DeskColumn(
                  label: 'Sinh viên',
                  flex: 3,
                  sortBy: (a) => a.student.name,
                  cell: (_, a) => Row(children: [
                    InitialsAvatar(name: a.student.name, size: 28),
                    const SizedBox(width: AppSpace.s8),
                    Flexible(child: Text(a.student.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ]),
                ),
                DeskColumn(label: 'MSSV', width: 120, sortBy: (a) => a.student.code, cell: (_, a) => Text(a.student.code)),
                DeskColumn(label: 'Lớp', flex: 2, sortBy: (a) => a.schoolClass.label, cell: (_, a) => Text(a.schoolClass.label)),
                DeskColumn(label: 'Vắng', width: 160, sortBy: (a) => a.absent - a.limit, cell: (ctx, a) => _absenceChip(ctx, a)),
                DeskColumn(label: '', width: 40, cell: (ctx, _) => Icon(LucideIcons.chevronRight, size: 16, color: ctx.colors.onSurfaceVariant)),
              ],
            ),
        },
      ),
    );
  }
}

/// GV-105 Yêu cầu sửa on desktop: requests as a table, the selected one in a side panel.
class RequestsDesktop extends ConsumerStatefulWidget {
  const RequestsDesktop({super.key});

  @override
  ConsumerState<RequestsDesktop> createState() => _RequestsDesktopState();
}

class _RequestsDesktopState extends ConsumerState<RequestsDesktop> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(requestsViewModelProvider);
    final vm = ref.read(requestsViewModelProvider.notifier);
    ref.listen(requestsViewModelProvider.select((x) => x.message), (prev, next) {
      if (next == null || next == prev) return;
      AppToast.show(context, next, onUndo: next == 'Đã duyệt' ? vm.undoApprove : null, error: !next.startsWith('Đã'));
      vm.messageShown();
    });
    final rows = s.data.dataOrNull ?? const <CorrectionRequest>[];
    final sel = rows.where((r) => r.id == _selected).firstOrNull;
    final busy = s.busyId != null;
    String note(CorrectionRequest r) => r.note.isEmpty ? r.reason : r.note;
    return DeskPage(
      title: 'Yêu cầu sửa',
      subtitle: rows.isEmpty ? null : '${rows.length} yêu cầu đang chờ',
      side: sel == null
          ? null
          : DeskSidePanel(
              title: sel.studentName,
              subtitle: sel.studentCode,
              onClose: () => setState(() => _selected = null),
              footer: Row(children: [
                Expanded(child: AppButton(label: 'Từ chối', style: AppButtonStyle.outline, size: AppButtonSize.medium, onPressed: busy ? null : () => rejectRequest(context, sel, vm))),
                const SizedBox(width: AppSpace.s8),
                Expanded(child: AppButton(label: 'Duyệt', icon: LucideIcons.check, size: AppButtonSize.medium, loading: s.busyId == sel.id, onPressed: busy ? null : () => vm.approve(sel))),
              ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DeskFacts([
                  ('Môn', sel.subject),
                  ('Buổi', '${VnDate.dayLabel(sel.slotStart)} · Slot ${sel.slotNo}'),
                  ('Đang ghi', 'Vắng'),
                ]),
                const SizedBox(height: AppSpace.s12),
                Text('Sinh viên viết', style: context.text.section),
                const SizedBox(height: AppSpace.s4),
                Container(
                  padding: const EdgeInsets.all(AppSpace.s12),
                  decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text('“${note(sel)}”', style: context.text.body.copyWith(color: context.status.fgStrong)),
                ),
              ]),
            ),
      body: DeskCard(
        expand: true,
        child: switch (s.data) {
          Loading() => const Padding(padding: EdgeInsets.all(AppSpace.s16), child: SkeletonList(count: 4, height: 40)),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Empty() => const Center(child: EmptyState(message: 'Trống', icon: LucideIcons.inbox, boxed: false)),
          Ready(:final data) => DeskTable<CorrectionRequest>(
              rows: data,
              rowHeight: 52,
              isSelected: (r) => r.id == _selected,
              onTap: (r) => setState(() => _selected = r.id == _selected ? null : r.id),
              rowLabel: (r) => '${r.studentName}, ${r.subject}, ${VnDate.dayLabel(r.slotStart)}',
              columns: [
                DeskColumn(
                  label: 'Sinh viên',
                  flex: 3,
                  sortBy: (r) => r.studentName,
                  cell: (ctx, r) => Row(children: [
                    InitialsAvatar(name: r.studentName, size: 28),
                    const SizedBox(width: AppSpace.s8),
                    Flexible(
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.studentName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(r.studentCode, style: ctx.text.caption),
                      ]),
                    ),
                  ]),
                ),
                DeskColumn(label: 'Buổi', flex: 3, sortBy: (r) => r.slotStart, cell: (_, r) => Text('${r.subject} · ${VnDate.dm(r.slotStart)} · Slot ${r.slotNo}')),
                DeskColumn(label: 'Lời nhắn', flex: 4, cell: (ctx, r) => Text(note(r), maxLines: 1, overflow: TextOverflow.ellipsis, style: ctx.text.caption)),
                DeskColumn(
                  label: '',
                  width: 190,
                  alignEnd: true,
                  cell: (_, r) => Row(mainAxisSize: MainAxisSize.min, children: [
                    AppButton(label: 'Từ chối', style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, onPressed: busy ? null : () => rejectRequest(context, r, vm)),
                    const SizedBox(width: AppSpace.s4),
                    AppButton(label: 'Duyệt', size: AppButtonSize.small, expand: false, loading: s.busyId == r.id, onPressed: busy ? null : () => vm.approve(r)),
                  ]),
                ),
              ],
            ),
        },
      ),
    );
  }
}
