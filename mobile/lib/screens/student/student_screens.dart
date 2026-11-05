import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import '../../viewmodels/student_viewmodels.dart';
import 'package:quick_attend_core/widgets/brand.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

bool _wide(BuildContext c) => c.isWide;

/// Đầu trang web sinh viên. Điện thoại: logo + “Hereby”. Laptop: thêm avatar + tên ở góc phải.
class _WebHeader extends StatelessWidget implements PreferredSizeWidget {
  const _WebHeader({this.user, this.back = false});
  final AppUser? user;
  final bool back;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: back ? 0 : (wide ? AppSpace.s24 : AppSpace.screen),
      leading: back
          ? IconButton(icon: const Icon(Icons.chevron_left, size: 28), tooltip: 'Quay lại', onPressed: () => context.pop())
          : null,
      title: BrandRow(
        trailing: wide && user != null
            ? InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => context.push('/me/account'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    InitialsAvatar(name: user!.displayName, size: 32),
                    const SizedBox(width: AppSpace.s8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(user!.displayName, style: context.text.label.copyWith(color: context.status.fgStrong)),
                      Text(user!.studentCode ?? '', style: context.text.caption),
                    ]),
                  ]),
                ),
              )
            : null,
      ),
    );
  }
}

/// Lời chào đầu trang chủ sinh viên: “Chào Dung” + kỳ học. Điện thoại có avatar bên phải (mở Tài khoản);
/// màn rộng avatar đã nằm trên thanh đầu trang.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.detail, required this.showAvatar});
  final AppUser? user;
  final String detail;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final name = (user?.givenName ?? '').isEmpty ? 'bạn' : user!.givenName;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s20),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text('Chào $name', style: context.text.display)),
            const SizedBox(height: AppSpace.s4),
            Text(detail, style: context.text.body.copyWith(color: context.colors.onSurfaceVariant)),
          ]),
        ),
        if (showAvatar && user != null)
          Semantics(
            button: true,
            label: '${user!.displayName}, ${user!.studentCode}, mở tài khoản',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/me/account'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: InitialsAvatar(name: user!.displayName, size: 44),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Thẻ môn ở trang chủ: tên môn, lớp, số buổi vắng / được vắng và thanh đếm buổi vắng.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.sub});
  final SubjectAttendance sub;

  @override
  Widget build(BuildContext context) {
    final color = _absentColor(context, sub);
    final parts = sub.limit < 1 ? 1 : sub.limit;
    final barColor = warnKindOf(sub) == null ? context.colors.primary : color;
    return QaCard(
      onTap: () => context.push('/me/subject/${sub.classId}'),
      semanticsLabel: '${sub.subject} ${sub.classCode}, vắng ${sub.absent} trên ${sub.limit} buổi được vắng',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(icon: Icons.menu_book_rounded, size: 40, background: context.colors.primaryContainer, color: context.colors.primary),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sub.subject, style: context.text.title),
              Text(sub.classCode, style: context.text.bodySm),
            ]),
          ),
          RatioText(value: '${sub.absent}', total: '${sub.limit}', color: color),
          const SizedBox(width: AppSpace.s4),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ]),
        const SizedBox(height: AppSpace.s12),
        Row(children: [
          for (var i = 0; i < parts; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < sub.absent ? barColor : context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: AppSpace.s8),
        Text(
          sub.absent >= sub.limit ? 'Hết buổi được vắng' : 'Còn được vắng ${sub.limit - sub.absent} buổi',
          style: context.text.caption,
        ),
      ]),
    );
  }
}

/// Dải cảnh báo SV-001 v2: hổ phách khi còn 1 hoặc 0 buổi được vắng, đỏ khi đã fail.
class _WarnBanner extends StatelessWidget {
  const _WarnBanner({required this.subject});
  final SubjectAttendance subject;

