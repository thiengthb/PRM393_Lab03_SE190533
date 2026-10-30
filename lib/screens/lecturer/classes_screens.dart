import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              SizedBox(
                height: AppSize.buttonInCard,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.terms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s8),
                  itemBuilder: (_, i) => AppChip(
                    label: data.terms[i],
                    selected: data.terms[i] == data.term,
                    onTap: () => vm.selectTerm(data.terms[i]),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.group),
              if (data.items.isEmpty)
                EmptyState(
                  icon: Icons.group_outlined,
                  message: 'Chưa có lớp',
                  actionLabel: data.term == data.currentTerm ? 'Nhập' : null,
                  actionIcon: Icons.upload_file_outlined,
                  onAction: () => context.push('/import'),
                )
              else
                for (final it in data.items) ...[
                  QaCard(
                    onTap: () => context.push('/class/${it.schoolClass.id}'),
                    semanticsLabel: '${it.schoolClass.label}, ${it.schoolClass.studentCount} sinh viên'
                        '${it.attentionCount > 0 ? ', ${it.attentionCount} em cần chú ý' : ''}',
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.schoolClass.label, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
                              Text('${it.schoolClass.studentCount} sinh viên', style: context.text.bodySm),
                            ],
                          ),
                        ),
                        if (it.attentionCount > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            height: 28,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
                            decoration: BoxDecoration(
                              color: context.status.warningSoft,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text('${it.attentionCount}', style: context.text.label.copyWith(color: context.status.warning)),
                          ),
                        Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
            ],
          ),
      },
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
      if (next is ExportDone && prev is! ExportDone) _showUploaded(context, next);
      if (next is ExportFailed && prev is! ExportFailed) AppToast.show(context, next.message, error: true);
    });
    final d = s.data.dataOrNull;
    final exporting = s.export is ExportRunning;
    return Scaffold(
      appBar: QaAppBar.nested(
        title: d?.schoolClass.code ?? 'Lớp',
        actions: [
          AppIconButton(
            icon: Icons.picture_as_pdf_outlined,
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
                Expanded(child: StatTile(value: '${data.schoolClass.studentCount}', label: 'sinh viên')),
                const SizedBox(width: AppSpace.s8),
                Expanded(child: StatTile(value: '${data.held}/${data.schoolClass.totalSlots}', label: 'buổi đã học')),
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
                  const SizedBox(height: AppSpace.s8),
                ],
              ] else ...[
                if (data.sessions.isEmpty) const EmptyState(message: 'Trống'),
                for (final slot in data.sessions) ...[
                  SessionRow(
                    title: VnDate.dayLabel(slot.start),
                    subtitle: 'Slot ${slot.slotNo} · ${slot.room}',
                    onTap: () => context.push('/slot/${slot.id}'),
                    trailing: slot.closed
                        ? RatioText(value: '${slot.presentCount}', total: '${slot.studentCount}')
                        : const StatusBadge(StatusBadgeKind.unclosed),
                  ),
                  const SizedBox(height: AppSpace.s8),
                ],
              ],
            ],
          ),
      },
    );
  }

  void _showUploaded(BuildContext context, ExportDone e) {
    AppSheet.show<void>(
      context,
      title: 'Đã tải lên',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${e.path} · ${e.sizeKb} KB', style: ctx.text.bodySm),
          const SizedBox(height: AppSpace.s8),
          SelectableText(e.url, style: ctx.text.bodySm.copyWith(color: ctx.colors.primary), maxLines: 3),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Chép link',
            icon: Icons.link,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: e.url));
              Navigator.of(ctx).pop();
              AppToast.show(context, 'Đã chép link');
            },
          ),
        ],
      ),
    );
  }
}
