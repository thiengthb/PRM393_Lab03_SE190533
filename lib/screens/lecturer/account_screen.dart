import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/view_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../widgets/widgets.dart';

/// GV-004 Tài khoản (+ .C hộp thoại Đăng xuất, nhóm Firebase D-L3-04).
/// Dùng lại cho tài khoản sinh viên (D-L3-06): ẩn Nhắc nhở và Dữ liệu.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, this.nested = false});

  /// true: mở từ web sinh viên (có nút quay lại).
  final bool nested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(accountViewModelProvider);
    final vm = ref.read(accountViewModelProvider.notifier);
    return Scaffold(
      appBar: nested
          ? const QaAppBar.nested(title: 'Tài khoản')
          : const QaAppBar.top(title: 'Tài khoản', icon: Icons.person_rounded),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 3)]),
        Failure(:final message) => ErrorState(message: message),
        Ready(:final data) => ScreenBody(
            children: [
              Row(children: [
                InitialsAvatar(name: data.displayName, size: 56),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data.displayName, style: context.text.title),
                    Text(
                      data.studentCode == null ? data.email : '${data.studentCode} · ${data.email}',
                      style: context.text.bodySm,
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.group),
              if (data.role == UserRole.lecturer) ...[
                Text('Nhắc nhở', style: context.text.section),
                const SizedBox(height: AppSpace.s8),
                _SwitchCard(title: 'Trước slot', detail: '10 phút', value: data.reminderBeforeSlot, onChanged: vm.setBeforeSlot),
                const SizedBox(height: AppSpace.s8),
                _SwitchCard(title: 'Slot chưa chốt', detail: 'Khi hết giờ', value: data.reminderUnclosed, onChanged: vm.setUnclosed),
                const SizedBox(height: AppSpace.group),
                Text('Dữ liệu', style: context.text.section),
                const SizedBox(height: AppSpace.s8),
                _LinkCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Nhập danh sách lớp',
                  detail: data.lastImportAt == null ? 'Chưa nhập' : 'Lần cuối ${VnDate.dm(data.lastImportAt!)}',
                  onTap: () => context.push('/import'),
                ),
                const SizedBox(height: AppSpace.group),
              ],
              Text('Firebase', style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              _LinkCard(
                icon: Icons.notifications_none_rounded,
                title: 'Thông báo',
                detail: 'Tin FCM đã nhận',
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: AppSpace.s8),
              _LinkCard(
                icon: Icons.science_outlined,
                title: 'Khu demo',
                detail: 'Xuất báo cáo, Remote Config, Crashlytics',
                onTap: () => context.push('/demo'),
              ),
              const SizedBox(height: AppSpace.group),
              AppButton(
                label: 'Đăng xuất',
                icon: Icons.logout_rounded,
                style: AppButtonStyle.outline,
                onPressed: () async {
                  final ok = await AppDialog.confirm(
                    context,
                    title: 'Đăng xuất?',
                    message: data.email,
                    confirmLabel: 'Đăng xuất',
                    destructive: true,
                  );
                  if (ok) await vm.signOut();
                },
              ),
            ],
          ),
      },
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({required this.title, required this.detail, required this.value, required this.onChanged});
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => QaCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.body.copyWith(color: context.status.fgStrong)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          Semantics(label: title, toggled: value, child: Switch(value: value, onChanged: onChanged)),
        ]),
      );
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.title, required this.detail, required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => QaCard(
        onTap: onTap,
        semanticsLabel: title,
        child: Row(children: [
          IconTile(icon: icon, size: 40),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.body.copyWith(color: context.status.fgStrong)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ]),
      );
}