  @override
  Widget build(BuildContext context) {
    final kind = warnKindOf(subject)!;
    final st = context.status;
    final failed = kind == WarnKind.failed;
    final text = switch (kind) {
      WarnKind.oneLeft => '${subject.subject} còn được vắng 1 buổi',
      WarnKind.lastChance => '${subject.subject}: vắng thêm sẽ fail',
      WarnKind.failed => '${subject.subject} đã fail',
    };
    final color = failed ? st.danger : st.warning;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16, vertical: AppSpace.s12),
        decoration: BoxDecoration(
          color: failed ? st.dangerSoft : st.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: failed ? st.danger.withValues(alpha: 0.25) : st.warningSoftEdge),
        ),
        child: Row(children: [
          Icon(Icons.warning_rounded, color: color, size: AppSize.icon20),
          const SizedBox(width: AppSpace.s12),
          Expanded(child: Text(text, style: context.text.body.copyWith(color: color))),
        ]),
      ),
    );
  }
}

/// Số buổi vắng: thường khi còn xa ngưỡng, hổ phách khi còn 1 hoặc 0 buổi, đỏ khi đã fail.
Color _absentColor(BuildContext context, SubjectAttendance s) => switch (warnKindOf(s)) {
      WarnKind.failed => context.status.danger,
      WarnKind.oneLeft || WarnKind.lastChance => context.status.warning,
      null => context.status.fgStrong,
    };

// ---------------- SV-001 Buổi vắng của tôi (.D, .D1, .D2, .W) ----------------

class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(myAttendanceViewModelProvider);
    final vm = ref.read(myAttendanceViewModelProvider.notifier);
    final wide = _wide(context);
    final user = ref.watch(myAttendanceUserProvider);
    final pad = EdgeInsets.fromLTRB(wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s8, wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s24);
    return Scaffold(
      appBar: _WebHeader(user: user),
      body: ScreenBody(
        // Sinh viên chỉ có vài môn: giữ một cột đọc thoải mái ở giữa màn rộng.
        maxWidth: wide ? AppLayout.column : 600,
        padding: pad,
        children: [
          ...switch (s) {
            Loading() => <Widget>[const SkeletonList()],
            Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
            Empty() => <Widget>[
                _Greeting(user: user, detail: Term.of(DateTime.now()), showAvatar: !wide),
                const EmptyState(message: 'Chưa có buổi học', icon: Icons.event_note_outlined),
              ],
            Ready(:final data) => <Widget>[
                _Greeting(user: user, detail: '${data.term} · ${data.subjects.length} môn', showAvatar: !wide),
                if (data.warning != null) ...[_WarnBanner(subject: data.warning!), const SizedBox(height: AppSpace.group)],
                const SectionHeader(title: 'Môn học'),
                CardGrid(minItemWidth: 320, children: [for (final sub in data.subjects) _SubjectCard(sub: sub)]),
              ],
          },
          if (wide) ...[
            const SizedBox(height: AppSpace.s32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.qr_code_2, size: AppSize.icon20, color: context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpace.s8),
              Text('Quét mã trên điện thoại', style: context.text.bodySm),
            ]),
          ],
        ],
      ),
      bottomNavigationBar: wide
          ? null
          // v2 bỏ nút Báo sai ở danh sách: báo sai từ từng buổi vắng ở SV-002.
          : BottomBar(children: [
              AppButton(label: 'Quét mã', icon: Icons.qr_code_2, onPressed: () => context.push('/me/scan')),
            ]),
    );
  }
}

// ---------------- SV-002 Chi tiết môn (.D, .W) ----------------

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(myAttendanceViewModelProvider);
    final vm = ref.read(myAttendanceViewModelProvider.notifier);
    final sub = vm.subject(classId);
    final data = s.dataOrNull;
    final wide = _wide(context);
    final user = ref.watch(myAttendanceUserProvider);
    final PreferredSizeWidget appBar;
    if (sub == null) {
      appBar = _WebHeader(user: user, back: true);
    } else {
      appBar = QaAppBar.nested(title: '${sub.subject} · ${sub.classCode}', icon: Icons.group_rounded);
    }
    return Scaffold(
      appBar: appBar,
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        _ when sub == null || data == null => const ScreenBody(children: [EmptyState(message: 'Trống')]),
        _ => ScreenBody(
            maxWidth: wide ? AppLayout.page : 600,
            padding: EdgeInsets.fromLTRB(wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s8, wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s24),
            children: [
              // Màn rộng: khối đếm bên trái, danh sách buổi bên phải.
              TwoColumns(
                mainFlex: 2,
                sideFlex: 3,
                main: [_AbsenceMeter(subject: sub)],
                side: [
                  Text('Buổi học', style: context.text.section),
                  const SizedBox(height: AppSpace.s12),
                  for (final r in sub.sessions) ...[
                    _SessionLine(record: r, request: data.requests[r.slotId], canReport: data.canReport(r)),
                    const SizedBox(height: AppSpace.s12),
                  ],
                ],
              ),
            ],
          ),
      },
    );
  }
}

