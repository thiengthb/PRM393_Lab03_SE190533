import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/review_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Hàng đợi duyệt: lớp giảng viên gửi từ app, duyệt xong app đổi theo thời gian thực.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(reviewViewModelProvider);
    final vm = ref.read(reviewViewModelProvider.notifier);
    ref.listen(reviewViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: ref.read(reviewViewModelProvider).isError);
        vm.messageShown();
      }
    });
    return AdminPage(
      title: 'Duyệt lớp',
      icon: Icons.fact_check_rounded,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: AdminSize.segmentedWide,
            child: AppSegmented<ClassStatus>(
              options: const [(ClassStatus.pending, 'Chờ duyệt'), (ClassStatus.approved, 'Đã duyệt'), (ClassStatus.rejected, 'Từ chối')],
              value: s.tab,
              onChanged: vm.setTab,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.group),
        ...switch (s.items) {
          Loading() => const <Widget>[SkeletonList(height: 120)],
          Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
          Empty() => <Widget>[EmptyState(message: s.tab == ClassStatus.pending ? 'Đã xử lý hết' : 'Trống', icon: Icons.check_circle_outline)],
          Ready(:final data) => <Widget>[
              for (final c in data) ...[
                _ClassRow(schoolClass: c, state: s),
                const SizedBox(height: AppSpace.s12),
              ],
            ],
        },
      ],
    );
  }
}

class _ClassRow extends ConsumerWidget {
  const _ClassRow({required this.schoolClass, required this.state});
  final SchoolClass schoolClass;
  final ReviewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = schoolClass;
    final vm = ref.read(reviewViewModelProvider.notifier);
    final busy = state.busyId == c.id;
    final unknown = state.subjectUnknown(c);
    return QaCard(
      tone: unknown && c.status == ClassStatus.pending ? CardTone.warning : CardTone.normal,
      semanticsLabel: '${c.label}, ${c.lecturerName}, ${c.studentCount} sinh viên',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(c.label, style: context.text.title),
        const SizedBox(height: AppSpace.s4),
        Text(
          '${c.term} · ${c.lecturerName.isEmpty ? 'Chưa rõ giảng viên' : c.lecturerName} · ${c.studentCount} sinh viên · ${c.totalSlots} buổi'
          '${c.submittedAt == null ? '' : ' · gửi ${VnDate.dm(c.submittedAt!)}'}',
          style: context.text.bodySm,
        ),
        if (unknown) ...[
          const SizedBox(height: AppSpace.s8),
          Row(children: [
            Icon(Icons.warning_rounded, size: 16, color: context.status.warning),
            const SizedBox(width: AppSpace.s8),
            Expanded(child: Text('Môn ${c.subject} chưa có trong danh mục', style: context.text.bodySm.copyWith(color: context.status.warning))),
          ]),
        ],
        if (c.status == ClassStatus.rejected && (c.rejectReason ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpace.s8),
          Text('Lý do: ${c.rejectReason}', style: context.text.body),
        ],
        const SizedBox(height: AppSpace.s12),
        Wrap(spacing: AppSpace.s8, runSpacing: AppSpace.s8, alignment: WrapAlignment.end, children: [
          AppButton(
            label: 'Danh sách',
            icon: Icons.group_outlined,
            style: AppButtonStyle.ghost,
            size: AppButtonSize.medium,
            expand: false,
            onPressed: () => _roster(context, c),
          ),
          if (c.status == ClassStatus.pending) ...[
            AppButton(
              label: 'Từ chối',
              style: AppButtonStyle.outline,
              size: AppButtonSize.medium,
              expand: false,
              onPressed: busy ? null : () => _reject(context, vm, c),
            ),
            AppButton(
              label: 'Duyệt',
              icon: Icons.check,
              size: AppButtonSize.medium,
              expand: false,
              loading: busy,
              onPressed: busy ? null : () => vm.approve(c),
            ),
          ],
        ]),
      ]),
    );
  }

  Future<void> _roster(BuildContext context, SchoolClass c) => showAdminForm<void>(
        context,
        title: c.label,
        builder: (_) => _RosterList(classId: c.id),
      );

  Future<void> _reject(BuildContext context, ReviewViewModel vm, SchoolClass c) => showAdminForm<void>(
        context,
        title: 'Từ chối ${c.label}',
        builder: (_) => _RejectForm(schoolClass: c, onSubmit: (r) => vm.reject(c, r)),
      );
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(classStudentsProvider(classId));
    return v.when(
      loading: () => const SkeletonList(count: 3, height: 40),
      error: (_, _) => ErrorState(message: 'Không tải được danh sách', onRetry: () => ref.invalidate(classStudentsProvider(classId))),
      data: (l) => l.isEmpty
          ? const EmptyState(message: 'Trống')
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(shrinkWrap: true, children: [
                for (final st in l)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
                    child: Row(children: [
                      SizedBox(width: AdminSize.rateValue, child: Text(st.code, style: context.text.label)),
                      Expanded(child: Text(st.name, style: context.text.body)),
                    ]),
                  ),
              ]),
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
          Expanded(
            child: AppButton(label: 'Hủy', style: AppButtonStyle.outline, size: AppButtonSize.medium, onPressed: () => Navigator.of(context).pop()),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: AppButton(label: 'Từ chối', style: AppButtonStyle.destructive, size: AppButtonSize.medium, onPressed: _submit),
          ),
        ]),
      ]);
}
