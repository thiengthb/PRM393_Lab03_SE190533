import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/classes_viewmodels.dart';
import '../../widgets/widgets.dart';

/// GV-003 Lớp.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(classesViewModelProvider);
    final vm = ref.read(classesViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.top(title: 'Lớp', icon: Icons.group_rounded),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Empty() => const SizedBox.shrink(),
        Ready(:final data) => ScreenBody(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _TermDropdown(terms: data.terms, term: data.term, onSelect: vm.selectTerm),
              ),
              const SizedBox(height: AppSpace.group),
              if (data.items.isEmpty)
                // .E (`302:4442`): kỳ hiện tại có nút Nhập; kỳ cũ chỉ báo trống.
                EmptyState(
                  icon: Icons.event_busy_outlined,
                  message: data.term == data.currentTerm ? 'Chưa nhập lịch' : 'Kỳ này không có lớp',
                  actionLabel: data.term == data.currentTerm ? 'Nhập' : null,
                  actionIcon: Icons.download_rounded,
                  onAction: () => context.push('/import'),
                  boxed: false,
                )
              else
                for (final it in data.items) ...[
                  _ClassRow(item: it, onTap: () => context.push('/class/${it.schoolClass.id}')),
                  const SizedBox(height: AppSpace.s12),
                ],
            ],
          ),
      },
    );
  }
}

/// Chọn kỳ v2 (`280:4844`): nút nền xám có mũi tên, mở danh sách kỳ.
class _TermDropdown extends StatelessWidget {
  const _TermDropdown({required this.terms, required this.term, required this.onSelect});
  final List<String> terms;
  final String term;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(context.colors.surface),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpace.s4)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
      ),
      menuChildren: [
        for (final t in terms)
          MenuItemButton(
            onPressed: () => onSelect(t),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(200, AppSize.touch)),
              backgroundColor: WidgetStatePropertyAll(t == term ? context.colors.primaryContainer : null),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))),
            ),
            child: Text(t, style: context.text.body.copyWith(color: st.fgStrong)),
          ),
      ],
      builder: (context, controller, _) => Semantics(
        button: true,
        label: 'Kỳ $term, bấm để đổi kỳ',
        excludeSemantics: true,
        child: Material(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(term, style: context.text.label.copyWith(color: st.fgStrong)),
                  const SizedBox(width: AppSpace.s4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: AppSize.icon20, color: st.fgStrong),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng lớp v2 (`278:5118`): ô icon xanh nhạt, tên lớp đậm, số sinh viên, số em vắng nhiều màu hổ phách.
class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.item, required this.onTap});
  final ClassItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = item.schoolClass;
    final st = context.status;
    return QaCard(
      onTap: onTap,
      semanticsLabel: '${c.label}, ${c.studentCount} sinh viên'
          '${item.attentionCount > 0 ? ', ${item.attentionCount} em vắng nhiều' : ''}',
      child: Row(children: [
        IconTile(
          icon: Icons.group_rounded,
          background: context.colors.primaryContainer,
          color: context.colors.primary,
          size: 40,
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.label, style: context.text.bodyStrong.copyWith(color: st.fgStrong)),
            Text('${c.studentCount} sinh viên', style: context.text.bodySm),
          ]),
        ),
        if (item.attentionCount > 0) ...[
          Icon(Icons.warning_rounded, size: 18, color: st.warning),
          const SizedBox(width: AppSpace.s4),
          Text('${item.attentionCount}', style: context.text.label.copyWith(color: st.warning)),
          const SizedBox(width: AppSpace.s8),
        ],
        Icon(Icons.chevron_right, color: st.fgStrong),
      ]),
    );
  }
}

/// GV-103 Chi tiết lớp (+ Xuất PDF, D-L3-05).
class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(classDetailViewModelProvider(classId));
    final vm = ref.read(classDetailViewModelProvider(classId).notifier);
    ref.listen(classDetailViewModelProvider(classId).select((x) => x.export), (prev, next) {
      if (next is ExportDone && prev is! ExportDone) _showSaved(context, next);
      if (next is ExportFailed && prev is! ExportFailed) AppToast.show(context, next.message, error: true);
    });
    final d = s.data.dataOrNull;
    final exporting = s.export is ExportRunning;
    return Scaffold(
      appBar: QaAppBar.nested(
        title: d?.schoolClass.code ?? 'Lớp',
        icon: Icons.group_rounded,
        actions: [
          AppIconButton(
            icon: Icons.download_rounded,
            tooltip: 'Xuất PDF',
            onPressed: d == null || exporting ? null : vm.exportPdf,
          ),
        ],
      ),
      body: switch (s.data) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
        Empty() => const SizedBox.shrink(),
        Ready(:final data) => ScreenBody(
            children: [
              if (s.export case ExportRunning(:final progress, :final step)) ...[
                Semantics(
                  liveRegion: true,
                  label: '$step ${(progress * 100).round()}%',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$step · ${(progress * 100).round()}%', style: context.text.bodySm),
                    const SizedBox(height: AppSpace.s4),
                    LinearProgressIndicator(value: progress == 0 ? null : progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  ]),
                ),
                const SizedBox(height: AppSpace.s12),
              ],
              Text('${data.schoolClass.subject} · ${data.schoolClass.term}', style: context.text.body),
              const SizedBox(height: AppSpace.s12),
              Row(children: [
                Expanded(child: StatTile(value: '${data.schoolClass.studentCount}', label: 'sinh viên', icon: Icons.group_outlined)),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: StatTile(
                    value: '${data.held}/${data.schoolClass.totalSlots}',
                    label: 'buổi đã học',
                    icon: Icons.menu_book_outlined,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpace.group),
              AppSegmented<ClassTab>(
                options: const [(ClassTab.students, 'Sinh viên'), (ClassTab.sessions, 'Buổi học')],
                value: s.tab,
                onChanged: vm.setTab,
              ),
              const SizedBox(height: AppSpace.s16),
              if (s.tab == ClassTab.students) ...[
                AppTextField(hint: 'Tìm tên hoặc MSSV', prefixIcon: Icons.search, onChanged: vm.setQuery),
                const SizedBox(height: AppSpace.s12),
                if (s.visibleStudents.isEmpty) const EmptyState(message: 'Trống'),
                for (final a in s.visibleStudents) ...[
                  AttentionRow(
                    item: a,
                    showClass: false,
                    onTap: () => context.push('/student/$classId/${a.student.code}'),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
              ] else ...[
                if (data.sessions.isEmpty) const EmptyState(message: 'Trống'),
                for (final slot in data.sessions) ...[
                  SessionRow(
                    kind: CardKind.sunken,
                    title: VnDate.dayLabel(slot.start),
                    subtitle: 'Slot ${slot.slotNo} · ${slot.room}',
                    // Buổi đã chốt mở thẳng .D2 để sửa (lối sửa buổi đã chốt, kế hoạch v2 câu 6).
                    onTap: () => context.push(slot.closed ? '/session/${slot.id}?edit=1' : '/session/${slot.id}'),
                    trailing: slot.closed
                        ? RatioText(value: '${slot.presentCount}', total: '${slot.studentCount}')
                        : const StatusBadge(StatusBadgeKind.unclosed),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
              ],
            ],
          ),
      },
    );
  }

  void _showSaved(BuildContext context, ExportDone e) {
    final name = e.path.split(RegExp(r'[/\\]')).last;
    AppToast.show(context, 'Đã lưu $name · ${e.sizeKb} KB');
  }
}