/// Khối Đếm SV-002 v2 (`295:3703`).
class _AbsenceMeter extends StatelessWidget {
  const _AbsenceMeter({required this.subject});
  final SubjectAttendance subject;

  @override
  Widget build(BuildContext context) =>
      AbsenceMeter(absent: subject.absent, limit: subject.limit, color: _absentColor(context, subject));
}

/// Một buổi ở SV-002 v2: tick xanh hoặc x đỏ ở đầu hàng. Buổi vắng chưa báo là thẻ nổi có "Báo sai";
/// buổi đã báo ghi kết quả (.D1). Buổi có mặt là thẻ chìm.
class _SessionLine extends StatelessWidget {
  const _SessionLine({required this.record, required this.request, required this.canReport});
  final AttendanceRecord record;
  final CorrectionRequest? request;
  final bool canReport;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final r = record;
    final title = r.start == null ? '—' : VnDate.dayLabel(r.start!);
    final req = request;
    final (String? note, Color? noteColor) = switch (req?.status) {
      RequestStatus.pending => ('Đang chờ duyệt', st.warning),
      RequestStatus.approved => ('Đã duyệt', st.success),
      RequestStatus.rejected => (
          'Bị từ chối${(req!.rejectReason ?? '').isEmpty ? '' : ': ${req.rejectReason}'}',
          st.danger,
        ),
      null => (null, null),
    };
    return QaCard(
      kind: canReport ? CardKind.raised : CardKind.sunken,
      onTap: canReport ? () => context.push('/me/report', extra: r) : null,
      semanticsLabel: '$title, ${r.present ? 'có mặt' : 'vắng'}${note == null ? '' : ', $note'}${canReport ? ', bấm để báo sai' : ''}',
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s12),
      child: Row(children: [
        Icon(
          r.present ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: r.present ? st.success : st.danger,
          size: 24,
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: context.text.body.copyWith(color: st.fgStrong)),
            Text('Slot ${r.slotNo} · ${r.room}', style: context.text.bodySm),
            if (note != null) Text(note, style: context.text.bodySm.copyWith(color: noteColor)),
          ]),
        ),
        if (canReport) ...[
          Text('Báo sai', style: context.text.label.copyWith(color: context.colors.primary)),
          const SizedBox(width: AppSpace.s4),
          Icon(Icons.chevron_right, size: AppSize.icon20, color: st.fgStrong),
        ],
      ]),
    );
  }
}

