import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../utils/app_exception.dart';
import '../utils/streams.dart';

/// Dữ liệu thời gian thực của một giảng viên, dùng chung cho các ViewModel tab
/// để chỉ mở một bộ listener Firestore.
class LecturerFeed {
  const LecturerFeed({
    required this.user,
    required this.classes,
    required this.slots,
    required this.records,
    required this.pending,
  });

  final AppUser user;
  final List<SchoolClass> classes;
  final List<Slot> slots;
  final List<AttendanceRecord> records;
  final List<CorrectionRequest> pending;

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
  ]).map((v) => LecturerFeed(
        user: user,
        classes: v[0]! as List<SchoolClass>,
        slots: v[1]! as List<Slot>,
        records: v[2]! as List<AttendanceRecord>,
        pending: v[3]! as List<CorrectionRequest>,
      ));
});

/// AsyncValue → ViewState, dùng trong build() của ViewModel.
ViewState<T> viewStateOf<S, T>(AsyncValue<S> v, T Function(S data) map) {
  return v.when(
    data: (d) => Ready(map(d)),
    error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
    loading: () => const Loading(),
  );
}
