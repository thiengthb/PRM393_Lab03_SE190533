import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/lecturer_viewmodels.dart';
import '../../viewmodels/session_viewmodel.dart';
import '../../widgets/widgets.dart';

/// Thẻ thông tin slot dùng ở GV-101 và GV-102 .S.
class _SlotInfo extends StatelessWidget {
  const _SlotInfo({required this.slot});
  final Slot slot;

  @override
  Widget build(BuildContext context) => QaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(VnDate.range(slot.start, slot.end), style: context.text.bodySm),
          const SizedBox(height: AppSpace.s4),
          Text(slot.classLabel, style: context.text.title),
          const SizedBox(height: AppSpace.s8),
          _line(context, Icons.calendar_today_outlined, VnDate.dayLabel(slot.start)),
          _line(context, Icons.location_on_outlined, slot.room),
          _line(context, Icons.group_outlined, '${slot.studentCount} sinh viên'),
        ]),
      );

  Widget _line(BuildContext context, IconData i, String t) => Padding(
        padding: const EdgeInsets.only(top: AppSpace.s4),
        child: Row(children: [
          Icon(i, size: 16, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpace.s8),
          Text(t, style: context.text.bodySm),
        ]),
      );
}

Widget _counts(BuildContext context, {int? present, int? absent}) => Row(children: [
      Expanded(child: StatTile(value: present?.toString(), label: 'có mặt')),
      const SizedBox(width: AppSpace.s8),
      Expanded(child: StatTile(value: absent?.toString(), label: 'vắng')),
    ]);

// ---------------- GV-101 Chi tiết slot ----------------

class SlotDetailScreen extends ConsumerWidget {
  const SlotDetailScreen({super.key, required this.slotId});
  final String slotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(slotDetailViewModelProvider(slotId));
    final vm = ref.read(slotDetailViewModelProvider(slotId).notifier);
    final d = s.dataOrNull;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Chi tiết slot'),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 2, height: 120)]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
        Ready(:final data) => ScreenBody(children: [
            _SlotInfo(slot: data.slot),
            if (data.phase != SlotPhase.upcoming) ...[
              const SizedBox(height: AppSpace.s12),
              data.slot.closed
                  ? _counts(context, present: data.slot.presentCount, absent: data.slot.absentCount)
                  : _counts(context),
            ],
            if (data.slot.closed && data.absentees.isNotEmpty) ...[
              const SizedBox(height: AppSpace.group),
              Text('Vắng', style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              for (final st in data.absentees) ...[
                StudentRow(name: st.name, code: st.code),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
          ]),
      },
      bottomNavigationBar: d == null
          ? null
          : BottomBar(children: [
              if (d.slot.closed)
                AppButton(
                  label: 'Sửa',
                  icon: Icons.edit_outlined,
                  style: AppButtonStyle.outline,
                  onPressed: () => context.push('/session/$slotId?edit=1'),
                )
              else
                AppButton(
                  label: d.phase == SlotPhase.unclosed ? 'Chốt ngay' : 'Điểm danh',
                  icon: d.phase == SlotPhase.unclosed ? Icons.check : Icons.qr_code_2,
                  // .D1 sắp tới: nút tắt, có tooltip.
                  onPressed: d.phase == SlotPhase.upcoming ? null : () => context.push('/session/$slotId'),
                  semanticsLabel: d.phase == SlotPhase.upcoming ? 'Điểm danh, chưa tới giờ' : null,
                ),
            ]),
    );
  }
}

