import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendo_core/config/app_config.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/firebase/analytics_service.dart';
import 'package:attendo_core/services/auth_service.dart';
import 'package:attendo_core/services/user_repository.dart';

import '../firebase/crash_service.dart';
import '../providers.dart';
import 'package:attendo_core/utils/app_exception.dart';

/// State chung cho form: đang gửi, lỗi theo ô, lỗi chung, đã xong.
class AuthFormState {
  const AuthFormState({this.busy = false, this.busyGoogle = false, this.error, this.fieldErrors = const {}, this.done = false, this.info});

  final bool busy;
  final bool busyGoogle;
  final String? error;
  final Map<String, String> fieldErrors;
  final bool done;

  /// Câu thông báo ngắn (toast), ví dụ “Đã hủy đăng nhập”.
  final String? info;

  AuthFormState copyWith({bool? busy, bool? busyGoogle, String? error, Map<String, String>? fieldErrors, bool? done, String? info}) =>
      AuthFormState(
        busy: busy ?? this.busy,
        busyGoogle: busyGoogle ?? this.busyGoogle,
        error: error,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        done: done ?? this.done,
        info: info,
      );
}

String? validateEmail(String email, UserRole role) {
  final e = email.trim();
  if (e.isEmpty) return 'Nhập email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) return 'Email chưa đúng';
  final domain = role == UserRole.lecturer ? AppConfig.lecturerDomain : AppConfig.studentDomain;
  if (domain.isNotEmpty && !e.toLowerCase().endsWith('@$domain')) return 'Dùng email @$domain';
  return null;
}

/// Câu báo khi tài khoản thuộc vai trò khác với cổng đang mở (màn chặn, màn đăng ký).
String roleMismatchMessage(UserRole actual) => switch (actual) {
      UserRole.student => 'Đây là tài khoản sinh viên, hãy dùng web Attendo',
      UserRole.lecturer => 'Đây là tài khoản giảng viên, hãy dùng app Attendo',
      UserRole.staff || UserRole.admin => 'Đây là tài khoản giáo vụ, hãy dùng trang quản trị',
      UserRole.user => 'Tài khoản chưa có vai trò, hãy liên hệ giáo vụ',
    };

// ---------------- GV-090 / SV-090 Đăng nhập ----------------

final loginViewModelProvider = NotifierProvider.autoDispose<LoginViewModel, AuthFormState>(LoginViewModel.new);

class LoginViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  Future<void> signIn(String email, String password) async {
    final fe = <String, String>{};
    if (email.trim().isEmpty) fe['email'] = 'Nhập email';
    if (password.isEmpty) fe['password'] = 'Nhập mật khẩu';
    if (fe.isNotEmpty) {
      state = state.copyWith(fieldErrors: fe);
      return;
    }
    state = const AuthFormState(busy: true);
    final deps = _SignInDeps(ref);
    try {
      final s = await deps.auth.signInWithEmail(email, password);
      await _afterSignIn(deps, s.uid, 'password');
    } on AppException catch (e) {
      if (!ref.mounted) return;
      // GV-090 .X: lỗi nằm dưới ô mật khẩu.
      state = e.kind == AppErrorKind.auth
          ? AuthFormState(fieldErrors: {'password': e.message})
          : AuthFormState(error: e.message);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthFormState(busyGoogle: true);
    final deps = _SignInDeps(ref);
    try {
      final s = await deps.auth.signInWithGoogle();
      final existing = await deps.users.get(s.uid);
      if (existing == null && AppConfig.portal == UserRole.lecturer) {
        // Đăng nhập Google lần đầu: tạo hồ sơ giảng viên, router đưa tới GV-093.
        await deps.users.create(AppUser(uid: s.uid, role: UserRole.lecturer, displayName: s.displayName, email: s.email));
        await deps.analytics.signUp('google', UserRole.lecturer.name);
      }
      // Sinh viên chưa có hồ sơ: router đưa tới /signup để điền MSSV.
      await _afterSignIn(deps, s.uid, 'google');
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = e.kind == AppErrorKind.cancelled ? const AuthFormState(info: 'Đã hủy đăng nhập') : AuthFormState(error: e.message);
    }
  }

