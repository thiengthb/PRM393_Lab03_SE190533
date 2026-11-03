import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../widgets/widgets.dart';

/// Thẻ thông tin slot dùng ở GV-101 và GV-102 .S (Figma GV-102 .S v2 `265:3807`):
/// đầu thẻ nền primary-soft (giờ, lớp, dấu đã chốt), dưới là ba hàng ngày, phòng, sĩ số.
class _SlotInfo extends StatelessWidget {
  const _SlotInfo({required this.slot});
  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QaCard(
      kind: CardKind.raised,
      padding: EdgeInsets.zero,
      semanticsLabel: '${VnDate.range(slot.start, slot.end)} ${slot.classLabel}${slot.closed ? ', đã chốt' : ''}, '
          '${VnDate.dayLabel(slot.start)}, ${slot.room}, ${slot.studentCount} sinh viên',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - AppSize.border)),
            ),
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(VnDate.range(slot.start, slot.end), style: context.text.titleLg)),
                if (slot.closed) Icon(Icons.check_circle_rounded, size: AppSize.icon20, color: context.status.success),
              ]),
              const SizedBox(height: AppSpace.s4),
              Text(slot.classLabel, style: context.text.body.copyWith(color: c.onSurfaceVariant)),
            ]),
          ),
          _line(context, Icons.calendar_today_outlined, VnDate.dayLabel(slot.start)),
          const Divider(),
          _line(context, Icons.location_on_rounded, slot.room),
          const Divider(),
          _line(context, Icons.group_rounded, '${slot.studentCount} sinh viên'),
        ]),
      ),
    );
  }

  Widget _line(BuildContext context, IconData i, String t) => SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
          child: Row(children: [
            IconTile(icon: i, size: 40, background: context.colors.surfaceContainerHighest, color: context.colors.onSurface),
            const SizedBox(width: AppSpace.s12),
            Expanded(child: Text(t, style: context.text.body.copyWith(color: context.status.fgStrong))),
          ]),
        ),
      );
}

Widget _counts(BuildContext context, {int? present, int? absent}) => Row(children: [
      Expanded(child: StatTile(value: present?.toString(), label: 'có mặt')),
      const SizedBox(width: AppSpace.s8),
      Expanded(
        child: StatTile(
          value: absent?.toString(),
          label: 'vắng',
          color: (absent ?? 0) > 0 ? context.status.danger : null,
        ),
      ),
    ]);

