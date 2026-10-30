import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/import_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../widgets/widgets.dart';

/// GV-100 Nhập lớp: .D chọn file, .D1 xem trước, .L đang nhập, .X dòng lỗi, .S xong.
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(importViewModelProvider);
    final vm = ref.read(importViewModelProvider.notifier);
    ref.listen(importViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: !next.startsWith('Đã'));
        vm.messageShown();
      }
    });
    final p = s.preview;

    if (s.step == ImportStep.done && p != null) return _DoneView(classCount: p.classes.length, weekly: p.weeklySlotCount);

    final body = switch (s.step) {
      ImportStep.pick => <Widget>[
          QaCard(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(children: [
              IconTile(icon: Icons.upload_file_rounded, background: context.colors.primaryContainer, color: context.colors.primary),
              const SizedBox(height: AppSpace.s12),
              Text('File Excel hoặc CSV từ phòng đào tạo', style: context.text.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s16),
              AppButton(label: 'Chọn file', icon: Icons.folder_open_outlined, size: AppButtonSize.medium, expand: false, onPressed: vm.pick),
              const SizedBox(height: AppSpace.s8),
              Text('.xlsx hoặc .csv, tối đa 5 MB', style: context.text.bodySm),
            ]),
          ),
          const SizedBox(height: AppSpace.s8),
          Center(
            child: TextButton.icon(
              onPressed: vm.copyTemplate,
              icon: Icon(Icons.download_outlined, color: context.colors.primary, size: AppSize.icon20),
              label: Text('Tải file mẫu', style: context.text.label.copyWith(color: context.colors.primary)),
            ),
          ),
        ],
      ImportStep.errors => <Widget>[
          if (p != null) _FileRow(name: p.fileName),
          const SizedBox(height: AppSpace.s16),
          Row(children: [
            Icon(Icons.warning_rounded, color: context.status.danger, size: AppSize.icon20),
            const SizedBox(width: AppSpace.s8),
            Text('${p?.errors.length ?? 0} dòng lỗi, chưa nhập', style: context.text.section),
          ]),
          const SizedBox(height: AppSpace.s12),
          for (final e in p?.errors ?? const <ImportRowError>[]) ...[
            SessionRow(title: e.row > 0 ? 'Dòng ${e.row}' : 'Lớp', subtitle: e.message),
            const SizedBox(height: AppSpace.s8),
          ],
        ],
      _ => <Widget>[
          if (p != null) ...[
            _FileRow(name: p.fileName, detail: '${p.term} · ${p.classes.length} lớp · ${p.weeklySlotCount} slot mỗi tuần'),
            const SizedBox(height: AppSpace.s16),
            if (s.step == ImportStep.importing) ...[
              Text('Đã nhập ${s.done}/${s.total} lớp', style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              LinearProgressIndicator(value: s.total == 0 ? null : s.done / s.total, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              const SizedBox(height: AppSpace.s16),
            ],
            for (final c in p.classes) ...[
              SessionRow(title: c.label, subtitle: '${c.students.length} sinh viên'),
              const SizedBox(height: AppSpace.s8),
            ],
          ],
        ],
    };

    final bottom = switch (s.step) {
      ImportStep.errors => BottomBar(children: [
          AppButton(label: 'Bỏ qua', style: AppButtonStyle.outline, onPressed: vm.skipErrors),
          AppButton(label: 'Chọn file khác', onPressed: vm.pick),
        ]),
      ImportStep.preview => BottomBar(children: [AppButton(label: 'Nhập', icon: Icons.download_done_rounded, onPressed: vm.commit)]),
      ImportStep.importing => const BottomBar(children: [AppButton(label: 'Đang xử lý', loading: true, onPressed: null)]),
      _ => null,
    };

    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Nhập lớp', icon: Icons.upload_file_rounded),
      body: ScreenBody(children: body),
      bottomNavigationBar: bottom,
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.name, this.detail});
  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) => QaCard(
        child: Row(children: [
          const IconTile(icon: Icons.description_outlined, size: 40),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong), overflow: TextOverflow.ellipsis),
              if (detail != null) Text(detail!, style: context.text.bodySm),
            ]),
          ),
        ]),
      );
}

/// GV-100 .S: đã nhập + bật nhắc ngay.
class _DoneView extends ConsumerWidget {
  const _DoneView({required this.classCount, required this.weekly});
  final int classCount;
  final int weekly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountViewModelProvider);
    final vm = ref.read(accountViewModelProvider.notifier);
    final AppUser? u = acc.dataOrNull;
    return Scaffold(
      body: SafeArea(
        child: ScreenBody(children: [
          const SizedBox(height: AppSpace.s32),
          Center(child: IconTile(icon: Icons.check_rounded, background: context.status.successSoft, color: context.status.success)),
          const SizedBox(height: AppSpace.s16),
          Text('Đã nhập $classCount lớp', style: context.text.titleLg, textAlign: TextAlign.center),
          Text('$weekly slot tuần này', style: context.text.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.group),
          Text('Nhắc nhở', style: context.text.section),
          const SizedBox(height: AppSpace.s8),
          QaCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s4),
            child: Column(children: [
              _row(context, 'Trước slot', '10 phút', u?.reminderBeforeSlot ?? true, vm.setBeforeSlot),
              const Divider(),
              _row(context, 'Slot chưa chốt', 'Khi hết giờ', u?.reminderUnclosed ?? true, vm.setUnclosed),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(label: 'Tổng quan', trailingArrow: true, onPressed: () => context.go('/overview')),
      ]),
    );
  }

  Widget _row(BuildContext context, String t, String d, bool v, ValueChanged<bool> f) => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: context.text.body.copyWith(color: context.status.fgStrong)),
            Text(d, style: context.text.bodySm),
          ]),
        ),
        Semantics(label: t, toggled: v, child: Switch(value: v, onChanged: f)),
      ]);
}
