import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/auth_viewmodels.dart';
import '../../widgets/brand.dart';
import '../../widgets/widgets.dart';

void _listenInfo(WidgetRef ref, BuildContext context, ProviderListenable<AuthFormState> p) {
  ref.listen(p, (prev, next) {
    if (next.info != null && next.info != prev?.info) AppToast.show(context, next.info!);
  });
}

Widget _errorLine(BuildContext context, String? error) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: AppSpace.s12),
        child: Semantics(
          liveRegion: true,
          child: Text(error, style: context.text.bodySm.copyWith(color: context.status.danger)),
        ),
      );

// ---------------- GV-090 / SV-090 Đăng nhập ----------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);
    _listenInfo(ref, context, loginViewModelProvider);
    final student = AppConfig.portal == UserRole.student;
    return Scaffold(
      body: SafeArea(
        child: ScreenBody(
          maxWidth: 420,
          children: [
            const SizedBox(height: AppSpace.s24),
            const BrandRow(),
            const SizedBox(height: AppSpace.s32),
            AutofillGroup(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Email',
                    hint: student ? 'giahuy@fpt.edu.vn' : 'quanm@fe.edu.vn',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    errorText: s.fieldErrors['email'],
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AppTextField(
                    label: 'Mật khẩu',
                    controller: _password,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    errorText: s.fieldErrors['password'],
                    onSubmitted: (_) => vm.signIn(_email.text, _password.text),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot'),
                style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, AppSize.touch)),
                child: Text('Quên mật khẩu?', style: context.text.label.copyWith(color: context.colors.primary)),
              ),
            ),
            AppButton(
              label: 'Đăng nhập',
              loading: s.busy,
              onPressed: s.busy || s.busyGoogle ? null : () => vm.signIn(_email.text, _password.text),
            ),
            _errorLine(context, s.error),
            const OrDivider(),
            AppButton(
              label: 'Đăng nhập với Google',
              icon: Icons.g_mobiledata_rounded,
              style: AppButtonStyle.outline,
              loading: s.busyGoogle,
              onPressed: s.busy || s.busyGoogle ? null : vm.signInWithGoogle,
            ),
            const SizedBox(height: AppSpace.s16),
            _SwitchLink(text: 'Chưa có tài khoản?', action: 'Đăng ký', onTap: () => context.go('/signup')),
          ],
        ),
      ),
    );
  }
}

class _SwitchLink extends StatelessWidget {
  const _SwitchLink({required this.text, required this.action, required this.onTap});
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: context.text.body),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, AppSize.touch)),
            child: Text(action, style: context.text.label.copyWith(color: context.colors.primary)),
          ),
        ],
      );
}