// ---------------- GV-102 Phiên điểm danh ----------------

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.slotId, this.edit = false});
  final String slotId;
  final bool edit;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// Hàng “Có mặt (n)” đang mở hay gập: chỉ là trạng thái hiển thị của màn.
  bool _presentOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(sessionViewModelProvider(widget.slotId).notifier).edit());
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.slotId;
    final s = ref.watch(sessionViewModelProvider(id));
    final vm = ref.read(sessionViewModelProvider(id).notifier);
    ref.listen(sessionViewModelProvider(id).select((x) => x.dataOrNull?.step), (prev, next) {
      if (next == SessionStep.closed && prev == SessionStep.closing) {
        AppToast.show(context, 'Đã chốt', onUndo: vm.undo);
      }
    });
    ref.listen(sessionViewModelProvider(id).select((x) => x.dataOrNull?.timedOut ?? false), (prev, next) {
      if (next && prev != true) AppToast.show(context, 'Hết giờ, đã đóng mã');
    });

    final d = s.dataOrNull;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Điểm danh', icon: Icons.qr_code_2),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 1, height: 260), SkeletonList()]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
        Ready(:final data) => data.step == SessionStep.closed
            ? _ClosedBody(data: data)
            : _LiveBody(
                data: data,
                vm: vm,
                presentOpen: _presentOpen,
                onTogglePresent: () => setState(() => _presentOpen = !_presentOpen),
              ),
      },
      bottomNavigationBar: d == null
          ? null
          : BottomBar(children: [
              switch (d.step) {
                SessionStep.open => AppButton(label: 'Đóng mã', icon: Icons.lock_outline_rounded, onPressed: vm.closeQr),
                SessionStep.review || SessionStep.offline => AppButton(label: 'Chốt', icon: Icons.check, onPressed: vm.confirmClose),
                SessionStep.closing => const AppButton(label: 'Đang chốt', loading: true, onPressed: null),
                SessionStep.closed => AppButton(label: 'Xong', onPressed: () => context.go('/overview')),
              },
            ]),
    );
  }
}

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.data, required this.vm, required this.presentOpen, required this.onTogglePresent});
  final SessionData data;
  final SessionViewModel vm;
  final bool presentOpen;
  final VoidCallback onTogglePresent;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final total = d.roster.length;
    final open = d.step == SessionStep.open;
    final st = context.status;
    return ScreenBody(children: [
      // .X: dải thay cho hộp thoại OV2; dữ liệu đã nằm trong bộ nhớ đệm của Firestore.
      if (d.step == SessionStep.offline) ...[
        OfflineBanner(title: 'Chưa gửi được', detail: 'Đã lưu trên máy', onRetry: vm.retrySync),
        const SizedBox(height: AppSpace.s24),
      ],
      QaCard(
        kind: CardKind.raised,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '${d.presentCount} trên $total đã có mặt',
                child: ExcludeSemantics(child: _Ratio(present: d.presentCount, total: total)),
              ),
            ),
            if (open)
              Text('Còn ${VnDate.countdown(d.remaining)}', style: context.text.label.copyWith(color: context.colors.onSurfaceVariant))
            else if (d.step != SessionStep.closing)
              AppButton(
                label: 'Mở lại mã',
                icon: Icons.qr_code_2,
                style: AppButtonStyle.ghost,
                size: AppButtonSize.small,
                expand: false,
                onPressed: vm.reopen,
              ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : d.presentCount / total,
              minHeight: 10,
              backgroundColor: context.colors.outlineVariant,
              color: open ? st.success : context.colors.onSurfaceVariant,
            ),
          ),
        ]),
      ),
      if (open && d.qrText != null) ...[
        const SizedBox(height: AppSpace.s16),
        QaCard(
          kind: CardKind.raised,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24, vertical: AppSpace.s16),
          child: Column(children: [
            Semantics(
              label: 'Mã QR điểm danh',
              child: QrImageView(
                data: d.qrText!,
                size: 176,
                padding: EdgeInsets.zero,
                backgroundColor: context.colors.surface,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: st.fgStrong),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: st.fgStrong),
              ),
            ),
            if (d.code != null) ...[
              const SizedBox(height: AppSpace.s12),
              Semantics(
                label: 'Mã số ${d.code!.split('').join(' ')}',
                child: ExcludeSemantics(
                  child: Text(
                    _spaced(d.code!),
                    style: context.text.display.copyWith(color: st.fgStrong, fontSize: 24, letterSpacing: 1),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.s8),
            Semantics(
              label: 'Mã mới sau ${d.rotateIn} giây',
              child: ExcludeSemantics(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sync_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Đổi mã ${d.rotateIn}s', style: context.text.bodySm),
                ]),
              ),
            ),
          ]),
        ),
      ],
      if (open) ...[
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: 'Chiếu lên TV',
          icon: Icons.cast_rounded,
          style: AppButtonStyle.outline,
          onPressed: () => _showTvSheet(context, vm),
        ),
      ],
      const SizedBox(height: AppSpace.s24),
      Text('Chưa quét (${d.missing.length})', style: context.text.section),
      const SizedBox(height: AppSpace.s12),
      for (final s in d.missing) ...[
        StudentRow(name: s.name, code: s.code, present: false, onChanged: (v) => vm.toggle(s, v)),
        const SizedBox(height: AppSpace.s8),
      ],
      const SizedBox(height: AppSpace.s16),
      _PresentHeader(count: d.scanned.length, open: presentOpen, onTap: onTogglePresent),
      if (presentOpen) ...[
        const SizedBox(height: AppSpace.s12),
        for (final s in d.scanned) ...[
          StudentRow(name: s.name, code: s.code, present: true, onChanged: (v) => vm.toggle(s, v)),
          const SizedBox(height: AppSpace.s8),
        ],
      ],
    ]);
  }
}

