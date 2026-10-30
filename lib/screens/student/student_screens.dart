import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/student_viewmodels.dart';
import '../../widgets/brand.dart';
import '../../widgets/widgets.dart';

bool _wide(BuildContext c) => MediaQuery.sizeOf(c).width >= AppSize.wideBreakpoint;

/// Đầu trang web sinh viên. Điện thoại: logo + “Quick Attend”. Laptop: thêm avatar + tên ở góc phải.
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

/// Dòng avatar + tên + MSSV đầu nội dung (điện thoại); chạm mở Tài khoản.
class _UserLine extends StatelessWidget {
  const _UserLine({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${user.displayName}, ${user.studentCode}, mở tài khoản',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.push('/me/account'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
            child: Row(children: [
              InitialsAvatar(name: user.displayName),
              const SizedBox(width: AppSpace.s12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.displayName, style: context.text.body.copyWith(color: context.status.fgStrong)),
                Text(user.studentCode ?? '', style: context.text.bodySm),
              ]),
            ]),
          ),
        ),
      );
}

class _WarnBanner extends StatelessWidget {
  const _WarnBanner({required this.subject});
  final SubjectAttendance subject;

  @override
  Widget build(BuildContext context) {
    final over = subject.level == AbsenceLevel.over;
    final text = subject.remaining < 0
        ? '${subject.subject}: đã quá số buổi được vắng'
        : over
            ? '${subject.subject}: vắng thêm 1 buổi là cấm thi'
            : '${subject.subject} còn ${subject.remaining} buổi được vắng';
    final color = over ? context.status.danger : context.status.warning;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s12),
        decoration: BoxDecoration(
          color: over ? context.status.dangerSoft : context.status.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Icon(Icons.warning_rounded, color: color, size: AppSize.icon20),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: Text(text, style: context.text.body.copyWith(color: color))),
        ]),
      ),
    );
  }
}

