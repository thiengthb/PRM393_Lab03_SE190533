import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import '../providers.dart';
import 'package:quick_attend_core/utils/app_exception.dart';
import 'package:quick_attend_core/utils/streams.dart';

/// Dữ liệu thời gian thực của một giảng viên, dùng chung cho các ViewModel tab
/// để chỉ mở một bộ listener Firestore.
class LecturerFeed {
  const LecturerFeed({
    required this.user,
    required this.classes,
    required this.slots,
    required this.records,
    required this.pending,
    this.inReview = const [],
  });

  final AppUser user;
  final List<SchoolClass> classes;
  final List<Slot> slots;
  final List<AttendanceRecord> records;
  final List<CorrectionRequest> pending;

  /// Lớp chưa được giáo vụ duyệt hoặc bị từ chối (đề Final: luồng liên vai trò).
  final List<SchoolClass> inReview;

  List<SchoolClass> classesOf(String term) => classes.where((c) => c.term == term).toList();
}

final lecturerFeedProvider = StreamProvider<LecturerFeed>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.role != UserRole.lecturer) {
    return const Stream<LecturerFeed>.empty();
  }
  final uid = user.uid;
  return combineLatest([
    ref.watch(classRepositoryProvider).watchClasses(uid),
    ref.watch(slotRepositoryProvider).watchSlots(uid),
    ref.watch(slotRepositoryProvider).watchLecturerRecords(uid),
    ref.watch(requestRepositoryProvider).watchPending(uid),
  ]).map((v) {
    final all = v[0]! as List<SchoolClass>;
    final approved = {for (final c in all) if (c.isApproved) c.id};
    return LecturerFeed(
      user: user,
      classes: all.where((c) => c.isApproved).toList(),
      inReview: all.where((c) => !c.isApproved).toList(),
      // Slot của lớp chưa duyệt chưa được điểm danh (Rules cũng chặn).
      slots: (v[1]! as List<Slot>).where((s) => approved.contains(s.classId)).toList(),
      records: v[2]! as List<AttendanceRecord>,
      pending: v[3]! as List<CorrectionRequest>,
    );
  });
});

/// AsyncValue → ViewState, dùng trong build() của ViewModel.
ViewState<T> viewStateOf<S, T>(AsyncValue<S> v, T Function(S data) map) {
  return v.when(
    data: (d) => Ready(map(d)),
    error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
    loading: () => const Loading(),
  );
}

/// GV-001 .X: lịch đang lấy từ bộ nhớ đệm. [lastSync] là lần cuối dữ liệu khớp máy chủ
/// trong phiên này, null nếu mở app khi đã mất mạng.
class OfflineInfo {
  const OfflineInfo(this.lastSync);
  final DateTime? lastSync;
}

/// Thời gian chờ trước khi báo mất mạng; test đặt bằng 0.
final offlineGraceProvider = Provider<Duration>((_) => const Duration(seconds: 4));

final lecturerOfflineViewModelProvider =
    NotifierProvider.autoDispose<LecturerOfflineViewModel, OfflineInfo?>(LecturerOfflineViewModel.new);

/// Theo dõi isFromCache của lịch giảng viên. Chỉ báo mất mạng khi trạng thái đệm kéo dài
/// quá [offlineGraceProvider], vì lúc mở app Firestore thường trả bản đệm trước rồi mới tới bản máy chủ.
class LecturerOfflineViewModel extends Notifier<OfflineInfo?> {
  DateTime? _lastSync;
  Timer? _timer;

  @override
  OfflineInfo? build() {
    final user = ref.watch(currentUserProvider).value;
    if (user == null || user.role != UserRole.lecturer) return null;
    final sub = ref.watch(slotRepositoryProvider).watchFromCache(user.uid).listen(_onCache, onError: (_) {});
    ref.onDispose(() {
      sub.cancel();
      _timer?.cancel();
    });
    return null;
  }

  void _onCache(bool fromCache) {
    _timer?.cancel();
    if (!fromCache) {
      _lastSync = ref.read(clockProvider)();
      state = null;
      return;
    }
    _timer = Timer(ref.read(offlineGraceProvider), () => state = OfflineInfo(_lastSync));
  }

  /// Nút Thử lại: mở lại listener, Firestore tự nối lại khi có mạng.
  void retry() {
    ref.invalidate(lecturerFeedProvider);
    ref.invalidateSelf();
  }
}
