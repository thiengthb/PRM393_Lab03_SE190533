import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import '../../viewmodels/classes_viewmodels.dart';
import 'package:attendo_core/widgets/widgets.dart';
import 'desktop/classes_desktop.dart';

/// GV-003 Lớp.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isDesktop) return const ClassesDesktop();
    final s = ref.watch(classesViewModelProvider);
    final vm = ref.read(classesViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.top(title: 'Lớp', icon: LucideIcons.users),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Empty() => const SizedBox.shrink(),
        Ready(:final data) => ScreenBody(
            maxWidth: context.isWide ? AppLayout.page : 600,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TermDropdown(terms: data.terms, term: data.term, onSelect: vm.selectTerm),
              ),
              const SizedBox(height: AppSpace.group),
              for (final c in data.inReview) ...[
                ClassReviewCard(schoolClass: c, onResubmit: () => context.push('/import')),
                const SizedBox(height: AppSpace.s8),
              ],
              // .E (`302:4442`): kỳ hiện tại có nút Nhập; kỳ cũ chỉ báo trống.
              if (data.items.isEmpty && data.inReview.isNotEmpty)
                const SizedBox.shrink()
              else if (data.items.isEmpty)
                EmptyState(
                  icon: LucideIcons.calendarX,
                  message: data.term == data.currentTerm ? 'Chưa nhập lịch' : 'Kỳ này không có lớp',
                  actionLabel: data.term == data.currentTerm ? 'Nhập' : null,
                  actionIcon: LucideIcons.download,
                  onAction: () => context.push('/import'),
                  boxed: false,
                )
              else
                CardGrid(children: [
                  for (final it in data.items) _ClassRow(item: it, onTap: () => context.push('/class/${it.schoolClass.id}')),
                ]),
            ],
          ),
      },
    );
  }
}

/// Chọn kỳ v2 (`280:4844`): nút nền xám có mũi tên, mở danh sách kỳ.
class TermDropdown extends StatelessWidget {
  const TermDropdown({required this.terms, required this.term, required this.onSelect});
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
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        container: true,
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
                  Icon(LucideIcons.chevronDown, size: AppSize.icon20, color: st.fgStrong),
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
        const IconTile(icon: LucideIcons.users, size: 40),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.label, style: context.text.title.copyWith(fontSize: 15)),
            Text('${c.studentCount} sinh viên', style: context.text.bodySm),
          ]),
        ),
        if (item.attentionCount > 0) ...[
          Icon(LucideIcons.triangleAlert, size: 18, color: st.warning),
          const SizedBox(width: AppSpace.s4),
          Text('${item.attentionCount}', style: context.text.label.copyWith(color: st.warning)),
          const SizedBox(width: AppSpace.s8),
        ],
        Icon(LucideIcons.chevronRight, size: AppSize.icon20, color: context.colors.onSurfaceVariant),
      ]),
    );
  }
}

/// Đầu trang chi tiết lớp: môn, kỳ, số sinh viên và thanh tiến độ buổi đã học.
class _ClassHeader extends StatelessWidget {
  const _ClassHeader({required this.subject, required this.term, required this.students, required this.held, required this.total});
  final String subject;
  final String term;
  final int students;
  final int held;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QaCard(
      semanticsLabel: '$subject, $term, $students sinh viên, đã học $held trên $total buổi',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const IconTile(icon: LucideIcons.bookOpen, size: 44),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject, style: context.text.titleLg),
                Text('$term · $students sinh viên', style: context.text.bodySm),
              ]),
            ),
          ]),
          const SizedBox(height: AppSpace.s16),
          Row(children: [
            Expanded(child: Text('Buổi đã học', style: context.text.label)),
            RatioText(value: '$held', total: '$total'),
          ]),
          const SizedBox(height: AppSpace.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : held / total,
              minHeight: 6,
              backgroundColor: c.surfaceContainerHighest,
              color: c.primary,
            ),
          ),
        ]),
      ),
    );
  }
}

/// GV-103 Chi tiết lớp (+ Xuất PDF, D-L3-05).
class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isDesktop) return ClassDetailDesktop(classId: classId);
    final s = ref.watch(classDetailViewModelProvider(classId));
    final vm = ref.read(classDetailViewModelProvider(classId).notifier);
    ref.listen(classDetailViewModelProvider(classId).select((x) => x.export), (prev, next) {
      if (next is ExportDone && prev is! ExportDone) showExportSaved(context, next);
      if (next is ExportFailed && prev is! ExportFailed) AppToast.show(context, next.message, error: true);
    });
    final d = s.data.dataOrNull;
    final exporting = s.export is ExportRunning;
    return Scaffold(
      appBar: QaAppBar.nested(
        title: d?.schoolClass.code ?? 'Lớp',
        icon: LucideIcons.users,
        actions: [
          AppIconButton(
            icon: LucideIcons.download,
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
                  container: true,
                  label: '$step ${(progress * 100).round()}%',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$step · ${(progress * 100).round()}%', style: context.text.bodySm),
                    const SizedBox(height: AppSpace.s4),
                    LinearProgressIndicator(value: progress == 0 ? null : progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  ]),
                ),
                const SizedBox(height: AppSpace.s12),
              ],
              _ClassHeader(
                subject: data.schoolClass.subject,
                term: data.schoolClass.term,
                students: data.schoolClass.studentCount,
                held: data.held,
                total: data.schoolClass.totalSlots,
              ),
              const SizedBox(height: AppSpace.group),
              AppSegmented<ClassTab>(
                options: const [(ClassTab.students, 'Sinh viên'), (ClassTab.sessions, 'Buổi học')],
                value: s.tab,
                onChanged: vm.setTab,
              ),
              const SizedBox(height: AppSpace.s16),
              if (s.tab == ClassTab.students) ...[
                AppTextField(hint: 'Tìm tên hoặc MSSV', prefixIcon: LucideIcons.search, onChanged: vm.setQuery),
                const SizedBox(height: AppSpace.s12),
                if (s.visibleStudents.isEmpty) const EmptyState(message: 'Trống'),
                if (s.visibleStudents.isNotEmpty)
                  CardList(dividerIndent: 64, children: [
                    for (final a in s.visibleStudents)
                      AttentionRow(
                        item: a,
                        showClass: false,
                        onTap: () => context.push('/student/$classId/${a.student.code}'),
                      ),
                  ]),
              ] else ...[
                if (data.sessions.isEmpty) const EmptyState(message: 'Trống'),
                if (data.sessions.isNotEmpty)
                  CardList(children: [
                    for (final slot in data.sessions)
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
                  ]),
              ],
            ],
          ),
      },
    );
  }

}

/// Sheet after a PDF export: file name, size and (when uploaded) the Cloudinary link.
void showExportSaved(BuildContext context, ExportDone e) {
    final name = e.path.split(RegExp(r'[/\\]')).last;
    AppSheet.show<void>(
      context,
      title: e.url == null ? 'Đã lưu trên máy' : 'Đã tải lên Cloudinary',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$name · ${e.sizeKb} KB', style: ctx.text.bodySm),
          const SizedBox(height: AppSpace.s8),
          if (e.url != null) ...[
            SelectableText(e.url!, style: ctx.text.bodySm.copyWith(color: ctx.colors.primary), maxLines: 3),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Chép link',
              icon: LucideIcons.link,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.url!));
                Navigator.of(ctx).pop();
                AppToast.show(context, 'Đã chép link');
              },
            ),
          ],
        ],
      ),
    );
}
