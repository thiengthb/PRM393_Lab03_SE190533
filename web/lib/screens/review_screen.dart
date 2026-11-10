import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';

import '../viewmodels/review_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Hàng đợi duyệt (direction A chosen 09/11): table of classes the lecturers submitted, a
/// detail panel on the right with the student list. Approving updates the app in real time.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String _query = '';
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reviewViewModelProvider);
    final vm = ref.read(reviewViewModelProvider.notifier);
    ref.listen(reviewViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: ref.read(reviewViewModelProvider).isError);
        vm.messageShown();
      }
    });
    final rows = s.visible(_query);
    final selected = rows.where((c) => c.id == _selected).firstOrNull;
    final pendingCount = s.tab == ClassStatus.pending ? (s.items.dataOrNull?.length ?? 0) : null;
    return DeskPage(
      title: 'Duyệt lớp',
      subtitle: pendingCount == null ? null : '$pendingCount lớp chờ duyệt',
      actions: [DeskSearchField(hint: 'Tìm lớp, môn, giảng viên', onChanged: (q) => setState(() => _query = q), width: 280)],
      side: selected == null ? null : _Detail(schoolClass: selected, state: s, onClose: () => setState(() => _selected = null)),
      body: DeskCard(
        expand: true,
        header: Row(children: [
          SizedBox(
            width: AdminSize.segmentedWide,
            child: AppSegmented<ClassStatus>(
              options: const [(ClassStatus.pending, 'Chờ duyệt'), (ClassStatus.approved, 'Đã duyệt'), (ClassStatus.rejected, 'Từ chối')],
              value: s.tab,
              onChanged: (t) {
                setState(() => _selected = null);
                vm.setTab(t);
              },
            ),
          ),
        ]),
        child: switch (s.items) {
          Loading() => const Padding(padding: EdgeInsets.all(AppSpace.s16), child: SkeletonList(count: 5, height: 40)),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          _ => DeskTable<SchoolClass>(
              rows: rows,
              emptyMessage: _query.isNotEmpty ? 'Không thấy lớp nào' : (s.tab == ClassStatus.pending ? 'Đã xử lý hết' : 'Trống'),
              emptyIcon: LucideIcons.circleCheck,
              isSelected: (c) => c.id == _selected,
              onTap: (c) => setState(() => _selected = c.id == _selected ? null : c.id),
              rowLabel: (c) => '${c.label}, ${c.lecturerName}, ${c.studentCount} sinh viên',
              columns: [
                DeskColumn(
                  label: 'Lớp',
                  flex: 2,
                  sortBy: (c) => c.label,
                  cell: (ctx, c) => Row(children: [
                    Flexible(child: Text(c.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (s.subjectUnknown(c) && c.status == ClassStatus.pending) ...[
                      const SizedBox(width: 6),
                      Tooltip(message: 'Môn ${c.subject} chưa có trong danh mục', child: Icon(LucideIcons.triangleAlert, size: 14, color: ctx.status.warning)),
                    ],
                  ]),
                ),
                DeskColumn(label: 'Giảng viên', flex: 2, sortBy: (c) => c.lecturerName, cell: (_, c) => Text(c.lecturerName.isEmpty ? 'Chưa rõ' : c.lecturerName)),
                DeskColumn(label: 'Kỳ', width: 110, cell: (_, c) => Text(c.term)),
                DeskColumn(label: 'Sĩ số', width: 80, sortBy: (c) => c.studentCount, cell: (_, c) => Text('${c.studentCount}')),
                DeskColumn(
                  label: s.tab == ClassStatus.pending ? 'Gửi lúc' : 'Xử lý lúc',
                  width: 120,
                  sortBy: (c) => (s.tab == ClassStatus.pending ? c.submittedAt : c.reviewedAt) ?? DateTime(0),
                  cell: (ctx, c) {
                    final t = s.tab == ClassStatus.pending ? c.submittedAt : c.reviewedAt;
                    return Text(t == null ? '–' : '${VnDate.dm(t)} ${VnDate.hm(t)}', style: ctx.text.caption);
                  },
                ),
                if (s.tab == ClassStatus.pending)
                  DeskColumn(
                    label: '',
                    width: 200,
                    alignEnd: true,
                    cell: (ctx, c) => _RowActions(schoolClass: c, busy: s.busyId == c.id),
                  )
                else
                  DeskColumn(label: 'Trạng thái', width: 200, cell: (ctx, c) => _StatusChip(schoolClass: c)),
              ],
            ),
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.schoolClass});
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final (String label, Color fg, Color bg) = switch (schoolClass.status) {
      ClassStatus.pending => ('Chờ duyệt', st.warning, st.warningSoft),
      ClassStatus.approved => ('Đã duyệt', st.success, st.successSoft),
      ClassStatus.rejected => ('Từ chối', st.danger, st.dangerSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.schoolClass, required this.busy});
  final SchoolClass schoolClass;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(reviewViewModelProvider.notifier);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AppButton(label: 'Từ chối', style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, onPressed: busy ? null : () => rejectClass(context, vm, schoolClass)),
      const SizedBox(width: AppSpace.s4),
      AppButton(label: 'Duyệt', icon: LucideIcons.check, size: AppButtonSize.small, expand: false, loading: busy, onPressed: busy ? null : () => vm.approve(schoolClass)),
    ]);
  }
}

