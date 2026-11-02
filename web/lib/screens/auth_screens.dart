import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/brand.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/admin_auth_viewmodel.dart';

class AdminSplashScreen extends StatelessWidget {
  const AdminSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Đăng nhập Google, chỉ giáo vụ và quản trị đi tiếp.
class AdminLoginScreen extends ConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminAuthViewModelProvider);
    ref.listen(adminAuthViewModelProvider.select((x) => x.info), (prev, next) {
      if (next != null && next != prev) AppToast.show(context, next);
    });
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const BrandRow(),
              const SizedBox(height: AppSpace.s8),
              Text('Trang quản trị', style: context.text.titleLg),
              const SizedBox(height: AppSpace.s24),
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
            ]),
          ),
        ),
      ),
    );
  }
}

/// Tài khoản không phải giáo vụ: nói rõ lý do, cho UID để Admin cấp quyền.
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