  Future<void> _afterSignIn(_SignInDeps deps, String uid, String method) async {
    final user = await deps.users.get(uid);
    // Sai vai trò: router đưa tới màn chặn, nơi nói rõ đây là tài khoản gì và có nút Đăng xuất.
    if (user != null && user.role != AppConfig.portal) return;
    await deps.analytics.login(method);
    await deps.analytics.setUser(uid, role: user?.role.name);
    await deps.crash.setUser(uid, role: user?.role.name);
    if (ref.mounted) state = const AuthFormState(done: true);
  }
}

/// Service đọc một lần trước lần `await` đầu tiên. Đăng nhập xong thì router có thể rời màn ngay,
/// view model autoDispose bị huỷ và `ref.read` sau đó ném lỗi, nên bước kiểm vai trò và đăng xuất
/// không bao giờ chạy (người dùng kẹt ở màn chặn).
class _SignInDeps {
  _SignInDeps(Ref ref)
      : auth = ref.read(authServiceProvider),
        users = ref.read(userRepositoryProvider),
        analytics = ref.read(analyticsServiceProvider),
        crash = ref.read(crashServiceProvider);

  final AuthService auth;
  final UserRepository users;
  final AnalyticsService analytics;
  final CrashService crash;
}

// ---------------- GV-091 / SV-091 Đăng ký ----------------

final signUpViewModelProvider = NotifierProvider.autoDispose<SignUpViewModel, AuthFormState>(SignUpViewModel.new);

class SignUpViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  UserRole get role => AppConfig.portal;

  Map<String, String> _validate(String name, String code, String email, String? password) {
    final fe = <String, String>{};
    if (name.trim().length < 2) fe['name'] = 'Nhập họ tên';
    if (role == UserRole.student && !RegExp(r'^[A-Za-z]{2}\d{6}$').hasMatch(code.trim())) {
      fe['code'] = 'MSSV dạng SE190601';
    }
    final ee = validateEmail(email, role);
    if (ee != null) fe['email'] = ee;
    if (password != null && password.length < 6) fe['password'] = 'Ít nhất 6 ký tự';
    return fe;
  }

  Future<void> signUp({required String name, required String code, required String email, required String password}) async {
    final fe = _validate(name, code, email, password);
    if (fe.isNotEmpty) {
      state = AuthFormState(fieldErrors: fe);
      return;
    }
    state = const AuthFormState(busy: true);
    try {
      final s = await ref.read(authServiceProvider).signUp(email: email, password: password, displayName: name);
      await ref.read(userRepositoryProvider).create(AppUser(
            uid: s.uid,
            role: role,
            displayName: name.trim(),
            email: email.trim(),
            studentCode: role == UserRole.student ? code.trim().toUpperCase() : null,
          ));
      await ref.read(analyticsServiceProvider).signUp('password', role.name);
      await ref.read(analyticsServiceProvider).setUser(s.uid, role: role.name);
      if (ref.mounted) state = const AuthFormState(done: true);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = e.message.contains('Email') ? AuthFormState(fieldErrors: {'email': e.message}) : AuthFormState(error: e.message);
    }
  }

  /// Đăng ký với Google (sinh viên cần MSSV đã nhập ở ô trên).
  Future<void> signUpWithGoogle({required String code}) async {
    if (role == UserRole.student && !RegExp(r'^[A-Za-z]{2}\d{6}$').hasMatch(code.trim())) {
      state = const AuthFormState(fieldErrors: {'code': 'Nhập MSSV trước khi dùng Google'});
      return;
    }
    state = const AuthFormState(busyGoogle: true);
    try {
      final s = await ref.read(authServiceProvider).signInWithGoogle();
      await completeProfile(uid: s.uid, name: s.displayName, email: s.email, code: code);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = e.kind == AppErrorKind.cancelled ? const AuthFormState(info: 'Đã hủy đăng ký') : AuthFormState(error: e.message);
    }
  }

  /// /signup?complete=1: tài khoản Google đã đăng nhập nhưng chưa có hồ sơ.
  Future<void> completeCurrent({required String code}) async {
    final auth = ref.read(authServiceProvider);
    if (role == UserRole.student && !RegExp(r'^[A-Za-z]{2}\d{6}$').hasMatch(code.trim())) {
      state = const AuthFormState(fieldErrors: {'code': 'MSSV dạng SE190601'});
      return;
    }
    state = const AuthFormState(busy: true);
    try {
      await completeProfile(uid: auth.currentUid ?? '', name: '', email: auth.currentEmail ?? '', code: code);
    } on AppException catch (e) {
      if (ref.mounted) state = AuthFormState(error: e.message);
    }
  }

  Future<void> useAnotherAccount() => ref.read(authServiceProvider).signOut();

  /// Tạo hồ sơ Firestore cho tài khoản đã đăng nhập nhưng chưa có hồ sơ.
  Future<void> completeProfile({required String uid, required String name, required String email, required String code}) async {
    final users = ref.read(userRepositoryProvider);
    final existing = await users.get(uid);
    if (existing != null) {
      if (existing.role != role) {
        await ref.read(authServiceProvider).signOut();
        if (ref.mounted) state = AuthFormState(error: roleMismatchMessage(existing.role));
        return;
      }
    } else {
      await users.create(AppUser(
        uid: uid,
        role: role,
        displayName: name.trim().isEmpty ? email.split('@').first : name.trim(),
        email: email,
        studentCode: role == UserRole.student ? code.trim().toUpperCase() : null,
      ));
      await ref.read(analyticsServiceProvider).signUp('google', role.name);
    }
    await ref.read(analyticsServiceProvider).setUser(uid, role: role.name);
    if (ref.mounted) state = const AuthFormState(done: true);
  }
}

