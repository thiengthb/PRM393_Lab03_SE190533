import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';
import '../../../viewmodels/session_viewmodel.dart';

/// GV-102 Phiên điểm danh, desktop (direction A chosen 09/11): the QR code and counters on the
/// left, the whole class as a table on the right. Space closes the code, Ctrl+Enter finalises,
/// / jumps to search. Same [SessionViewModel] as the phone screen.
class SessionDesktop extends StatefulWidget {
  const SessionDesktop({super.key, required this.state, required this.vm, required this.onTv});

  final ViewState<SessionData> state;
  final SessionViewModel vm;
  final VoidCallback onTv;

  @override
  State<SessionDesktop> createState() => _SessionDesktopState();
}

class _SessionDesktopState extends State<SessionDesktop> {
  RosterFilter? _filter;
  String _query = '';
  final _search = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final vm = widget.vm;
    final d = s.dataOrNull;
    final step = d?.step;
    final title = d == null ? 'Điểm danh' : '${d.slot.classLabel} · Slot ${d.slot.slotNo}';
    final subtitle = d == null ? null : '${VnDate.dayLabel(d.slot.start)} · ${VnDate.range(d.slot.start, d.slot.end)} · ${d.slot.room}';
    void back() => context.canPop() ? context.pop() : context.go('/overview');

    final actions = <Widget>[
      if (step == SessionStep.open) ...[
        AppButton(label: 'Chiếu lên TV', icon: LucideIcons.cast, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: widget.onTv),
        _Keyed(keys: 'Space', child: AppButton(label: 'Đóng mã', icon: LucideIcons.lock, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: vm.closeQr)),
      ],
      if ((step == SessionStep.review || step == SessionStep.offline) && d!.canReopen)
        AppButton(label: 'Mở lại mã', icon: LucideIcons.qrCode, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: vm.reopen),
      if (step == SessionStep.review || step == SessionStep.offline || step == SessionStep.open)
        _Keyed(
          keys: 'Ctrl ↵',
          child: AppButton(
            label: 'Chốt',
            icon: LucideIcons.check,
            size: AppButtonSize.small,
            expand: false,
            // Finalising while the code is open closes it first (same as Đóng mã, then Chốt).
            onPressed: step == SessionStep.open ? null : vm.confirmClose,
          ),
        ),
      if (step == SessionStep.closing) const AppButton(label: 'Đang chốt', loading: true, size: AppButtonSize.small, expand: false, onPressed: null),
      if (step == SessionStep.closed) ...[
        AppButton(label: 'Sửa', icon: LucideIcons.pencil, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: vm.edit),
        AppButton(label: 'Xong', size: AppButtonSize.small, expand: false, onPressed: () => context.go('/overview')),
      ],
    ];

    return DeskShortcuts(
      bindings: {
        if (step == SessionStep.open) const SingleActivator(LogicalKeyboardKey.space): vm.closeQr,
        if (step == SessionStep.review || step == SessionStep.offline)
          const SingleActivator(LogicalKeyboardKey.enter, control: true): vm.confirmClose,
        const SingleActivator(LogicalKeyboardKey.slash): _search.requestFocus,
        const SingleActivator(LogicalKeyboardKey.escape): back,
      },
      child: DeskPage(
        title: title,
        subtitle: subtitle,
        onBack: back,
        actions: actions,
        banner: step == SessionStep.offline
            ? Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.s20, AppSpace.s12, AppSpace.s20, 0),
                child: OfflineBanner(title: 'Chưa gửi được', detail: 'Đã lưu trên máy, có mạng sẽ tự gửi', onRetry: vm.retrySync),
              )
            : null,
        body: switch (s) {
          Loading() || Empty() => const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 400, child: SkeletonList(count: 1, height: 420)),
              SizedBox(width: AppSpace.s16),
              Expanded(child: SkeletonList(count: 8)),
            ]),
          Failure(:final message, :final canRetry) => ErrorState(message: message, onRetry: canRetry ? vm.retry : null),
          Ready(:final data) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: 400, child: _CodePanel(data: data)),
              const SizedBox(width: AppSpace.s16),
              Expanded(child: _Roster(data: data, vm: vm, filter: _filter ?? (data.step == SessionStep.open ? RosterFilter.missing : RosterFilter.all), query: _query, search: _search, onFilter: (f) => setState(() => _filter = f), onQuery: (q) => setState(() => _query = q))),
            ]),
        },
      ),
    );
  }
}

/// A button with its keyboard hint to the right.
class _Keyed extends StatelessWidget {
  const _Keyed({required this.keys, required this.child});
  final String keys;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [child, const SizedBox(width: 6), Kbd(keys)]);
}

