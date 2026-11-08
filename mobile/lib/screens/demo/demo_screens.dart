import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/config/app_config.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/classes_viewmodels.dart';
import 'package:attendo_core/widgets/widgets.dart';

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
      appBar: const QaAppBar.nested(title: 'Khu demo', icon: LucideIcons.flaskConical),
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
            icon: LucideIcons.bell,
            size: AppButtonSize.medium,
            trailingArrow: true,
            onPressed: () => context.push('/notifications'),
          ),
        ]),
        if (lecturer)
          _Section(title: 'Xuất báo cáo · Cloudinary', children: [
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
              label: cfg.reportCloudUpload ? 'Xuất PDF và tải lên' : 'Xuất PDF',
              icon: LucideIcons.fileDown,
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
          _KV('ai_reminder_enabled', cfg.aiReminderEnabled ? 'Bật' : 'Tắt'),
          _KV('ai_model', cfg.aiModel),
          _KV('report_cloud_upload', cfg.reportCloudUpload ? 'Bật' : 'Tắt'),
          _KV('Nguồn', cfg.source),
          if (cfg.fetchedAt != null && cfg.fetchedAt!.year > 1970)
            _KV('Lần tải', '${VnDate.dm(cfg.fetchedAt!)} ${VnDate.hm(cfg.fetchedAt!)}'),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            label: 'Tải lại',
            icon: LucideIcons.refreshCw,
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
                  if (ok) await vm.crash();
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
        ExportDone(:final path, :final sizeKb, :final url) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              url == null
                  ? 'Đã lưu trên máy và ghi vào Firestore reports · $path · $sizeKb KB'
                  : 'Đã tải lên Cloudinary, lưu trên máy và ghi link vào Firestore reports · $sizeKb KB',
              style: context.text.bodySm.copyWith(color: context.status.success),
            ),
            if (url == null)
              Text('Bản build chưa có CLOUDINARY_CLOUD_NAME nên chưa tải lên', style: context.text.bodySm)
            else
              Row(children: [
                Expanded(child: SelectableText(url, style: context.text.bodySm, maxLines: 2)),
                IconButton(
                  tooltip: 'Chép link',
                  icon: const Icon(LucideIcons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) AppToast.show(context, 'Đã chép link');
                  },
                ),
              ]),
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
          QaCard(kind: CardKind.raised, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
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
        icon: LucideIcons.bell,
        actions: [AppIconButton(icon: LucideIcons.trash2, tooltip: 'Xóa hết', onPressed: vm.clear)],
      ),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message),
        Empty() => const ScreenBody(children: [EmptyState(message: 'Trống', icon: LucideIcons.bell)]),
        Ready(:final data) => ScreenBody(children: [
            for (final n in data) ...[
              SessionRow(
                title: n.title,
                subtitle: '${n.body}\n${VnDate.dm(n.receivedAt)} ${VnDate.hm(n.receivedAt)} · ${_state(n.appState)}',
                onTap: n.route == null ? null : () => context.push(n.route!),
                trailing: n.route == null ? null : const Icon(LucideIcons.chevronRight),
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