/// "482917" → "482 917" cho dễ đọc.
String _spaced(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

/// Sheet Chiếu lên TV: link có khoá để gõ trên máy phòng học, kèm nút Chép.
Future<void> _showTvSheet(BuildContext context, SessionViewModel vm) async {
  final link = await vm.startTv();
  if (!context.mounted) return;
  if (link == null) {
    AppToast.show(context, 'Chưa tạo được link, hãy thử lại', error: true);
    return;
  }
  final shown = link.replaceFirst(RegExp('^https?://'), '');
  await AppSheet.show<void>(
    context,
    title: 'Chiếu lên TV',
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Mở link này trên máy chiếu của phòng', style: ctx.text.bodySm),
      const SizedBox(height: AppSpace.s12),
      QaCard(
        kind: CardKind.sunken,
        child: SelectableText(shown, style: ctx.text.bodyStrong.copyWith(color: ctx.status.fgStrong)),
      ),
      const SizedBox(height: AppSpace.s8),
      Text('Link dùng được tới hết giờ slot. Không cần đăng nhập.', style: ctx.text.caption),
      const SizedBox(height: AppSpace.s16),
      AppButton(
        label: 'Chép link',
        icon: Icons.copy_rounded,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: link));
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          if (context.mounted) AppToast.show(context, 'Đã chép link');
        },
      ),
    ]),
  );
}

/// Số có mặt: số đậm 28, “/ tổng” thường 20 (Figma GV-102 v2, khối Đếm).
class _Ratio extends StatelessWidget {
  const _Ratio({required this.present, required this.total});
  final int present;
  final int total;

  @override
  Widget build(BuildContext context) {
    final base = context.text.display.copyWith(color: context.status.fgStrong);
    return Text.rich(TextSpan(children: [
      TextSpan(text: '$present', style: base),
      TextSpan(text: ' / $total', style: base.copyWith(fontSize: 20, fontWeight: FontWeight.w400)),
    ]));
  }
}

/// Hàng có mặt v2 (`265:3564`): cả hàng bấm được để mở hay gập danh sách đã có mặt.
class _PresentHeader extends StatelessWidget {
  const _PresentHeader({required this.count, required this.open, required this.onTap});
  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        expanded: open,
        label: 'Có mặt $count, ${open ? 'bấm để gập' : 'bấm để xem'}',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.touch),
            child: Row(children: [
              Expanded(child: Text('Có mặt ($count)', style: context.text.section)),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.chevron_right, size: 16, color: context.colors.onSurface),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// GV-102 .X (`288:5240`): mất mạng khi chốt. Dải vàng luôn có chữ, không chỉ dựa vào màu.
/// GV-102 .S: kết quả như GV-101 .D3.
class _ClosedBody extends StatelessWidget {
  const _ClosedBody({required this.data});
  final SessionData data;

  @override
  Widget build(BuildContext context) => ScreenBody(children: [
        _SlotInfo(slot: data.slot),
        const SizedBox(height: AppSpace.s24),
        _counts(context, present: data.presentCount, absent: data.absentCount),
        if (data.absentees.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s24),
          Text('Vắng', style: context.text.section),
          const SizedBox(height: AppSpace.s12),
          for (final st in data.absentees) ...[
            StudentRow(name: st.name, code: st.code),
            const SizedBox(height: AppSpace.s8),
          ],
        ],
      ]);
}
