import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/classes_viewmodels.dart';
import '../../widgets/widgets.dart';

/// Khu demo Firebase (đề Lab 3 mục 3): thông báo, xuất và tải file, Remote Config, Crashlytics.
class FirebaseDemoScreen extends ConsumerWidget {
  const FirebaseDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(firebaseDemoViewModelProvider);
    final vm = ref.read(firebaseDemoViewModelProvider.notifier);
    final cfg = ref.watch(firebaseDemoConfigProvider);
    final classes = ref.watch(demoClassesProvider);
    ref.listen(firebaseDemoViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next);
        vm.messageShown();
      }
    });
    final lecturer = AppConfig.portal == UserRole.lecturer;
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Khu demo', icon: Icons.science_outlined),
      body: ScreenBody(children: [
        _Section(title: 'Cloud Messaging', children: [
          _KV('Quyền thông báo', switch (s.permission) { true => 'Đã cho phép', false => 'Bị chặn', null => 'Chưa hỏi' }),
          _KV('FCM token', s.token == null ? 'Đang lấy…' : (s.token!.isEmpty ? 'Chưa có' : '${s.token!.substring(0, s.token!.length < 24 ? s.token!.length : 24)}…')),
          const SizedBox(height: AppSpace.s8),
          Row(children: [
            Expanded(child: AppButton(label: 'Cho phép', size: AppButtonSize.medium, style: AppButtonStyle.outline, onPressed: vm.requestPermission)),
            const SizedBox(width: AppSpace.s8),
            Expanded(child: AppButton(label: 'Chép token', size: AppButtonSize.medium, style: AppButtonStyle.outline, onPressed: vm.copyToken)),
          ]),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            label: 'Trung tâm thông báo',
            icon: Icons.notifications_none_rounded,
            size: AppButtonSize.medium,
            trailingArrow: true,
            onPressed: () => context.push('/notifications'),
          ),
        ]),
        if (lecturer)
          _Section(title: 'Xuất báo cáo · Cloud Storage', children: [
            if (classes.isEmpty)
              Text('Chưa có lớp kỳ này', style: context.text.bodySm)
            else
              Wrap(spacing: AppSpace.s8, runSpacing: AppSpace.s8, children: [
                for (final c in classes)
                  AppChip(
                    label: c.label,
                    selected: (s.selectedClassId ?? classes.first.id) == c.id,
                    onTap: () => vm.selectClass(c.id),
                  ),
              ]),
            const SizedBox(height: AppSpace.s12),
            _ExportStatus(state: s.export),
            const SizedBox(height: AppSpace.s8),
            AppButton(
              label: 'Xuất PDF và tải lên',
              icon: Icons.picture_as_pdf_outlined,
              size: AppButtonSize.medium,
              loading: s.export is ExportRunning,
              onPressed: classes.isEmpty || s.export is ExportRunning ? null : () => vm.exportSelected(classes),
            ),
          ]),
        _Section(title: 'Remote Config', children: [
          _KV('absence_limit_percent', '${cfg.absenceLimitPercent}%'),
          _KV('qr_rotate_seconds', '${cfg.qrRotateSeconds}s'),
          _KV('attention_preview_count', '${cfg.attentionPreviewCount}'),
          _KV('session_minutes', '${cfg.sessionMinutes}'),
          _KV('Nguồn', cfg.source),
          if (cfg.fetchedAt != null && cfg.fetchedAt!.year > 1970)
            _KV('Lần tải', '${VnDate.dm(cfg.fetchedAt!)} ${VnDate.hm(cfg.fetchedAt!)}'),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            label: 'Tải lại',
            icon: Icons.refresh_rounded,
            size: AppButtonSize.medium,
            style: AppButtonStyle.outline,
            loading: s.refreshing,
            onPressed: s.refreshing ? null : vm.refreshConfig,
          ),
        ]),
        _Section(title: 'Crashlytics', children: [
          Row(children: [
            Expanded(child: AppButton(label: 'Lỗi non-fatal', size: AppButtonSize.medium, style: AppButtonStyle.outline, onPressed: vm.nonFatal)),
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: AppButton(
                label: 'Test crash',
                size: AppButtonSize.medium,
                style: AppButtonStyle.destructive,
                onPressed: () async {
                  final ok = await AppDialog.confirm(context,
                      title: 'Đóng app để thử?', message: 'App sẽ thoát ngay', confirmLabel: 'Test crash', destructive: true);
                  if (ok) vm.crash();
                },
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _ExportStatus extends StatelessWidget {
  const _ExportStatus({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) => switch (state) {
        ExportIdle() => const SizedBox.shrink(),
        ExportRunning(:final progress, :final step) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$step · ${(progress * 100).round()}%', style: context.text.bodySm),
            const SizedBox(height: AppSpace.s4),
            LinearProgressIndicator(value: progress == 0 ? null : progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ]),
        ExportDone(:final url, :final path, :final sizeKb) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đã tải lên $path · $sizeKb KB', style: context.text.bodySm.copyWith(color: context.status.success)),
            const SizedBox(height: AppSpace.s4),
            SelectableText(url, maxLines: 3, style: context.text.bodySm.copyWith(color: context.colors.primary)),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                AppToast.show(context, 'Đã chép link');
              },
              icon: Icon(Icons.link, size: AppSize.icon20, color: context.colors.primary),
              label: Text('Chép link', style: context.text.label.copyWith(color: context.colors.primary)),
            ),
          ]),
        ExportFailed(:final message) => Text(message, style: context.text.bodySm.copyWith(color: context.status.danger)),
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.group),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: context.text.section),
          const SizedBox(height: AppSpace.s8),
          QaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
        ]),
      );
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
        child: Row(children: [
          Expanded(child: Text(k, style: context.text.bodySm)),
          Text(v, style: context.text.label.copyWith(color: context.status.fgStrong)),
        ]),
      );
}

// ---------------- Trung tâm thông báo ----------------

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationsViewModelProvider);
    final vm = ref.read(notificationsViewModelProvider.notifier);
    return Scaffold(
      appBar: QaAppBar.nested(
        title: 'Thông báo',
        icon: Icons.notifications_rounded,
        actions: [AppIconButton(icon: Icons.delete_sweep_outlined, tooltip: 'Xóa hết', onPressed: vm.clear)],
      ),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message),
        Empty() => const ScreenBody(children: [EmptyState(message: 'Trống', icon: Icons.notifications_none_rounded)]),
        Ready(:final data) => ScreenBody(children: [
            for (final n in data) ...[
              SessionRow(
                title: n.title,
                subtitle: '${n.body}\n${VnDate.dm(n.receivedAt)} ${VnDate.hm(n.receivedAt)} · ${_state(n.appState)}',
                onTap: n.route == null ? null : () => context.push(n.route!),
                trailing: n.route == null ? null : const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
          ]),
      },
    );
  }

  static String _state(String s) => switch (s) {
        'foreground' => 'app đang mở',
        'background' => 'app chạy nền',
        'terminated' => 'app đã tắt',
        _ => s,
      };
}