// ---------------- GV-102 Phiên điểm danh ----------------

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.slotId, this.edit = false});
  final String slotId;
  final bool edit;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
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
      if (next == SessionStep.offline && prev != SessionStep.offline) _showOffline(vm);
    });

    final d = s.dataOrNull;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Điểm danh', icon: Icons.qr_code_2),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 1, height: 260), SkeletonList()]),
        Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
        Ready(:final data) => data.step == SessionStep.closed ? _ClosedBody(data: data) : _LiveBody(data: data, vm: vm),
      },
      bottomNavigationBar: d == null
          ? null
          : BottomBar(children: [
              switch (d.step) {
                SessionStep.open => AppButton(label: 'Chốt', icon: Icons.check, onPressed: vm.closeQr),
                SessionStep.review || SessionStep.offline => AppButton(
                    label: 'Chốt',
                    icon: Icons.check,
                    onPressed: () async {
                      final ok = await AppDialog.confirm(
                        context,
                        title: 'Chốt điểm danh?',
                        message: '${d.presentCount} có mặt · ${d.absentCount} vắng',
                        confirmLabel: 'Chốt',
                        confirmIcon: Icons.check,
                      );
                      if (ok) await vm.confirmClose();
                    },
                  ),
                SessionStep.closing => const AppButton(label: 'Đang xử lý', loading: true, onPressed: null),
                SessionStep.closed => AppButton(label: 'Xong', onPressed: () => context.go('/overview')),
              },
            ]),
    );
  }

  /// GV-OV2 Lỗi mạng: Để sau / Thử lại.
  Future<void> _showOffline(SessionViewModel vm) async {
    final retry = await AppDialog.confirm(
      context,
      title: 'Chưa gửi được',
      message: 'Mất mạng · đã lưu trên máy',
      cancelLabel: 'Để sau',
      confirmLabel: 'Thử lại',
      confirmIcon: Icons.refresh_rounded,
      error: true,
    );
    if (!mounted) return;
    if (retry) {
      await vm.retrySync();
    } else {
      context.go('/overview');
    }
  }
}

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.data, required this.vm});
  final SessionData data;
  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final total = d.roster.length;
    final open = d.step == SessionStep.open;
    return ScreenBody(children: [
      QaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '${d.presentCount} trên $total đã có mặt',
                child: ExcludeSemantics(
                  child: RatioText(value: '${d.presentCount}', total: '$total', style: context.text.display),
                ),
              ),
            ),
            if (!open && d.step != SessionStep.closing)
              AppButton(
                label: 'Mở lại',
                icon: Icons.qr_code_2,
                style: AppButtonStyle.ghost,
                size: AppButtonSize.medium,
                expand: false,
                onPressed: vm.reopen,
              ),
          ]),
          const SizedBox(height: AppSpace.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : d.presentCount / total,
              minHeight: 8,
              color: context.status.fgStrong.withValues(alpha: 0.75),
            ),
          ),
          if (open && d.qrText != null) ...[
            const SizedBox(height: AppSpace.s16),
            Center(
              child: Semantics(
                label: 'Mã QR điểm danh',
                child: QrImageView(data: d.qrText!, size: 220, backgroundColor: context.colors.surface, gapless: true),
              ),
            ),
            const SizedBox(height: AppSpace.s8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Còn ${VnDate.countdown(d.remaining)}', style: context.text.label),
              const SizedBox(width: AppSpace.s12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: AppSpace.s4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text('Đổi mã ${d.rotateIn}s', style: context.text.label.copyWith(color: context.colors.onSurfaceVariant)),
              ),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: AppSpace.group),
      Text('Chưa quét (${d.missing.length})', style: context.text.section),
      const SizedBox(height: AppSpace.s8),
      for (final st in d.missing) ...[
        StudentRow(name: st.name, code: st.code, present: false, onChanged: (v) => vm.toggle(st, v)),
        const SizedBox(height: AppSpace.s8),
      ],
      const SizedBox(height: AppSpace.s16),
      Text('Đã quét (${d.scanned.length})', style: context.text.section),
      const SizedBox(height: AppSpace.s8),
      for (final st in d.scanned) ...[
        StudentRow(name: st.name, code: st.code, present: true, onChanged: (v) => vm.toggle(st, v)),
        const SizedBox(height: AppSpace.s8),
      ],
    ]);
  }
}

/// GV-102 .S: kết quả như GV-101 .D3.
class _ClosedBody extends StatelessWidget {
  const _ClosedBody({required this.data});
  final SessionData data;

  @override
  Widget build(BuildContext context) => ScreenBody(children: [
        _SlotInfo(slot: data.slot),
        const SizedBox(height: AppSpace.s12),
        _counts(context, present: data.presentCount, absent: data.absentCount),
        if (data.absentees.isNotEmpty) ...[
          const SizedBox(height: AppSpace.group),
          Text('Vắng', style: context.text.section),
          const SizedBox(height: AppSpace.s8),
          for (final st in data.absentees) ...[
            StudentRow(name: st.name, code: st.code),
            const SizedBox(height: AppSpace.s8),
          ],
        ],
      ]);
}
