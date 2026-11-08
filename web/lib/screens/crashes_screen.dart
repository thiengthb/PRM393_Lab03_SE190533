import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/crash_report.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';

import '../viewmodels/crashes_viewmodel.dart';

/// Chỉ Admin: bản tóm tắt sự cố app gửi lên (test crash, lỗi non-fatal, lỗi giao diện).
/// Stack đầy đủ nằm ở Crashlytics console; Crashlytics không có API cho web.
class CrashesScreen extends ConsumerStatefulWidget {
  const CrashesScreen({super.key});

  static IconData icon(CrashKind k) => switch (k) {
        CrashKind.testCrash => LucideIcons.octagonX,
        CrashKind.nonFatal => LucideIcons.octagonAlert,
        CrashKind.flutterError => LucideIcons.imageOff,
      };

  static String role(String r) => UserRole.values.where((x) => x.name == r).firstOrNull?.label ?? r;

  @override
  ConsumerState<CrashesScreen> createState() => _CrashesScreenState();
}

class _CrashesScreenState extends ConsumerState<CrashesScreen> {
  String? _selected;

  Future<void> _copyConsole() async {
    await Clipboard.setData(const ClipboardData(text: crashlyticsConsoleUrl));
    if (mounted) AppToast.show(context, 'Đã chép link Crashlytics');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(crashesViewModelProvider);
    final vm = ref.read(crashesViewModelProvider.notifier);
    final rows = s.items.dataOrNull ?? const <CrashReport>[];
    final sel = rows.where((r) => r.id == _selected).firstOrNull;
    String when(DateTime? t) => t == null ? '–' : '${VnDate.dm(t)} ${VnDate.hm(t)}';
    return DeskPage(
      title: 'Sự cố',
      subtitle: 'Tóm tắt app gửi lên; stack đầy đủ ở Crashlytics console',
      actions: [
        AppButton(label: 'Chép link Crashlytics', icon: LucideIcons.copy, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: _copyConsole),
      ],
      side: sel == null
          ? null
          : DeskSidePanel(
              title: sel.kind.label,
              subtitle: when(sel.createdAt),
              onClose: () => setState(() => _selected = null),
              footer: AppButton(label: 'Chép link Crashlytics', icon: LucideIcons.copy, style: AppButtonStyle.outline, size: AppButtonSize.medium, onPressed: _copyConsole),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DeskFacts([
                  ('Nơi xảy ra', sel.where),
                  ('Vai trò', CrashesScreen.role(sel.role)),
                  ('Nền tảng', sel.platform),
                  ('Mã người dùng', sel.uid),
                ]),
                const SizedBox(height: AppSpace.s12),
                Text('Thông điệp', style: context.text.section),
                const SizedBox(height: AppSpace.s4),
                SelectableText(sel.message.isEmpty ? '–' : sel.message, style: context.text.bodySm.copyWith(color: context.status.fgStrong)),
              ]),
            ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (final k in CrashKind.values) ...[
            if (k != CrashKind.values.first) const SizedBox(width: AppSpace.s12),
            Expanded(
              child: StatTile(
                value: s.items is Loading ? null : '${s.counts[k] ?? 0}',
                label: s.kind == k ? '${k.label} · đang lọc' : k.label,
                icon: CrashesScreen.icon(k),
                onTap: () => vm.setKind(k),
              ),
            ),
          ],
        ]),
        const SizedBox(height: AppSpace.s16),
        Expanded(
          child: DeskCard(
            title: 'Sự cố gần đây',
            count: rows.length,
            expand: true,
            child: switch (s.items) {
              Loading() => const Padding(padding: EdgeInsets.all(AppSpace.s16), child: SkeletonList(count: 6, height: 40)),
              Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
              Empty() => const EmptyState(message: 'Chưa có sự cố', icon: LucideIcons.badgeCheck, boxed: false),
              Ready(:final data) => DeskTable<CrashReport>(
                  rows: data,
                  isSelected: (r) => r.id == _selected,
                  onTap: (r) => setState(() => _selected = r.id == _selected ? null : r.id),
                  rowLabel: (r) => '${r.kind.label} · ${r.where}',
                  columns: [
                    DeskColumn(label: 'Thời gian', width: 120, sortBy: (r) => r.createdAt ?? DateTime(0), cell: (ctx, r) => Text(when(r.createdAt), style: ctx.text.caption)),
                    DeskColumn(
                      label: 'Loại',
                      width: 170,
                      cell: (ctx, r) => Row(children: [
                        Icon(CrashesScreen.icon(r.kind), size: 14, color: ctx.colors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(child: Text(r.kind.label, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                    DeskColumn(label: 'Nơi xảy ra', flex: 2, cell: (_, r) => Text(r.where, overflow: TextOverflow.ellipsis)),
                    DeskColumn(label: 'Thông điệp', flex: 3, cell: (ctx, r) => Text(r.message.replaceAll('\n', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: ctx.text.caption)),
                    DeskColumn(label: 'Vai trò', width: 100, cell: (_, r) => Text(CrashesScreen.role(r.role))),
                    DeskColumn(label: 'Nền tảng', width: 90, cell: (ctx, r) => Text(r.platform, style: ctx.text.caption)),
                  ],
                ),
            },
          ),
        ),
      ]),
    );
  }
}
