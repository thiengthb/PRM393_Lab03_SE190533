import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/subjects_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Quản lý danh mục môn: app đọc danh mục này để kiểm file nhập lớp.
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(subjectsViewModelProvider);
    final vm = ref.read(subjectsViewModelProvider.notifier);
    ref.listen(subjectsViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: ref.read(subjectsViewModelProvider).isError);
        vm.messageShown();
      }
    });
    return AdminPage(
      title: 'Môn học',
      icon: LucideIcons.bookOpen,
      children: [
        Wrap(spacing: AppSpace.s12, runSpacing: AppSpace.s12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: AdminSize.filterField,
            child: AppTextField(hint: 'Tìm mã hoặc tên', prefixIcon: LucideIcons.search, onChanged: vm.setQuery),
          ),
          SizedBox(
            width: AdminSize.filterField,
            child: AppSegmented<bool>(
              options: const [(false, 'Đang dùng'), (true, 'Đã lưu trữ')],
              value: s.archived,
              onChanged: vm.setArchived,
            ),
          ),
          AppButton(
            label: 'Thêm môn',
            icon: LucideIcons.plus,
            size: AppButtonSize.medium,
            expand: false,
            onPressed: () => _edit(context, vm, null),
          ),
        ]),
        const SizedBox(height: AppSpace.group),
        ...switch (s.items) {
          Loading() => const <Widget>[SkeletonList()],
          Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
          Empty() => <Widget>[
              EmptyState(
                message: s.query.isEmpty ? 'Chưa có môn' : 'Không tìm thấy',
                icon: LucideIcons.bookOpen,
                actionLabel: s.query.isEmpty && !s.archived ? 'Thêm môn' : null,
                actionIcon: LucideIcons.plus,
                onAction: () => _edit(context, vm, null),
              ),
            ],
          Ready(:final data) => <Widget>[
              for (final x in data) ...[
                QaCard(
                  semanticsLabel: '${x.code} ${x.name}',
                  child: Row(children: [
                    SizedBox(width: AdminSize.codeColumn, child: Text(x.code, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong))),
                    Expanded(child: Text(x.name, style: context.text.body)),
                    if (x.isActive)
                      AppIconButton(icon: LucideIcons.pencil, tooltip: 'Sửa ${x.code}', onPressed: () => _edit(context, vm, x)),
                    AppIconButton(
                      icon: x.isActive ? LucideIcons.archive : LucideIcons.archiveRestore,
                      tooltip: x.isActive ? 'Lưu trữ ${x.code}' : 'Khôi phục ${x.code}',
                      onPressed: () => vm.setSubjectArchived(x, x.isActive),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
        },
      ],
    );
  }

  Future<void> _edit(BuildContext context, SubjectsViewModel vm, Subject? existing) {
    vm.clearForm();
    return showAdminForm<void>(
      context,
      title: existing == null ? 'Thêm môn' : 'Sửa ${existing.code}',
      builder: (_) => _SubjectForm(existing: existing),
    );
  }
}

class _SubjectForm extends ConsumerStatefulWidget {
  const _SubjectForm({this.existing});
  final Subject? existing;

  @override
  ConsumerState<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends ConsumerState<_SubjectForm> {
  late final _code = TextEditingController(text: widget.existing?.code);
  late final _name = TextEditingController(text: widget.existing?.name);

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(subjectsViewModelProvider.notifier)
        .save(_code.text, _name.text, isNew: widget.existing == null);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(subjectsViewModelProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(label: 'Mã môn', hint: 'PRM393', controller: _code, enabled: widget.existing == null, errorText: s.fieldErrors['code']),
      const SizedBox(height: AppSpace.s16),
      AppTextField(label: 'Tên môn', controller: _name, errorText: s.fieldErrors['name'], onSubmitted: (_) => _save()),
      const SizedBox(height: AppSpace.s16),
      Row(children: [
        Expanded(child: AppButton(label: 'Hủy', style: AppButtonStyle.outline, size: AppButtonSize.medium, onPressed: () => Navigator.of(context).pop())),
        const SizedBox(width: AppSpace.s12),
        Expanded(child: AppButton(label: 'Lưu', size: AppButtonSize.medium, loading: s.saving, onPressed: s.saving ? null : _save)),
      ]),
    ]);
  }
}
