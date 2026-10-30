import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'models/models.dart';
import 'providers.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/demo/demo_screens.dart';
import 'screens/lecturer/account_screen.dart';
import 'screens/lecturer/classes_screens.dart';
import 'screens/lecturer/import_screen.dart';
import 'screens/lecturer/lecturer_shell.dart';
import 'screens/lecturer/overview_screen.dart';
import 'screens/lecturer/schedule_screen.dart';
import 'screens/lecturer/session_screens.dart';
import 'screens/lecturer/student_screens.dart';
import 'screens/student/student_screens.dart';

/// Báo router chạy lại redirect khi phiên đăng nhập hoặc hồ sơ đổi.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authUidProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}

const _authRoutes = {'/login', '/signup', '/forgot'};
const _transient = {'/splash', '/verify', '/blocked'};

String homeOf(UserRole r) => r == UserRole.student ? '/me' : '/overview';

/// Quy tắc điều hướng theo trạng thái đăng nhập và vai trò (hàm thuần, có test).
String? resolveRedirect({
  required String location,
  required AsyncValue<String?> uid,
  required AsyncValue<AppUser?> user,
  required bool emailVerified,
  required bool googleUser,
  required UserRole portal,
}) {
  if (uid.isLoading && !uid.hasValue) return location == '/splash' ? null : '/splash';
  final id = uid.value;
  if (id == null) return _authRoutes.contains(location) ? null : '/login';
  if (user.hasError) return location == '/blocked' ? null : '/blocked';
  if (!user.hasValue) return location == '/splash' ? null : '/splash';
  final u = user.value;
  if (u == null) {
    // Đã đăng nhập (Google) nhưng chưa có hồ sơ → điền nốt (MSSV với sinh viên).
    return location == '/signup' ? null : '/signup?complete=1';
  }
  if (u.role != portal) return location == '/blocked' ? null : '/blocked';
  if (!emailVerified && !googleUser) return location == '/verify' ? null : '/verify';
  if (_authRoutes.contains(location) || _transient.contains(location)) {
    // Vừa đăng ký xong (GV-091 → GV-092 → GV-093).
    final fromSignUp = location == '/signup' || location == '/verify';
    if (u.role == UserRole.lecturer && fromSignUp && u.lastImportAt == null) return '/start';
    return homeOf(u.role);
  }
  final studentArea = location == '/me' || location.startsWith('/me/');
  const shared = {'/demo', '/notifications'};
  if (u.role == UserRole.lecturer && studentArea) return '/overview';
  if (u.role == UserRole.student && !studentArea && !shared.contains(location)) return '/me';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authServiceProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        uid: ref.read(authUidProvider),
        user: ref.read(currentUserProvider),
        emailVerified: auth.emailVerified,
        googleUser: auth.isGoogleUser,
        portal: AppConfig.portal,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (_, s) => SignUpScreen(complete: s.uri.queryParameters['complete'] == '1'),
      ),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify', builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: '/start', builder: (_, _) => const StartScreen()),
      GoRoute(
        path: '/blocked',
        builder: (_, _) => const BlockedScreen(message: 'Tài khoản không dùng được ở đây'),
      ),

      // App giảng viên: 4 tab (GV-001..004).
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => LecturerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/overview', builder: (_, _) => const OverviewScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/classes', builder: (_, _) => const ClassesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())]),
        ],
      ),
      GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
      GoRoute(path: '/slot/:slotId', builder: (_, s) => SlotDetailScreen(slotId: s.pathParameters['slotId']!)),
      GoRoute(
        path: '/session/:slotId',
        builder: (_, s) => SessionScreen(slotId: s.pathParameters['slotId']!, edit: s.uri.queryParameters['edit'] == '1'),
      ),
      GoRoute(path: '/class/:classId', builder: (_, s) => ClassDetailScreen(classId: s.pathParameters['classId']!)),
      GoRoute(path: '/attention', builder: (_, _) => const AttentionScreen()),
      GoRoute(path: '/requests', builder: (_, _) => const RequestsScreen()),
      GoRoute(
        path: '/student/:classId/:code',
        builder: (_, s) => StudentProfileScreen(classId: s.pathParameters['classId']!, code: s.pathParameters['code']!),
      ),
      GoRoute(path: '/demo', builder: (_, _) => const FirebaseDemoScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),

      // Web sinh viên (SV-001, SV-002, SV-101, SV-102).
      GoRoute(path: '/me', builder: (_, _) => const MyAttendanceScreen()),
      GoRoute(path: '/me/subject/:classId', builder: (_, s) => SubjectDetailScreen(classId: s.pathParameters['classId']!)),
      GoRoute(path: '/me/scan', builder: (_, _) => const ScanScreen()),
      GoRoute(path: '/me/report', builder: (_, s) => ReportScreen(session: s.extra is AttendanceRecord ? s.extra! as AttendanceRecord : null)),
      GoRoute(path: '/me/account', builder: (_, _) => const AccountScreen(nested: true)),
    ],
  );
});