// ---------------- GV-092 Xác nhận email ----------------

final verifyEmailViewModelProvider =
    NotifierProvider.autoDispose<VerifyEmailViewModel, AuthFormState>(VerifyEmailViewModel.new);

class VerifyEmailViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  String get email => ref.read(authServiceProvider).currentEmail ?? '';

  Future<void> check() async {
    state = const AuthFormState(busy: true);
    try {
      final ok = await ref.read(authServiceProvider).reloadVerified();
      if (!ref.mounted) return;
      // Router tự đi tiếp khi emailVerified đổi; ép đọc lại hồ sơ để router chạy redirect.
      if (ok) ref.invalidate(authUidProvider);
      state = ok ? const AuthFormState(done: true) : const AuthFormState(error: 'Chưa xác nhận, hãy mở link trong email');
    } on AppException catch (e) {
      if (ref.mounted) state = AuthFormState(error: e.message);
    }
  }

  Future<void> resend() async {
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (ref.mounted) state = const AuthFormState(info: 'Đã gửi lại email');
    } on AppException catch (e) {
      if (ref.mounted) state = AuthFormState(error: e.message);
    }
  }

  Future<void> wrongEmail() => ref.read(authServiceProvider).signOut();
}

// ---------------- GV-094 Quên mật khẩu ----------------

final forgotPasswordViewModelProvider =
    NotifierProvider.autoDispose<ForgotPasswordViewModel, AuthFormState>(ForgotPasswordViewModel.new);

class ForgotPasswordViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  String sentTo = '';

  Future<void> send(String email) async {
    final ee = validateEmail(email, AppConfig.portal);
    if (ee != null) {
      state = AuthFormState(fieldErrors: {'email': ee});
      return;
    }
    state = const AuthFormState(busy: true);
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      sentTo = email.trim();
      if (ref.mounted) state = const AuthFormState(done: true);
    } on AppException catch (e) {
      if (ref.mounted) state = AuthFormState(error: e.message);
    }
  }
}
