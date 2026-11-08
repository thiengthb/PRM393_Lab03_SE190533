import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/crash_report.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/crashes_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Chỉ Admin: bản tóm tắt sự cố app gửi lên (test crash, lỗi non-fatal, lỗi giao diện).
/// Stack đầy đủ nằm ở Crashlytics console; Crashlytics không có API cho web.
class CrashesScreen extends ConsumerWidget {
  const CrashesScreen({super.key});

  static IconData _icon(CrashKind k) => switch (k) {
        CrashKind.testCrash => Icons.dangerous_outlined,
        CrashKind.nonFatal => Icons.report_outlined,
        CrashKind.flutterError => Icons.broken_image_outlined,
      };

  static String _role(String r) => UserRole.values.where((x) => x.name == r).firstOrNull?.label ?? r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(crashesViewModelProvider);
    final vm = ref.read(crashesViewModelProvider.notifier);
    return AdminPage(
      title: 'Sự cố',
      icon: Icons.bug_report_rounded,
      actions: [
        AppIconButton(
          icon: Icons.copy_rounded,
          tooltip: 'Chép link Crashlytics console (stack đầy đủ)',
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: crashlyticsConsoleUrl));
            if (context.mounted) AppToast.show(context, 'Đã chép link Crashlytics');
          },
        ),
      ],
      children: [
        LayoutBuilder(builder: (context, c) {
          final perRow = c.maxWidth >= 720 ? 3 : 1;
          final w = (c.maxWidth - AppSpace.s12 * (perRow - 1)) / perRow;
          return Wrap(spacing: AppSpace.s12, runSpacing: AppSpace.s12, children: [
            for (final k in CrashKind.values)
              SizedBox(
                width: w,
                child: StatTile(
                  value: s.items is Loading ? null : '${s.counts[k] ?? 0}',
                  label: s.kind == k ? '${k.label} · đang lọc' : k.label,
                  icon: _icon(k),
                  onTap: () => vm.setKind(k),
                ),
              ),
          ]);
        }),
        const SizedBox(height: AppSpace.group),
        ...switch (s.items) {
          Loading() => const <Widget>[SkeletonList()],
          Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
          Empty() => const <Widget>[EmptyState(message: 'Chưa có sự cố', icon: Icons.verified_outlined)],
          Ready(:final data) => <Widget>[
              for (final r in data) ...[
                SessionRow(
                  title: '${r.kind.label} · ${r.where}',
                  subtitle: [
                    if (r.createdAt != null) '${VnDate.hm(r.createdAt!)} ${VnDate.dm(r.createdAt!)}',
                    _role(r.role),
                    r.platform,
                  ].join(' · ') +
                      (r.message.isEmpty ? '' : '\n${r.message}'),
                  trailing: Icon(_icon(r.kind), color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
        },
      ],
    );
  }
}
