import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/admin_auth_viewmodel.dart';

class AdminSplashScreen extends StatelessWidget {
  const AdminSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Đăng nhập Google, chỉ Admin đi tiếp (xem webAdminRoles).
class AdminLoginScreen extends ConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminAuthViewModelProvider);
    ref.listen(adminAuthViewModelProvider.select((x) => x.info), (prev, next) {
      if (next != null && next != prev) AppToast.show(context, next);
    });
    return AuthShell(
      title: 'Trang quản trị',
      subtitle: 'Chỉ tài khoản Admin được vào',
      tagline: 'Quản lý lớp, môn học, người dùng và sự cố của cả hệ thống.',
      points: const ['Duyệt lớp giảng viên gửi từ app', 'Gửi thông báo cho cả trường', 'Xem báo cáo sự cố từ app'],
      children: [
        AppButton(
          label: 'Đăng nhập với Google',
          icon: Icons.login_rounded,
          loading: s.busy,
          onPressed: s.busy ? null : ref.read(adminAuthViewModelProvider.notifier).signInWithGoogle,
        ),
        if (s.error != null) ...[
          const SizedBox(height: AppSpace.s12),
          Semantics(
            liveRegion: true,
            child: Text(s.error!, style: context.text.bodySm.copyWith(color: context.status.danger)),
          ),
        ],
      ],
    );
  }
}

/// Tài khoản không được vào web admin: nói rõ lý do, cho UID để Admin cấp quyền.
class AdminDeniedScreen extends ConsumerWidget {
  const AdminDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(adminAuthViewModelProvider.notifier);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: IconTile(icon: Icons.lock_outline_rounded, background: context.status.warningSoft, color: context.status.warning)),
              const SizedBox(height: AppSpace.s16),
              Text(vm.deniedMessage(), style: context.text.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s8),
              SelectableText(vm.currentEmail, style: context.text.body, textAlign: TextAlign.center),
              SelectableText(vm.currentUid, style: context.text.bodySm, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s24),
              AppButton(label: 'Dùng tài khoản khác', style: AppButtonStyle.outline, onPressed: vm.signOut),
            ]),
          ),
        ),
      ),
    );
  }
}