String _spaced(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.data});
  final SessionData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final c = context.colors;
    final st = context.status;
    final total = d.roster.length;
    final open = d.step == SessionStep.open && d.qrText != null;
    final (String tag, Color dot) = switch (d.step) {
      SessionStep.open => ('Đang mở mã', st.danger),
      SessionStep.closed => ('Đã chốt', st.success),
      SessionStep.closing => ('Đang chốt', c.primary),
      SessionStep.offline => ('Chưa gửi được', st.warning),
      SessionStep.review => ('Đã đóng mã', c.onSurfaceVariant),
    };
    final ratio = Semantics(
      liveRegion: true,
      container: true,
      label: '${d.presentCount} trên $total đã có mặt',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('Đã có mặt', style: context.text.bodySm),
            const Spacer(),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${d.presentCount}', style: context.text.title.copyWith(color: st.fgStrong)),
              TextSpan(text: ' / $total', style: context.text.bodySm),
            ])),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : d.presentCount / total,
              minHeight: 6,
              backgroundColor: c.surfaceContainerHighest,
              color: d.step == SessionStep.open ? st.fill : c.onSurfaceVariant,
            ),
          ),
        ]),
      ),
    );
    return DeskCard(
      padding: const EdgeInsets.all(AppSpace.s20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(tag, style: context.text.caption.copyWith(color: d.step == SessionStep.open ? st.danger : st.fgStrong, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (d.step == SessionStep.open) Text('Còn ${VnDate.countdown(d.remaining)}', style: context.text.caption),
        ]),
        const SizedBox(height: AppSpace.s16),
        if (open) ...[
          Center(
            child: Semantics(
              label: 'Mã QR điểm danh',
              child: QrImageView(
                data: d.qrText!,
                size: 300,
                padding: const EdgeInsets.all(AppSpace.s12),
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
          ),
          if (d.code != null) ...[
            const SizedBox(height: AppSpace.s12),
            Center(child: Text('Mã số', style: context.text.caption)),
            Center(
              child: Semantics(
                label: 'Mã số ${d.code!.split('').join(' ')}',
                child: ExcludeSemantics(
                  child: Text(_spaced(d.code!), style: context.text.display.copyWith(fontSize: 30, letterSpacing: 6, color: st.fgStrong)),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s4),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const RotateCodeIcon(),
              const SizedBox(width: 6),
              Text('Mã mới sau ${d.rotateIn} giây', style: context.text.caption),
            ]),
          ),
          const SizedBox(height: AppSpace.s20),
        ] else ...[
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(d.step == SessionStep.closed ? LucideIcons.circleCheck : LucideIcons.lock, size: 28, color: d.step == SessionStep.closed ? st.success : c.onSurfaceVariant),
              const SizedBox(height: AppSpace.s8),
              Text(
                switch (d.step) {
                  SessionStep.closed => 'Đã chốt: ${d.presentCount} có mặt, ${d.absentCount} vắng',
                  _ => 'Mã đã đóng. Bật công tắc cho em có mặt mà không quét được, rồi Chốt.',
                },
                textAlign: TextAlign.center,
                style: context.text.bodySm,
              ),
            ]),
          ),
          const SizedBox(height: AppSpace.s20),
        ],
        ratio,
      ]),
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.data, required this.vm, required this.filter, required this.query, required this.search, required this.onFilter, required this.onQuery});
  final SessionData data;
  final SessionViewModel vm;
  final RosterFilter filter;
  final String query;
  final FocusNode search;
  final ValueChanged<RosterFilter> onFilter;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final st = context.status;
    final c = context.colors;
    final order = {for (var i = 0; i < d.roster.length; i++) d.roster[i].code: i + 1};
    final rows = d.rosterView(filter, query);
    final editable = d.step == SessionStep.open || d.step == SessionStep.review || d.step == SessionStep.offline;

    Widget chip(Student s) {
      final r = d.records[s.code];
      final present = d.isPresent(s.code);
      final (String label, Color fg, Color bg) = present
          ? (r?.source == AttendanceSource.manual ? ('Bật tay', c.primary, c.primaryContainer) : ('Có mặt', st.success, st.successSoft))
          : (d.step == SessionStep.closed ? ('Vắng', st.danger, st.dangerSoft) : ('Chưa quét', c.onSurfaceVariant, c.surfaceContainerHighest));
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w500)),
      );
    }

    return DeskCard(
      expand: true,
      header: Row(children: [
        AppSegmented<RosterFilter>(
          options: [
            (RosterFilter.all, 'Tất cả ${d.roster.length}'),
            (RosterFilter.missing, '${d.step == SessionStep.closed ? 'Vắng' : 'Chưa quét'} ${d.missing.length}'),
            (RosterFilter.present, 'Có mặt ${d.presentCount}'),
          ],
          value: filter,
          onChanged: onFilter,
        ),
        const Spacer(),
        DeskSearchField(hint: 'Tìm tên, MSSV', onChanged: onQuery, shortcut: '/', focusNode: search, width: 220),
      ]),
      child: DeskTable<Student>(
        rows: rows,
        emptyMessage: query.isEmpty ? (filter == RosterFilter.missing ? 'Cả lớp đã có mặt' : 'Trống') : 'Không thấy "$query"',
        emptyIcon: filter == RosterFilter.missing && query.isEmpty ? LucideIcons.circleCheck : LucideIcons.searchX,
        rowLabel: (s) => '${s.name}, ${s.code}, ${d.isPresent(s.code) ? 'có mặt' : 'chưa có mặt'}',
        columns: [
          DeskColumn(label: '#', width: 52, cell: (_, s) => Text('${order[s.code]}', style: context.text.caption), sortBy: (s) => order[s.code]!),
          DeskColumn(label: 'MSSV', width: 120, cell: (_, s) => Text(s.code), sortBy: (s) => s.code),
          DeskColumn(label: 'Họ tên', flex: 3, cell: (_, s) => Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)), sortBy: (s) => s.name),
          DeskColumn(label: 'Trạng thái', width: 130, cell: (_, s) => chip(s), sortBy: (s) => d.isPresent(s.code) ? 1 : 0),
          DeskColumn(
            label: 'Giờ quét',
            width: 100,
            cell: (_, s) {
              final at = d.records[s.code]?.at;
              return Text(at == null || !d.isPresent(s.code) ? '–' : VnDate.hm(at), style: context.text.caption);
            },
          ),
          DeskColumn(
            label: 'Có mặt',
            width: 90,
            cell: (_, s) => AppSwitch(
              value: d.isPresent(s.code),
              semanticLabel: 'Có mặt: ${s.name}',
              onChanged: editable ? (v) => vm.toggle(s, v) : null,
            ),
          ),
        ],
      ),
    );
  }
}
