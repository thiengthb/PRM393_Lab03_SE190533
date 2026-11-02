import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/providers.dart';

import 'screens/announcements_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/review_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/users_screen.dart';
import 'widgets/admin_shell.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authUidProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}

/// Điều hướng theo đăng nhập và vai trò (hàm thuần, có test).
/// Chưa đăng nhập → /login. Không phải giáo vụ → /denied. Giáo vụ không vào được /users.
String? resolveAdminRedirect({
  required String location,
  required AsyncValue<String?> uid,
  required AsyncValue<AppUser?> user,
}) {
  if (uid.isLoading && !uid.hasValue) return location == '/splash' ? null : '/splash';
  if (uid.value == null) return location == '/login' ? null : '/login';
  if (user.hasError) return location == '/denied' ? null : '/denied';
  if (!user.hasValue) return location == '/splash' ? null : '/splash';
  final u = user.value;
  if (u == null || !u.role.isStaff) return location == '/denied' ? null : '/denied';
  if (const {'/login', '/denied', '/splash'}.contains(location)) return '/dashboard';
  if (location == '/users' && u.role != UserRole.admin) return '/dashboard';
  return null;
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => resolveAdminRedirect(
      location: state.matchedLocation,
      uid: ref.read(authUidProvider),
      user: ref.read(currentUserProvider),
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const AdminSplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const AdminLoginScreen()),
      GoRoute(path: '/denied', builder: (_, _) => const AdminDeniedScreen()),
      ShellRoute(
        builder: (_, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (_, _) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: '/review', pageBuilder: (_, _) => const NoTransitionPage(child: ReviewScreen())),
          GoRoute(path: '/subjects', pageBuilder: (_, _) => const NoTransitionPage(child: SubjectsScreen())),
          GoRoute(path: '/announcements', pageBuilder: (_, _) => const NoTransitionPage(child: AnnouncementsScreen())),
          GoRoute(path: '/users', pageBuilder: (_, _) => const NoTransitionPage(child: UsersScreen())),
        ],
      ),
    ],
  );
});