// ---------------- SV-101 Quét mã (.D, .S, .X, .X2) ----------------

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nút Nhập mã: tắt camera trong lúc gõ để không quét nhầm mã khác.
  Future<void> _typeCode() async {
    await _controller.stop();
    if (!mounted) return;
    await context.push('/me/scan/code');
    if (!mounted) return;
    if (ref.read(scanViewModelProvider) is Scanning) await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scanViewModelProvider);
    final vm = ref.read(scanViewModelProvider.notifier);
    final typeCode = AppButton(label: 'Nhập mã', style: AppButtonStyle.outline, onPressed: _typeCode);
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Quét mã', icon: Icons.qr_code_scanner_rounded),
      backgroundColor: s is Scanning || s is Submitting ? context.status.camera : null,
      body: switch (s) {
        Scanning() || Submitting() => _CameraView(
            controller: _controller,
            submitting: s is Submitting,
            onDetect: vm.onCode,
            onBlocked: vm.cameraBlocked,
          ),
        Scanned(:final result) => _ScanDone(slot: result.slot, at: result.at),
        ScanFailed() => _ResultBox(icon: Icons.cancel_rounded, tone: _Tone.danger, title: s.title),
        CameraBlocked() => const _ResultBox(
            icon: Icons.no_photography_outlined,
            tone: _Tone.warning,
            title: 'Cần quyền camera',
            detail: 'Trình duyệt đang chặn camera',
          ),
      },
      bottomNavigationBar: switch (s) {
        Scanning() => BottomBar(children: [typeCode]),
        Scanned(:final result) => _DoneBar(classId: result.slot.classId),
        ScanFailed() => BottomBar(children: [AppButton(label: 'Quét lại', icon: Icons.qr_code_2, onPressed: vm.rescan)]),
        CameraBlocked() => BottomBar(children: [
            typeCode,
            AppButton(
              label: 'Cho phép',
              onPressed: () async {
                vm.rescan();
                await _controller.start();
              },
            ),
          ]),
        _ => null,
      },
    );
  }
}

/// SV-101 .D v2 (`259:3190`): nền camera đen, khung 4 góc, chữ trắng. Không ghi tên lớp
/// vì trước khi quét chưa biết lớp nào (D-L3-17).
class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller, required this.submitting, required this.onDetect, required this.onBlocked});
  final MobileScannerController controller;
  final bool submitting;
  final ValueChanged<String> onDetect;
  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    final on = context.colors.onPrimary;
    return Stack(fit: StackFit.expand, children: [
      if (!submitting)
        MobileScanner(
          controller: controller,
          onDetect: (cap) {
            final raw = cap.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
            if (raw != null) onDetect(raw);
          },
          errorBuilder: (context, error) {
            if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onBlocked());
            }
            return ColoredBox(color: context.status.camera);
          },
        ),
      Column(children: [
        const SizedBox(height: 48),
        Text('Quét mã trên màn chiếu', style: context.text.title.copyWith(color: on), textAlign: TextAlign.center),
        const Spacer(),
        SizedBox.square(
          dimension: 240,
          child: submitting
              ? const Center(child: CircularProgressIndicator())
              : CustomPaint(painter: _CornersPainter(on)),
        ),
        const SizedBox(height: AppSpace.s24),
        Text('Đưa mã vào khung', style: context.text.bodySm.copyWith(color: on), textAlign: TextAlign.center),
        const Spacer(flex: 2),
      ]),
    ]);
  }
}

/// Bốn góc khung quét, nét 4, bo 8.
class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 40.0;
    const r = 8.0;
    final w = size.width;
    final h = size.height;
    for (final (x, y, dx, dy) in [(0.0, 0.0, 1.0, 1.0), (w, 0.0, -1.0, 1.0), (0.0, h, 1.0, -1.0), (w, h, -1.0, -1.0)]) {
      final path = Path()
        ..moveTo(x, y + dy * len)
        ..lineTo(x, y + dy * r)
        ..quadraticBezierTo(x, y, x + dx * r, y)
        ..lineTo(x + dx * len, y);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}

/// .S Đã ghi nhận: môn, slot, giờ ghi.
class _ScanDone extends StatelessWidget {
  const _ScanDone({required this.slot, required this.at});
  final Slot slot;
  final DateTime at;

  @override
  Widget build(BuildContext context) => _ResultBox(
        icon: Icons.check_circle_rounded,
        tone: _Tone.success,
        title: 'Đã ghi nhận',
        detail: '${slot.subject} · Slot ${slot.slotNo} · ${VnDate.hm(at)}',
      );
}

