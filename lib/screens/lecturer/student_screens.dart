import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/lecturer_viewmodels.dart';
import '../../widgets/widgets.dart';

// ---------------- GV-104 Chú ý ----------------

class AttentionScreen extends ConsumerWidget {
  const AttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(attentionViewModelProvider);
    final vm = ref.read(attentionViewModelProvider.notifier);
    final d = s.dataOrNull;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Chú ý', icon: Icons.warning_rounded),
      body: ScreenBody(children: [
        AppTextField(hint: 'Tìm tên hoặc MSSV', prefixIcon: Icons.search, onChanged: vm.setQuery),
        const SizedBox(height: AppSpace.s12),
        SizedBox(
          height: AppSize.buttonInCard,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            AppChip(label: 'Tất cả', selected: d?.filter == AttentionFilter.all && d?.classId == null, onTap: () => vm.setFilter(AttentionFilter.all)),
            const SizedBox(width: AppSpace.s8),
            AppChip(label: 'Vượt', selected: d?.filter == AttentionFilter.over, onTap: () => vm.setFilter(AttentionFilter.over)),
            const SizedBox(width: AppSpace.s8),
            AppChip(label: 'Sắp chạm', selected: d?.filter == AttentionFilter.near, onTap: () => vm.setFilter(AttentionFilter.near)),
            const SizedBox(width: AppSpace.s8),
            AppChip(
              label: d?.classChipLabel ?? 'Lớp',
              selected: d?.classId != null,
              onTap: () => _pickClass(context, d?.classes ?? const [], vm),
            ),
          ]),
        ),
        const SizedBox(height: AppSpace.group),
        switch (s) {
          Loading() || Empty() => const SkeletonList(),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Ready(:final data) when data.items.isEmpty => const EmptyState(message: 'Trống', icon: Icons.check_circle_outline),
          Ready(:final data) => Column(children: [
              for (final a in data.items) ...[
                AttentionRow(item: a, onTap: () => context.push('/student/${a.schoolClass.id}/${a.student.code}')),
                const SizedBox(height: AppSpace.s8),
              ],
            ]),
        },
      ]),
    );
  }

  void _pickClass(BuildContext context, List<SchoolClass> classes, AttentionViewModel vm) {
    AppSheet.show<void>(
      context,
      title: 'Lớp',
      builder: (ctx) => Wrap(spacing: AppSpace.s8, runSpacing: AppSpace.s8, children: [
        AppChip(label: 'Tất cả lớp', selected: false, onTap: () {
          vm.setClass(null);
          Navigator.of(ctx).pop();
        }),
        for (final c in classes)
          AppChip(label: c.label, selected: false, onTap: () {
            vm.setClass(c.id);
            Navigator.of(ctx).pop();
          }),
      ]),
    );
  }
}

// ---------------- GV-105 Yêu cầu sửa (+ GV-OV5) ----------------

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(requestsViewModelProvider);
    final vm = ref.read(requestsViewModelProvider.notifier);
    ref.listen(requestsViewModelProvider.select((x) => x.message), (prev, next) {
      if (next == null || next == prev) return;
      AppToast.show(context, next, onUndo: next == 'Đã duyệt' ? vm.undoApprove : null, error: !next.startsWith('Đã'));
      vm.messageShown();
    });
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Yêu cầu sửa'),
      body: switch (s.data) {
        Loading() => const ScreenBody(children: [SkeletonList(height: 140)]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Empty() => const ScreenBody(children: [EmptyState(message: 'Trống', icon: Icons.inbox_outlined)]),
        Ready(:final data) => ScreenBody(children: [
            for (final r in data) ...[
              QaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    InitialsAvatar(name: r.studentName),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(child: Text(r.studentName, style: context.text.body.copyWith(color: context.status.fgStrong))),
                    const StatusChip.absent(),
                  ]),
                  const SizedBox(height: AppSpace.s8),
                  Text('${r.subject} · ${VnDate.dayLabel(r.slotStart)} · Slot ${r.slotNo}', style: context.text.bodySm),
                  const SizedBox(height: AppSpace.s4),
                  Text('“${r.note.isEmpty ? r.reason : r.note}”', style: context.text.body),
                  const SizedBox(height: AppSpace.s12),
                  Row(children: [
                    Expanded(
                      child: AppButton(
                        label: 'Từ chối',
                        style: AppButtonStyle.outline,
                        size: AppButtonSize.medium,
                        onPressed: s.busyId != null ? null : () => _reject(context, r, vm),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: AppButton(
                        label: 'Duyệt',
                        icon: Icons.check,
                        size: AppButtonSize.medium,
                        loading: s.busyId == r.id,
                        onPressed: s.busyId != null ? null : () => vm.approve(r),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: AppSpace.s12),
            ],
          ]),
      },
    );
  }

  Future<void> _reject(BuildContext context, CorrectionRequest r, RequestsViewModel vm) async {
    final result = await AppSheet.show<(String, String)>(
      context,
      title: 'Từ chối yêu cầu',
      builder: (ctx) => _RejectForm(request: r),
    );
    if (result != null) await vm.reject(r, reason: result.$1, note: result.$2);
  }
}