Color _ratioColor(BuildContext context, SubjectAttendance s) => switch (s.level) {
      AbsenceLevel.over => context.status.danger,
      AbsenceLevel.near => context.status.warning,
      AbsenceLevel.ok => context.status.fgStrong,
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
    final latestAbsence = s.dataOrNull?.latestAbsence;
    return Scaffold(
      appBar: _WebHeader(user: user),
      body: ScreenBody(
        maxWidth: wide ? 1200 : 600,
        padding: pad,
        children: [
          if (!wide && user != null) _UserLine(user: user),
          const SizedBox(height: AppSpace.s8),
          ...switch (s) {
            Loading() => <Widget>[const SkeletonList()],
            Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
            Empty() => <Widget>[
                DateHeader(left: Term.of(DateTime.now()), right: wide ? null : 'Có mặt'),
                const SizedBox(height: AppSpace.s12),
                const EmptyState(message: 'Chưa có buổi học', icon: Icons.event_note_outlined),
              ],
            Ready(:final data) => <Widget>[
                if (data.warning != null) ...[_WarnBanner(subject: data.warning!), const SizedBox(height: AppSpace.group)],
                if (wide)
                  Row(children: [
                    Expanded(child: Text('Môn học', style: context.text.section)),
                    Text('Có mặt / đã học', style: context.text.bodySm),
                    const SizedBox(width: 40),
                  ])
                else
                  DateHeader(left: data.term, right: 'Có mặt'),
                const SizedBox(height: AppSpace.s12),
                for (final sub in data.subjects) ...[
                  QaCard(
                    onTap: () => context.push('/me/subject/${sub.classId}'),
                    semanticsLabel: '${sub.subject} ${sub.classCode}, có mặt ${sub.attended} trên ${sub.held}',
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(sub.subject, style: context.text.body.copyWith(color: context.status.fgStrong)),
                          Text(sub.classCode, style: context.text.bodySm),
                        ]),
                      ),
                      RatioText(value: '${sub.attended}', total: '${sub.held}', color: _ratioColor(context, sub)),
                      const SizedBox(width: AppSpace.s8),
                      Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                    ]),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
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
          : BottomBar(children: [
              AppButton(
                label: 'Báo sai',
                icon: Icons.chat_bubble_outline_rounded,
                style: AppButtonStyle.outline,
                onPressed: latestAbsence == null ? null : () => context.push('/me/report', extra: latestAbsence),
              ),
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
    final wide = _wide(context);
    final user = ref.watch(myAttendanceUserProvider);
    final firstAbsent = sub?.sessions.where((r) => !r.present).firstOrNull;
    return Scaffold(
      appBar: _WebHeader(user: user, back: true),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        _ when sub == null => const ScreenBody(children: [EmptyState(message: 'Trống')]),
        _ => ScreenBody(
            maxWidth: wide ? 1200 : 600,
            padding: EdgeInsets.fromLTRB(wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s8, wide ? AppSpace.s24 : AppSpace.screen, AppSpace.s24),
            children: [
              Row(children: [
                Expanded(child: Text('${sub!.subject} · ${sub.classCode}', style: context.text.title)),
                if (wide)
                  AppButton(
                    label: 'Báo sai',
                    icon: Icons.chat_bubble_outline_rounded,
                    style: AppButtonStyle.outline,
                    size: AppButtonSize.medium,
                    expand: false,
                    onPressed: firstAbsent == null ? null : () => context.push('/me/report', extra: firstAbsent),
                  ),
              ]),
              const SizedBox(height: AppSpace.s12),
              QaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RatioText(value: '${sub.attended}', total: '${sub.held}', style: context.text.display, color: _ratioColor(context, sub)),
                  Text('buổi có mặt', style: context.text.bodySm),
                ]),
              ),
              const SizedBox(height: AppSpace.group),
              Text('Buổi học', style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              for (final r in sub.sessions) ...[
                SessionRow(
                  title: r.start == null ? '—' : VnDate.dayLabel(r.start!),
                  subtitle: 'Slot ${r.slotNo} · ${r.room}',
                  trailing: r.present ? const StatusChip.present() : const StatusChip.absent(),
                  onTap: r.present ? null : () => context.push('/me/report', extra: r),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
          ),
      },
      bottomNavigationBar: wide || sub == null
          ? null
          : BottomBar(children: [
              AppButton(
                label: 'Báo sai',
                icon: Icons.chat_bubble_outline_rounded,
                style: AppButtonStyle.outline,
                onPressed: firstAbsent == null ? null : () => context.push('/me/report', extra: firstAbsent),
              ),
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scanViewModelProvider);
    final vm = ref.read(scanViewModelProvider.notifier);
    final user = ref.watch(myAttendanceUserProvider);
    final scanning = s is Scanning || s is Submitting;
    return Scaffold(
      appBar: _WebHeader(user: user, back: true),
      body: ScreenBody(children: [
        Text('Quét mã', style: context.text.titleLg),
        const SizedBox(height: AppSpace.s12),
        switch (s) {
          Scanning() || Submitting() => Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(color: context.status.camera),
                    if (scanning)
                      MobileScanner(
                        controller: _controller,
                        onDetect: (cap) {
                          final raw = cap.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                          if (raw != null) vm.onCode(raw);
                        },
                        errorBuilder: (context, error) {
                          if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                            WidgetsBinding.instance.addPostFrameCallback((_) => vm.cameraBlocked());
                          }
                          return ColoredBox(color: context.status.camera);
                        },
                      ),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.onPrimary, width: 3),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                    if (s is Submitting) const Center(child: CircularProgressIndicator()),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpace.s12),
              Text('Quét mã trên màn chiếu', style: context.text.body, textAlign: TextAlign.center),
              Text('Đưa mã vào khung', style: context.text.bodySm, textAlign: TextAlign.center),
            ]),
          Scanned(:final result) => _ResultBox(
              icon: Icons.check_rounded,
              tone: _Tone.success,
              title: 'Đã ghi nhận',
              detail: '${result.slot.subject} · Slot ${result.slot.slotNo} · ${VnDate.hm(result.at)}',
            ),
          ScanFailed() => _ResultBox(icon: Icons.timer_off_outlined, tone: _Tone.danger, title: s.title, detail: s.detail),
          CameraBlocked() => const _ResultBox(
              icon: Icons.no_photography_outlined,
              tone: _Tone.warning,
              title: 'Cần quyền camera',
              detail: 'Trình duyệt đang chặn camera',
            ),
        },
      ]),
      bottomNavigationBar: switch (s) {
        Scanned() => BottomBar(children: [AppButton(label: 'Xong', onPressed: () => context.go('/me'))]),
        ScanFailed() => BottomBar(children: [AppButton(label: 'Quét lại', icon: Icons.qr_code_2, onPressed: vm.rescan)]),
        CameraBlocked() => BottomBar(children: [
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

enum _Tone { success, warning, danger }

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.icon, required this.tone, required this.title, required this.detail});
  final IconData icon;
  final _Tone tone;
  final String title;
  final String detail;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s32),
        child: Column(children: [
          IconTile(icon: icon, background: bg, color: fg, size: 64),
          const SizedBox(height: AppSpace.s16),
          Text(title, style: context.text.titleLg, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.s4),
          Text(detail, style: context.text.body, textAlign: TextAlign.center),
        ]),
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
    final user = ref.watch(myAttendanceUserProvider);
    final r = widget.session;
    if (s.sent) {
      return Scaffold(
        appBar: _WebHeader(user: user),
        body: const ScreenBody(children: [
          _ResultBox(icon: Icons.send_rounded, tone: _Tone.success, title: 'Đã gửi', detail: 'Giảng viên sẽ duyệt trong ngày'),
        ]),
        bottomNavigationBar: BottomBar(children: [AppButton(label: 'Xong', onPressed: () => context.go('/me'))]),
      );
    }
    return Scaffold(
      appBar: _WebHeader(user: user, back: true),
      body: r == null
          ? const ScreenBody(children: [EmptyState(message: 'Không có buổi vắng')])
          : ScreenBody(children: [
              Text('Báo sai', style: context.text.titleLg),
              const SizedBox(height: AppSpace.s12),
              QaCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.subject, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
                      Text('${r.start == null ? '' : VnDate.dayLabel(r.start!)} · Slot ${r.slotNo}', style: context.text.bodySm),
                    ]),
                  ),
                  const StatusChip.absent(),
                ]),
              ),
              const SizedBox(height: AppSpace.group),
              Text('Chọn lý do', style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              RadioGroup<String>(
                groupValue: s.reason,
                onChanged: (v) {
                  if (v != null) vm.choose(v);
                },
                child: Column(children: [
                  for (final x in reportReasons)
                    RadioListTile<String>(
                      value: x,
                      title: Text(x, style: context.text.body),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ]),
              ),
              if (s.error != null)
                Text(s.error!, style: context.text.bodySm.copyWith(color: context.status.danger)),
              const SizedBox(height: AppSpace.s12),
              AppTextField(label: 'Ghi thêm', hint: 'Em quét rồi nhưng mạng lỗi', controller: _note, maxLines: 3),
              const SizedBox(height: AppSpace.s16),
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