/// Thanh đáy .S: dải còn vắng theo ba mức (`256:2460`, `260:2724`, `260:2772`) rồi nút Xong.
class _DoneBar extends ConsumerWidget {
  const _DoneBar({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(myAttendanceViewModelProvider);
    final sub = ref.read(myAttendanceViewModelProvider.notifier).subject(classId);
    final st = context.status;
    Widget? strip;
    if (sub != null) {
      final kind = warnKindOf(sub);
      final (Color bg, Color fg) = switch (kind) {
        WarnKind.failed => (st.dangerSoft, st.danger),
        WarnKind.oneLeft || WarnKind.lastChance => (st.warningSoft, st.warning),
        null => (context.colors.surfaceContainerHighest, st.fgStrong),
      };
      final base = context.text.body.copyWith(color: fg);
      final text = switch (kind) {
        WarnKind.failed => Text('Đã vượt ngưỡng vắng', style: base),
        WarnKind.lastChance => Text('Vắng thêm sẽ fail', style: base),
        _ => Text.rich(
            TextSpan(style: base, children: [
              const TextSpan(text: 'Còn được vắng '),
              TextSpan(text: '${sub.remaining} buổi', style: base.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
      };
      strip = Semantics(
        liveRegion: true,
        child: Container(
          color: bg,
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.s12),
          child: text,
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ?strip,
      BottomBar(children: [AppButton(label: 'Xong', onPressed: () => context.go('/me'))]),
    ]);
  }
}

/// SV-101 Nhập mã: gõ 6 chữ số hiện trên màn chiếu khi không quét được.
class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key});

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends ConsumerState<CodeEntryScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _retry() {
    _code.clear();
    ref.read(scanViewModelProvider.notifier).rescan();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scanViewModelProvider);
    final vm = ref.read(scanViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Nhập mã', icon: Icons.qr_code_scanner_rounded),
      body: switch (s) {
        Scanned(:final result) => _ScanDone(slot: result.slot, at: result.at),
        ScanFailed() => _ResultBox(icon: Icons.cancel_rounded, tone: _Tone.danger, title: s.title, detail: s.detail),
        _ => ScreenBody(children: [
            const SizedBox(height: AppSpace.s24),
            Text('Nhập mã trên màn chiếu', style: context.text.title.copyWith(color: context.status.fgStrong), textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.s24),
            _CodeBoxes(controller: _code, focus: _focus, enabled: s is! Submitting, onDone: vm.submitCode),
          ]),
      },
      bottomNavigationBar: switch (s) {
        Scanned(:final result) => _DoneBar(classId: result.slot.classId),
        ScanFailed() => BottomBar(children: [AppButton(label: 'Nhập lại', onPressed: _retry)]),
        _ => ListenableBuilder(
            listenable: _code,
            builder: (context, _) => BottomBar(children: [
              AppButton(
                label: 'Gửi',
                loading: s is Submitting,
                onPressed: _code.text.length == 6 && s is! Submitting ? () => vm.submitCode(_code.text) : null,
              ),
            ]),
          ),
      },
    );
  }
}

/// Sáu ô số (Figma `259:3108`). Một ô nhập ẩn phía trên nhận bàn phím số và dán.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.controller, required this.focus, required this.enabled, required this.onDone});
  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final ValueChanged<String> onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, focus]),
          builder: (context, _) {
            final t = controller.text;
            return ExcludeSemantics(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 6; i++) ...[
                if (i == 3) const SizedBox(width: AppSpace.s12) else if (i > 0) const SizedBox(width: AppSpace.s8),
                Container(
                  width: 44,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: i == t.length && focus.hasFocus ? Border.all(color: context.colors.primary, width: 2) : null,
                  ),
                  child: Text(i < t.length ? t[i] : '', style: context.text.titleLg.copyWith(color: context.status.fgStrong)),
                ),
              ],
            ]),
            );
          },
        ),
        // Ô nhập thật nằm trên 6 ô vẽ, trong suốt. Giữ trong cây accessibility để trình đọc
        // màn hình và ARTEMIS (TC-17) tìm được ô "Mã 6 chữ số"; Opacity 0 mặc định bỏ nó đi.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: TextField(
              controller: controller,
              focusNode: focus,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none, labelText: 'Mã 6 chữ số'),
              onSubmitted: (v) {
                if (v.length == 6) onDone(v);
              },
            ),
          ),
        ),
      ]),
    );
  }
}

