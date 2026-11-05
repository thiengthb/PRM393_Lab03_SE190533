import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/providers.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

class AdminAuthState {
  const AdminAuthState({this.busy = false, this.error, this.info});
  final bool busy;
  final String? error;
  final String? info;
}

// Không autoDispose: nút Đăng xuất ở khung trang chỉ đọc notifier trong callback,
// bản autoDispose sẽ bị hủy giữa lúc đang đăng xuất (CR-08).
final adminAuthViewModelProvider = NotifierProvider<AdminAuthViewModel, AdminAuthState>(AdminAuthViewModel.new);

class AdminAuthViewModel extends Notifier<AdminAuthState> {
  @override
  AdminAuthState build() => const AdminAuthState();

  /// Đăng nhập Google. Tài khoản mới được ghi hồ sơ vai trò `user`: router đưa tới /denied,
  /// Admin thấy tài khoản này ở màn Người dùng và cấp quyền.
  Future<void> signInWithGoogle() async {
    state = const AdminAuthState(busy: true);
    try {
      final s = await ref.read(authServiceProvider).signInWithGoogle();
      final users = ref.read(userRepositoryProvider);
      final existing = await users.get(s.uid);
      if (existing == null) {
        await users.create(AppUser(uid: s.uid, role: UserRole.user, displayName: s.displayName, email: s.email));
      }
      await ref.read(analyticsServiceProvider).login('google');
      await ref.read(analyticsServiceProvider).setUser(s.uid, role: existing?.role.name ?? UserRole.user.name);
      if (ref.mounted) state = const AdminAuthState();
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = e.kind == AppErrorKind.cancelled
          ? const AdminAuthState(info: 'Đã hủy đăng nhập')
          : AdminAuthState(error: e.message);
    }
  }

  Future<void> signOut() async {
    await ref.read(analyticsServiceProvider).logout();
    await ref.read(analyticsServiceProvider).setUser(null);
    await ref.read(authServiceProvider).signOut();
  }

  String deniedMessage() {
    final role = ref.read(currentUserProvider).value?.role;
    return switch (role) {
      UserRole.lecturer => 'Đây là tài khoản giảng viên, hãy dùng app Hereby',
      UserRole.student => 'Đây là tài khoản sinh viên, hãy dùng web Hereby',
      UserRole.staff => 'Web admin hiện chỉ mở cho Quản trị',
      _ => 'Tài khoản chưa được cấp quyền quản trị',
    };
  }

  String get currentEmail => ref.read(authServiceProvider).currentEmail ?? '';
  String get currentUid => ref.read(authServiceProvider).currentUid ?? '';
}

/// Vai trò để khung trang biết có hiện mục Người dùng không.
final adminRoleProvider = Provider<UserRole?>((ref) => ref.watch(currentUserProvider).value?.role);
final adminUserProvider = Provider<AppUser?>((ref) => ref.watch(currentUserProvider).value);
