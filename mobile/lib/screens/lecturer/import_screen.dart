import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/import_models.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import '../../viewmodels/account_viewmodels.dart';
import 'package:attendo_core/widgets/widgets.dart';

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
      // .D (`303:4571`): khung nét đứt thấp, bấm cả khung để chọn file.
      ImportStep.pick => <Widget>[
          Text('File Excel hoặc CSV từ phòng đào tạo', style: context.text.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.s12),
          Semantics(
            button: true,
            label: 'Chọn file, .xlsx hoặc .csv, tối đa 5 MB',
            onTap: vm.pick,
            container: true,
            excludeSemantics: true,
            child: InkWell(
              onTap: vm.pick,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CustomPaint(
                painter: _DashedBorder(color: context.colors.onSurfaceVariant),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s32, horizontal: AppSpace.s16),
                  child: Column(children: [
                    Icon(LucideIcons.fileText, size: 32, color: context.status.fgStrong),
                    const SizedBox(height: AppSpace.s12),
                    Text('Chọn file', style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
                    const SizedBox(height: AppSpace.s4),
                    Text('.xlsx hoặc .csv, tối đa 5 MB', style: context.text.bodySm),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Center(
            child: TextButton.icon(
              onPressed: vm.copyTemplate,
              icon: Icon(LucideIcons.download, color: context.colors.primary, size: AppSize.icon20),
              label: Text('Tải file mẫu', style: context.text.label.copyWith(color: context.colors.primary)),
            ),
          ),
        ],
      // .X (`298:4371`): dải đỏ, danh sách dòng lỗi trong một thẻ chìm.
      ImportStep.errors => <Widget>[
          if (p != null) _FileRow(name: p.fileName),
          const SizedBox(height: AppSpace.s12),
          Container(
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(color: context.status.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              Icon(LucideIcons.circleX, color: context.status.danger, size: AppSize.icon20),
              const SizedBox(width: AppSpace.s8),
              Text('${p?.errors.length ?? 0} dòng lỗi, chưa nhập', style: context.text.body.copyWith(color: context.status.danger)),
            ]),
          ),
          const SizedBox(height: AppSpace.s12),
          QaCard(
            kind: CardKind.sunken,
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, e) in (p?.errors ?? const <ImportRowError>[]).indexed) ...[
                if (i > 0) Divider(height: 1, color: context.colors.outlineVariant),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.s12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.row > 0 ? 'Dòng ${e.row}' : 'Lớp', style: context.text.body.copyWith(color: context.status.fgStrong)),
                    Text(e.message, style: context.text.bodySm),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      // .D1 (`298:4232`) và .L: chọn lớp cần nhập.
      _ => <Widget>[
          if (p != null) ...[
            _FileRow(name: p.fileName),
            const SizedBox(height: AppSpace.s12),
            Text('${p.term} · ${p.classes.length} lớp · ${p.weeklySlotCount} slot mỗi tuần', style: context.text.section),
            const SizedBox(height: AppSpace.s12),
            if (s.step == ImportStep.importing) ...[
              Text('Đã nhập ${s.done}/${s.total} lớp', style: context.text.bodySm),
              const SizedBox(height: AppSpace.s8),
              LinearProgressIndicator(value: s.total == 0 ? null : s.done / s.total, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              const SizedBox(height: AppSpace.s12),
            ],
            for (final c in p.classes) ...[
              QaCard(
                kind: CardKind.raised,
                onTap: s.step == ImportStep.importing ? null : () => vm.toggleClass(c.label),
                semanticsLabel: '${c.label}, ${c.students.length} sinh viên, ${s.unchecked.contains(c.label) ? 'không nhập' : 'sẽ nhập'}',
                child: Row(children: [
                  Checkbox(
                    value: !s.unchecked.contains(c.label),
                    onChanged: s.step == ImportStep.importing ? null : (_) => vm.toggleClass(c.label),
                  ),
                  const SizedBox(width: AppSpace.s4),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.label, style: context.text.body.copyWith(color: context.status.fgStrong)),
                      Text('${c.students.length} sinh viên', style: context.text.bodySm),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpace.s12),
            ],
          ],
        ],
    };

    final errCount = p?.errors.length ?? 0;
    final bottom = switch (s.step) {
      ImportStep.pick => const BottomBar(children: [AppButton(label: 'Nhập', onPressed: null)]),
      ImportStep.errors => BottomBar(children: [
          AppButton(label: 'Bỏ $errCount dòng lỗi', style: AppButtonStyle.outline, onPressed: vm.skipErrors),
          AppButton(label: 'Chọn file khác', onPressed: vm.pick),
        ]),
      ImportStep.preview => BottomBar(children: [
          AppButton(label: 'Nhập', onPressed: s.checkedCount == 0 ? null : vm.commit),
        ]),
      ImportStep.importing => const BottomBar(children: [AppButton(label: 'Đang nhập', loading: true, onPressed: null)]),
      _ => null,
    };

    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Nhập lớp', icon: LucideIcons.download),
      body: ScreenBody(children: body),
      bottomNavigationBar: bottom,
    );
  }
}

/// Viền nét đứt quanh khung chọn file.
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.md));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Dòng tên file: icon nhỏ và tên, không viền (`298:4232`).
class _FileRow extends StatelessWidget {
  const _FileRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(LucideIcons.fileText, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpace.s8),
        Expanded(child: Text(name, style: context.text.bodySm, overflow: TextOverflow.ellipsis)),
      ]);
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
          Center(child: IconTile(icon: LucideIcons.check, background: context.status.successSoft, color: context.status.success)),
          const SizedBox(height: AppSpace.s16),
          Text('Đã gửi $classCount lớp', style: context.text.titleLg, textAlign: TextAlign.center),
          Text('Chờ giáo vụ duyệt · $weekly slot mỗi tuần', style: context.text.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.group),
          Text('Nhắc nhở', style: context.text.section),
          const SizedBox(height: AppSpace.s8),
          QaCard(
            kind: CardKind.raised,
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
        AppSwitch(value: v, onChanged: f, semanticLabel: t),
      ]);
}