Future<void> rejectClass(BuildContext context, ReviewViewModel vm, SchoolClass c) => showAdminForm<void>(
      context,
      title: 'Từ chối ${c.label}',
      builder: (_) => _RejectForm(schoolClass: c, onSubmit: (r) => vm.reject(c, r)),
    );

class _Detail extends ConsumerWidget {
  const _Detail({required this.schoolClass, required this.state, required this.onClose});
  final SchoolClass schoolClass;
  final ReviewState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = schoolClass;
    final vm = ref.read(reviewViewModelProvider.notifier);
    final busy = state.busyId == c.id;
    final st = context.status;
    return DeskSidePanel(
      title: c.label,
      subtitle: c.term,
      onClose: onClose,
      footer: c.status != ClassStatus.pending
          ? null
          : Row(children: [
              Expanded(child: AppButton(label: 'Từ chối', icon: LucideIcons.x, style: AppButtonStyle.destructive, size: AppButtonSize.medium, onPressed: busy ? null : () => rejectClass(context, vm, c))),
              const SizedBox(width: AppSpace.s8),
              Expanded(child: AppButton(label: 'Duyệt lớp này', icon: LucideIcons.check, size: AppButtonSize.medium, loading: busy, onPressed: busy ? null : () => vm.approve(c))),
            ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _StatusChipAligned(schoolClass: c),
        const SizedBox(height: AppSpace.s12),
        DeskFacts([
          ('Giảng viên', c.lecturerName.isEmpty ? 'Chưa rõ' : c.lecturerName),
          ('Môn', c.subject),
          ('Sĩ số', '${c.studentCount} sinh viên'),
          ('Số buổi', '${c.totalSlots}'),
          if (c.submittedAt != null) ('Gửi lúc', '${VnDate.dayLabel(c.submittedAt!)} ${VnDate.hm(c.submittedAt!)}'),
          if (c.reviewedAt != null) ('Xử lý lúc', '${VnDate.dayLabel(c.reviewedAt!)} ${VnDate.hm(c.reviewedAt!)}'),
          if ((c.rejectReason ?? '').isNotEmpty) ('Lý do', c.rejectReason!),
        ]),
        if (state.subjectUnknown(c)) ...[
          const SizedBox(height: AppSpace.s12),
          Row(children: [
            Icon(LucideIcons.triangleAlert, size: 16, color: st.warning),
            const SizedBox(width: AppSpace.s8),
            Expanded(child: Text('Môn ${c.subject} chưa có trong danh mục', style: context.text.bodySm.copyWith(color: st.warning))),
          ]),
        ],
        const SizedBox(height: AppSpace.s16),
        Text('Danh sách sinh viên', style: context.text.section),
        const SizedBox(height: AppSpace.s8),
        _RosterList(classId: c.id),
      ]),
    );
  }
}

class _StatusChipAligned extends StatelessWidget {
  const _StatusChipAligned({required this.schoolClass});
  final SchoolClass schoolClass;
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft, child: _StatusChip(schoolClass: schoolClass));
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(classStudentsProvider(classId));
    return v.when(
      loading: () => const SkeletonList(count: 3, height: 32),
      error: (_, _) => ErrorState(message: 'Không tải được danh sách', onRetry: () => ref.invalidate(classStudentsProvider(classId))),
      data: (l) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outlineVariant, width: AppSize.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: DeskTable<Student>(
          rows: l,
          shrinkWrap: true,
          rowHeight: 36,
          emptyMessage: 'Trống',
          columns: [
            DeskColumn(label: 'MSSV', width: AdminSize.codeColumn, cell: (_, st) => Text(st.code), sortBy: (st) => st.code),
            DeskColumn(label: 'Họ tên', cell: (_, st) => Text(st.name, overflow: TextOverflow.ellipsis), sortBy: (st) => st.name),
          ],
        ),
      ),
    );
  }
}

class _RejectForm extends StatefulWidget {
  const _RejectForm({required this.schoolClass, required this.onSubmit});
  final SchoolClass schoolClass;
  final Future<bool> Function(String reason) onSubmit;

  @override
  State<_RejectForm> createState() => _RejectFormState();
}

class _RejectFormState extends State<_RejectForm> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.onSubmit(_ctrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = 'Nhập lý do, tối đa 300 ký tự');
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(label: 'Lý do', controller: _ctrl, maxLines: 3, errorText: _error),
        const SizedBox(height: AppSpace.s16),
        Row(children: [
          const Spacer(),
          AppButton(label: 'Hủy', style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: AppSpace.s8),
          AppButton(label: 'Từ chối', style: AppButtonStyle.destructive, size: AppButtonSize.small, expand: false, onPressed: _submit),
        ]),
      ]);
}