class _RejectForm extends StatefulWidget {
  const _RejectForm({required this.request});
  final CorrectionRequest request;

  @override
  State<_RejectForm> createState() => _RejectFormState();
}

class _RejectFormState extends State<_RejectForm> {
  static const _reasons = ['Không có mặt', 'Quét sau giờ', 'Khác'];
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${r.studentName} · ${r.subject} · ${VnDate.dayLabel(r.slotStart)}', style: context.text.bodySm),
      const SizedBox(height: AppSpace.s16),
      Text('Lý do', style: context.text.label),
      const SizedBox(height: AppSpace.s8),
      Wrap(spacing: AppSpace.s8, runSpacing: AppSpace.s8, children: [
        for (final x in _reasons) AppChip(label: x, selected: _reason == x, onTap: () => setState(() => _reason = x)),
      ]),
      const SizedBox(height: AppSpace.s16),
      AppTextField(label: 'Ghi thêm (không bắt buộc)', controller: _note, maxLines: 3),
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Gửi từ chối',
        icon: Icons.send_outlined,
        style: AppButtonStyle.destructive,
        onPressed: _reason == null ? null : () => Navigator.of(context).pop((_reason!, _note.text)),
      ),
    ]);
  }
}

// ---------------- GV-201 Hồ sơ sinh viên (+ GV-OV3) ----------------

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, required this.classId, required this.code});
  final String classId;
  final String code;

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  bool _logged = false;

  StudentKey get _key => (classId: widget.classId, code: widget.code);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(studentProfileViewModelProvider(_key));
    final vm = ref.read(studentProfileViewModelProvider(_key).notifier);
    ref.listen(studentProfileViewModelProvider(_key).select((x) => x.message), (prev, next) {
      if (next == null || next == prev) return;
      AppToast.show(context, next, error: next != 'Đã gửi');
      vm.messageShown();
    });
    if (!_logged && s.data is Ready) {
      _logged = true;
      vm.logView();
    }
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Hồ sơ'),
      body: switch (s.data) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 1, height: 160), SkeletonList()]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? () => ref.invalidate(studentProfileViewModelProvider(_key)) : null),
        Ready(:final data) => _ProfileBody(data: data),
      },
      bottomNavigationBar: s.data.dataOrNull == null
          ? null
          : BottomBar(children: [
              AppButton(
                label: s.sentToday ? 'Đã nhắc' : 'Nhắc nhở',
                icon: s.sentToday ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
                loading: s.sending,
                onPressed: s.sentToday || s.sending ? null : () => _remind(context, vm, s.data.dataOrNull!),
              ),
            ]),
    );
  }

  Future<void> _remind(BuildContext context, StudentProfileViewModel vm, StudentProfileData d) async {
    final ctrl = TextEditingController(text: vm.draftMessage());
    final send = await AppSheet.show<bool>(
      context,
      title: 'Nhắc sinh viên',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(controller: ctrl, maxLines: 3),
        const SizedBox(height: AppSpace.s8),
        Row(children: [
          Icon(Icons.mail_outline, size: 16, color: ctx.colors.onSurfaceVariant),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: Text(d.email ?? 'Chưa có email', style: ctx.text.bodySm)),
        ]),
        const SizedBox(height: AppSpace.s16),
        AppButton(label: 'Gửi', icon: Icons.send_outlined, onPressed: () => Navigator.of(ctx).pop(true)),
      ]),
    );
    if (send == true) await vm.send(ctrl.text);
    ctrl.dispose();
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data});
  final StudentProfileData data;

  @override
  Widget build(BuildContext context) {
    final a = data.absence;
    return ScreenBody(children: [
      Row(children: [
        InitialsAvatar(name: a.student.name, size: 56),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.student.name, style: context.text.title),
            Text('${a.student.code} · ${a.schoolClass.subject} · ${a.schoolClass.code}', style: context.text.bodySm),
          ]),
        ),
      ]),
      const SizedBox(height: AppSpace.s16),
      QaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RatioText(value: '${a.absent}', total: '${a.limit}', color: absenceColor(context, a.level), style: context.text.display),
          Text('buổi vắng', style: context.text.bodySm),
          if (a.level == AbsenceLevel.over) ...[
            const SizedBox(height: AppSpace.s8),
            Row(children: [
              Icon(Icons.block_outlined, size: 16, color: context.status.danger),
              const SizedBox(width: AppSpace.s8),
              Text('Sinh viên đã bị cấm thi', style: context.text.label.copyWith(color: context.status.danger)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: AppSpace.group),
      Text('Buổi vắng', style: context.text.section),
      const SizedBox(height: AppSpace.s8),
      if (data.absentSessions.isEmpty) const EmptyState(message: 'Trống'),
      for (final r in data.absentSessions) ...[
        SessionRow(
          title: r.start == null ? '—' : VnDate.dayLabel(r.start!),
          subtitle: 'Slot ${r.slotNo} · ${r.room}',
        ),
        const SizedBox(height: AppSpace.s8),
      ],
    ]);
  }
}