// ---------------- GV-091 / SV-091 Đăng ký ----------------

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.complete = false});

  /// true: đã đăng nhập (Google) nhưng chưa có hồ sơ → chỉ điền thông tin còn thiếu.
  final bool complete;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _code, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(signUpViewModelProvider);
    final vm = ref.read(signUpViewModelProvider.notifier);
    _listenInfo(ref, context, signUpViewModelProvider);
    final student = vm.role == UserRole.student;
    final busy = s.busy || s.busyGoogle;
    return Scaffold(
      body: SafeArea(
        child: ScreenBody(
          maxWidth: 420,
          children: [
            const SizedBox(height: AppSpace.s24),
            const BrandRow(),
            const SizedBox(height: AppSpace.s32),
            if (!widget.complete || student) ...[
              if (!widget.complete) ...[
                AppTextField(
                  label: 'Họ tên',
                  hint: student ? 'Lê Gia Huy' : 'Nguyễn Minh Quân',
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  errorText: s.fieldErrors['name'],
                ),
                const SizedBox(height: AppSpace.s16),
              ],
              if (student) ...[
                AppTextField(
                  label: 'MSSV',
                  hint: 'SE190601',
                  controller: _code,
                  textInputAction: TextInputAction.next,
                  errorText: s.fieldErrors['code'],
                ),
                const SizedBox(height: AppSpace.s16),
              ],
            ],
            if (!widget.complete) ...[
              AppTextField(
                label: 'Email',
                hint: student ? 'giahuy@fpt.edu.vn' : 'quanm@fe.edu.vn',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: s.fieldErrors['email'],
              ),
              const SizedBox(height: AppSpace.s16),
              AppTextField(
                label: 'Mật khẩu',
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                errorText: s.fieldErrors['password'],
              ),
              const SizedBox(height: AppSpace.s24),
            ],
            AppButton(
              label: 'Tạo tài khoản',
              loading: s.busy,
              onPressed: busy
                  ? null
                  : () => widget.complete
                      ? vm.completeCurrent(code: _code.text)
                      : vm.signUp(name: _name.text, code: _code.text, email: _email.text, password: _password.text),
            ),
            _errorLine(context, s.error),
            if (!widget.complete) ...[
              const OrDivider(),
              AppButton(
                label: 'Đăng ký với Google',
                icon: Icons.g_mobiledata_rounded,
                style: AppButtonStyle.outline,
                loading: s.busyGoogle,
                onPressed: busy ? null : () => vm.signUpWithGoogle(code: _code.text),
              ),
              const SizedBox(height: AppSpace.s16),
              _SwitchLink(text: 'Đã có tài khoản?', action: 'Đăng nhập', onTap: () => context.go('/login')),
            ] else
              TextButton(
                onPressed: vm.useAnotherAccount,
                child: Text('Dùng tài khoản khác', style: context.text.label.copyWith(color: context.colors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- GV-092 Xác nhận email (D-L3-02) ----------------

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(verifyEmailViewModelProvider);
    final vm = ref.read(verifyEmailViewModelProvider.notifier);
    _listenInfo(ref, context, verifyEmailViewModelProvider);
    return Scaffold(
      body: SafeArea(
        child: ScreenBody(
          maxWidth: 420,
          children: [
            const SizedBox(height: AppSpace.s24),
            Text('Xác nhận email', style: context.text.titleLg),
            const SizedBox(height: AppSpace.s8),
            Text('Link xác nhận đã gửi tới ${vm.email}', style: context.text.body),
            const SizedBox(height: AppSpace.s24),
            IconTile(icon: Icons.mark_email_unread_outlined, background: context.colors.primaryContainer, color: context.colors.primary),
            const SizedBox(height: AppSpace.s24),
            AppButton(label: 'Xác nhận', icon: Icons.check, loading: s.busy, onPressed: s.busy ? null : vm.check),
            _errorLine(context, s.error),
            const SizedBox(height: AppSpace.s8),
            Center(
              child: TextButton(
                onPressed: vm.resend,
                style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, AppSize.touch)),
                child: Text('Gửi lại email', style: context.text.label.copyWith(color: context.colors.primary)),
              ),
            ),
            _SwitchLink(text: 'Sai email?', action: 'Sửa lại', onTap: vm.wrongEmail),
          ],
        ),
      ),
    );
  }
}

// ---------------- GV-093 Bắt đầu ----------------

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(accountViewModelProvider).dataOrNull;
    final steps = [
      ('B1', 'Nhập danh sách lớp', 'Chọn file Excel hoặc CSV phòng đào tạo gửi'),
      ('B2', 'App tự xếp lịch dạy', 'Lịch lấy từ thời khóa biểu trong file'),
      ('B3', 'Điểm danh từng slot', 'Sinh viên quét mã, thầy bấm chốt'),
    ];
    return Scaffold(
      body: SafeArea(
        child: ScreenBody(
          maxWidth: 480,
          children: [
            const SizedBox(height: AppSpace.s24),
            Text('Chào thầy ${user?.givenName ?? ''}', style: context.text.titleLg),
            const SizedBox(height: AppSpace.s4),
            Text('Làm lần lượt 3 bước để bắt đầu điểm danh', style: context.text.body),
            const SizedBox(height: AppSpace.s24),
            for (final (i, (badge, title, detail)) in steps.indexed) ...[
              QaCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0 ? context.colors.primary : context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        badge,
                        style: context.text.label.copyWith(color: i == 0 ? context.colors.onPrimary : context.colors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
                          Text(detail, style: context.text.bodySm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s12),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(label: 'Nhập lớp ngay', trailingArrow: true, onPressed: () => context.go('/import')),
              TextButton(
                onPressed: () => context.go('/overview'),
                style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, AppSize.touch)),
                child: Text('Để sau', style: context.text.label.copyWith(color: context.colors.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- GV-094 Quên mật khẩu ----------------

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(forgotPasswordViewModelProvider);
    final vm = ref.read(forgotPasswordViewModelProvider.notifier);
    if (s.done) {
      // GV-094 .S
      return Scaffold(
        body: SafeArea(
          child: ScreenBody(
            maxWidth: 420,
            children: [
              const SizedBox(height: AppSpace.s32 + AppSpace.s16),
              Center(child: IconTile(icon: Icons.mark_email_read_outlined, background: context.status.successSoft, color: context.status.success)),
              const SizedBox(height: AppSpace.s16),
              Text('Đã gửi link', style: context.text.titleLg, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s4),
              Text('Kiểm tra hộp thư ${vm.sentTo}', style: context.text.body, textAlign: TextAlign.center),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton(label: 'Về đăng nhập', onPressed: () => context.go('/login')),
        ]),
      );
    }
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Quên mật khẩu'),
      body: SafeArea(
        child: ScreenBody(
          maxWidth: 420,
          children: [
            Text('Nhập email để nhận link đặt lại mật khẩu', style: context.text.body),
            const SizedBox(height: AppSpace.s16),
            AppTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              errorText: s.fieldErrors['email'],
              onSubmitted: (_) => vm.send(_email.text),
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(label: 'Gửi link đặt lại', icon: Icons.send_outlined, loading: s.busy, onPressed: s.busy ? null : () => vm.send(_email.text)),
            _errorLine(context, s.error),
            const SizedBox(height: AppSpace.s8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Quay lại đăng nhập', style: context.text.label.copyWith(color: context.colors.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đang tải phiên đăng nhập.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: BrandMark(size: 56)),
      );
}

/// Tài khoản sai vai trò hoặc lỗi tải hồ sơ.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: EmptyState(
            boxed: false,
            icon: Icons.block_outlined,
            message: message,
            actionLabel: 'Đăng xuất',
            onAction: () => ref.read(accountViewModelProvider.notifier).signOut(),
          ),
        ),
      );
}
