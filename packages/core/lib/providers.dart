import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase/analytics_service.dart';
import 'firebase/config_service.dart';
import 'models/models.dart';
import 'services/announcement_repository.dart';
import 'services/attendance_aggregator.dart';
import 'services/auth_service.dart';
import 'services/class_repository.dart';
import 'services/dashboard_repository.dart';
import 'services/palette_store.dart';
import 'services/reminder_repository.dart';
import 'services/report_repository.dart';
import 'services/request_repository.dart';
import 'services/slot_repository.dart';
import 'services/student_attendance_repository.dart';
import 'services/subject_repository.dart';
import 'services/tv_repository.dart';
import 'services/user_repository.dart';

/// Nơi duy nhất tạo service dùng chung (DI). Test ghi đè bằng ProviderContainer(overrides: ...).
/// Widget không đọc các provider này trực tiếp; chỉ ViewModel đọc.

final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>((_) => FirebaseAuthService(FirebaseAuth.instance));
final userRepositoryProvider = Provider<UserRepository>((ref) => FirestoreUserRepository(ref.watch(firestoreProvider)));
final classRepositoryProvider = Provider<ClassRepository>((ref) => FirestoreClassRepository(ref.watch(firestoreProvider)));
final slotRepositoryProvider = Provider<SlotRepository>((ref) => FirestoreSlotRepository(ref.watch(firestoreProvider)));
final requestRepositoryProvider =
    Provider<RequestRepository>((ref) => FirestoreRequestRepository(ref.watch(firestoreProvider)));
final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) => FirestoreReminderRepository(ref.watch(firestoreProvider)));
final tvRepositoryProvider = Provider<TvRepository>((ref) => FirestoreTvRepository(ref.watch(firestoreProvider)));
final studentAttendanceRepositoryProvider = Provider<StudentAttendanceRepository>(
    (ref) => FirestoreStudentAttendanceRepository(ref.watch(firestoreProvider)));
final subjectRepositoryProvider =
    Provider<SubjectRepository>((ref) => FirestoreSubjectRepository(ref.watch(firestoreProvider)));
final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) => FirestoreAnnouncementRepository(ref.watch(firestoreProvider)));
final reportRepositoryProvider =
    Provider<ReportRepository>((ref) => FirestoreReportRepository(ref.watch(firestoreProvider)));
final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => FirestoreDashboardRepository(ref.watch(firestoreProvider)));

final aggregatorProvider = Provider<AttendanceAggregator>((_) => const AttendanceAggregator());
final paletteStoreProvider = Provider<PaletteStore>((_) => const PrefsPaletteStore());

final analyticsServiceProvider =
    Provider<AnalyticsService>((_) => FirebaseAnalyticsService(FirebaseAnalytics.instance));

/// Được ghi đè trong main.dart bằng bản đã init().
final configServiceProvider =
    Provider<ConfigService>((_) => FirebaseConfigService(FirebaseRemoteConfig.instance));

/// Hàm lấy giờ hiện tại, test ghi đè để cố định ngày.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

// ---------- Phiên đăng nhập ----------

/// uid đang đăng nhập (null = đã đăng xuất).
final authUidProvider = StreamProvider<String?>((ref) => ref.watch(authServiceProvider).uidChanges());

/// Hồ sơ người dùng hiện tại trong Firestore.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watch(uid);
});

/// Giá trị Remote Config đang dùng (đổi theo thời gian thực).
final remoteConfigProvider = StreamProvider<AppRemoteConfig>((ref) => ref.watch(configServiceProvider).watch());