enum _Tone { success, warning, danger }

/// Kết quả giữa màn (SV-101 .S, .X, .X2, SV-102 .S): ô icon 56 nền nhạt, tiêu đề, dòng phụ.
class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.icon, required this.tone, required this.title, this.detail});
  final IconData icon;
  final _Tone tone;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final (Color bg, Color fg) = switch (tone) {
      _Tone.success => (st.successSoft, st.success),
      _Tone.warning => (st.warningSoft, st.warning),
      _Tone.danger => (st.dangerSoft, st.danger),
    };
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconTile(icon: icon, background: bg, color: fg, size: 64),
            const SizedBox(height: AppSpace.s24),
            Text(title, style: context.text.titleLg.copyWith(color: st.fgStrong), textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: AppSpace.s4),
              Text(detail!, style: context.text.body, textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }
}

// ---------------- SV-102 Gửi báo sai ----------------

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.session});
  final AttendanceRecord? session;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reportViewModelProvider);
    final vm = ref.read(reportViewModelProvider.notifier);
    final r = widget.session;
    const bar = QaAppBar.nested(title: 'Báo sai', icon: Icons.chat_bubble_rounded);
    final when = r == null ? '' : '${r.subject}${r.start == null ? '' : ' · ${VnDate.dayLabel(r.start!)}'}';
    if (s.sent) {
      // .S v2 (`296:3887`): dòng phụ là buổi vừa báo.
      return Scaffold(
        appBar: bar,
        body: _ResultBox(icon: Icons.send_rounded, tone: _Tone.success, title: 'Đã gửi', detail: when),
        bottomNavigationBar: BottomBar(children: [AppButton(label: 'Xong', onPressed: () => context.go('/me'))]),
      );
    }
    return Scaffold(
      appBar: bar,
      body: r == null
          ? const ScreenBody(children: [EmptyState(message: 'Không có buổi vắng')])
          : ScreenBody(children: [
              // .D v2 (`296:3808`): thẻ chìm buổi vắng, nhóm lý do trong một thẻ, ô ghi thêm nền xám.
              QaCard(
                kind: CardKind.sunken,
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.subject, style: context.text.body.copyWith(color: context.status.fgStrong)),
                      Text('${r.start == null ? '' : VnDate.dayLabel(r.start!)} · Slot ${r.slotNo}', style: context.text.bodySm),
                    ]),
                  ),
                  const StatusChip.absent(),
                ]),
              ),
              const SizedBox(height: AppSpace.group),
              Text('Chọn lý do', style: context.text.section),
              const SizedBox(height: AppSpace.s12),
              QaCard(
                kind: CardKind.raised,
                padding: EdgeInsets.zero,
                child: RadioGroup<String>(
                  groupValue: s.reason,
                  onChanged: (v) {
                    if (v != null) vm.choose(v);
                  },
                  child: Column(children: [
                    for (var i = 0; i < reportReasons.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: context.colors.outlineVariant),
                      RadioListTile<String>(
                        value: reportReasons[i],
                        title: Text(reportReasons[i], style: context.text.body.copyWith(color: context.status.fgStrong)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                      ),
                    ],
                  ]),
                ),
              ),
              if (s.error != null) ...[
                const SizedBox(height: AppSpace.s8),
                Text(s.error!, style: context.text.bodySm.copyWith(color: context.status.danger)),
              ],
              const SizedBox(height: AppSpace.group),
              AppTextField(label: 'Ghi thêm', hint: 'Em quét rồi nhưng mạng lỗi', controller: _note, maxLines: 3),
            ]),
      // Nút Gửi ở thanh đáy như các màn khác (kế hoạch v2: SV-102 nút Gửi ở thanh đáy).
      bottomNavigationBar: r == null
          ? null
          : BottomBar(children: [
              AppButton(
                label: 'Gửi',
                icon: Icons.send_outlined,
                loading: s.sending,
                onPressed: s.sending ? null : () => vm.send(r, _note.text),
              ),
            ]),
    );
  }
}
