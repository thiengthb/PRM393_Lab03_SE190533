import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import '../../viewmodels/lecturer_viewmodels.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

// ---------------- GV-104 Chú ý ----------------

class AttentionScreen extends ConsumerWidget {
  const AttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(attentionViewModelProvider);
    final vm = ref.read(attentionViewModelProvider.notifier);
    final d = s.dataOrNull;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Vắng nhiều', icon: LucideIcons.triangleAlert),
      body: ScreenBody(children: [
        AppTextField(hint: 'Tìm tên hoặc MSSV', prefixIcon: LucideIcons.search, onChanged: vm.setQuery),
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
          Ready(:final data) when data.items.isEmpty => const EmptyState(message: 'Trống', icon: LucideIcons.circleCheck),
          Ready(:final data) => CardList(dividerIndent: 64, children: [
              for (final a in data.items)
                AttentionRow(item: a, onTap: () => context.push('/student/${a.schoolClass.id}/${a.student.code}')),
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
      appBar: const QaAppBar.nested(title: 'Yêu cầu sửa', icon: LucideIcons.messageCircle),
      body: switch (s.data) {
        Loading() => const ScreenBody(children: [SkeletonList(height: 140)]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        // .E (`289:3724`): căn giữa màn, không viền.
        Empty() => const Center(child: EmptyState(message: 'Trống', icon: LucideIcons.inbox, boxed: false)),
        Ready(:final data) => ScreenBody(children: [
            for (final r in data) ...[
              QaCard(
                kind: CardKind.raised,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    InitialsAvatar(name: r.studentName),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(child: Text(r.studentName, style: context.text.body.copyWith(color: context.status.fgStrong))),
                    const StatusChip.absent(),
                  ]),
                  const SizedBox(height: AppSpace.s12),
                  // .D v2 (`289:3337`): dòng buổi có icon lịch, lời sinh viên trong ô nền xám.
                  Row(children: [
                    Icon(LucideIcons.calendar, size: 16, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Text('${r.subject} · ${VnDate.dayLabel(r.slotStart)} · Slot ${r.slotNo}', style: context.text.bodySm),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.s12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.s12),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '“${r.note.isEmpty ? r.reason : r.note}”',
                      style: context.text.body.copyWith(color: context.status.fgStrong),
                    ),
                  ),
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
      AppTextField(hint: 'Ghi thêm (không bắt buộc)', controller: _note, maxLines: 3),
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Gửi từ chối',
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
      appBar: const QaAppBar.nested(title: 'Hồ sơ', icon: LucideIcons.user),
      body: switch (s.data) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 1, height: 160), SkeletonList()]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? () => ref.invalidate(studentProfileViewModelProvider(_key)) : null),
        Ready(:final data) => _ProfileBody(data: data),
      },
      // Em đã fail thì không còn gì để nhắc (.D1 `278:5335` không có nút).
      bottomNavigationBar: s.data.dataOrNull == null || s.data.dataOrNull!.absence.level == AbsenceLevel.over
          ? null
          : BottomBar(children: [
              AppButton(
                label: s.sentToday ? 'Đã nhắc · ${VnDate.dm(DateTime.now())}' : 'Nhắc nhở',
                icon: LucideIcons.bell,
                loading: s.sending,
                onPressed: s.sentToday || s.sending ? null : () => _remind(context, vm, s.data.dataOrNull!),
              ),
            ]),
    );
  }

  /// GV-OV3 v2 (`289:3922`): lời nhắc soạn sẵn nói rõ còn được vắng bao nhiêu, dòng email có dấu tick.
  Future<void> _remind(BuildContext context, StudentProfileViewModel vm, StudentProfileData d) async {
    final message = await AppSheet.show<String>(
      context,
      title: 'Nhắc sinh viên',
      builder: (_) => _ReminderSheet(studentKey: _key, email: d.email),
    );
    if (message != null) await vm.send(message);
  }
}

/// GV-OV3: ô soạn sửa được; “Gợi ý AI” điền kết quả có cấu trúc, gắn nhãn AI (đề Final mục 8).
class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({required this.studentKey, required this.email});
  final StudentKey studentKey;
  final String? email;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    // Mở lại sheet: giữ gợi ý AI đang có để nhãn “AI gợi ý” đúng với nội dung (CR-09).
    final p = studentProfileViewModelProvider(widget.studentKey);
    _ctrl = TextEditingController(text: ref.read(p).aiDraft?.fullText ?? ref.read(p.notifier).draftMessage());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = studentProfileViewModelProvider(widget.studentKey);
    final s = ref.watch(p);
    ref.listen(p.select((x) => x.aiDraft), (prev, next) {
      if (next != null && next != prev) _ctrl.text = next.fullText;
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(controller: _ctrl, maxLines: 3),
      if (s.aiDraft != null) ...[
        const SizedBox(height: AppSpace.s8),
        Semantics(
          label: 'Nội dung do AI gợi ý, hãy kiểm tra trước khi gửi',
          child: Row(children: [
            Icon(LucideIcons.sparkles, size: 16, color: context.colors.primary),
            const SizedBox(width: AppSpace.s8),
            Expanded(child: Text('AI gợi ý · kiểm tra trước khi gửi', style: context.text.bodySm)),
          ]),
        ),
      ],
      const SizedBox(height: AppSpace.s8),
      Row(children: [
        IconTile(icon: LucideIcons.mail, size: 40, background: context.colors.surfaceContainerHighest, color: context.status.fgStrong),
        const SizedBox(width: AppSpace.s12),
        Expanded(child: Text(widget.email ?? 'Chưa có email', style: context.text.body.copyWith(color: context.status.fgStrong))),
        if (widget.email != null) Icon(LucideIcons.check, size: AppSize.icon20, color: context.status.fgStrong),
      ]),
      const SizedBox(height: AppSpace.s16),
      if (s.aiEnabled) ...[
        AppButton(
          label: 'Gợi ý AI',
          icon: LucideIcons.sparkles,
          style: AppButtonStyle.outline,
          size: AppButtonSize.medium,
          loading: s.aiBusy,
          onPressed: s.aiBusy ? null : ref.read(p.notifier).requestAiDraft,
        ),
        const SizedBox(height: AppSpace.s8),
      ],
      AppButton(label: 'Gửi', icon: LucideIcons.send, onPressed: () => Navigator.of(context).pop(_ctrl.text)),
    ]);
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
        const SizedBox(width: AppSpace.s16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpace.s8, children: [
              Text(a.student.name, style: context.text.title.copyWith(color: context.status.fgStrong)),
              if (a.level == AbsenceLevel.over) const FailedChip(),
            ]),
            Text('${a.student.code} · ${a.schoolClass.subject} · ${a.schoolClass.code}', style: context.text.bodySm),
          ]),
        ),
      ]),
      const SizedBox(height: AppSpace.s16),
      AbsenceMeter(absent: a.absent, limit: a.limit, color: absenceColor(context, a.level)),
      const SizedBox(height: AppSpace.group),
      Text('Buổi vắng', style: context.text.section),
      const SizedBox(height: AppSpace.s12),
      if (data.absentSessions.isEmpty) const EmptyState(message: 'Chưa vắng buổi nào', icon: LucideIcons.circleCheck),
      if (data.absentSessions.isNotEmpty)
        CardList(children: [
          for (final r in data.absentSessions)
            SessionRow(
              kind: CardKind.sunken,
              title: r.start == null ? '—' : VnDate.dayLabel(r.start!),
              subtitle: 'Slot ${r.slotNo} · ${r.room}',
            ),
        ]),
    ]);
  }
}
