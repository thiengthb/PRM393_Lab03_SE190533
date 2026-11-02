import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/providers.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

class ReviewState {
  const ReviewState({
    required this.tab,
    required this.items,
    this.activeSubjects = const {},
    this.busyId,
    this.message,
    this.isError = false,
  });
  final ClassStatus tab;
  final ViewState<List<SchoolClass>> items;

  /// Rỗng khi danh mục chưa có môn: không cảnh báo sai.
  final Set<String> activeSubjects;
  final String? busyId;
  final String? message;
  final bool isError;

  bool subjectUnknown(SchoolClass c) => activeSubjects.isNotEmpty && !activeSubjects.contains(c.subject);
}

class _ReviewUi {
  const _ReviewUi({this.tab = ClassStatus.pending, this.busyId, this.message, this.isError = false});
  final ClassStatus tab;
  final String? busyId;
  final String? message;
  final bool isError;
}

final _reviewUiProvider = NotifierProvider.autoDispose<_ReviewUiNotifier, _ReviewUi>(_ReviewUiNotifier.new);

class _ReviewUiNotifier extends Notifier<_ReviewUi> {
  @override
  _ReviewUi build() => const _ReviewUi();
  void set(_ReviewUi v) => state = v;
}

final _classesByStatusProvider = StreamProvider.autoDispose.family<List<SchoolClass>, ClassStatus>(
  (ref, status) => ref.watch(classRepositoryProvider).watchByStatus(status),
);

final _subjectsProvider = StreamProvider.autoDispose<List<Subject>>((ref) => ref.watch(subjectRepositoryProvider).watchAll());

final classStudentsProvider = FutureProvider.autoDispose.family<List<Student>, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).students(classId),
);

final reviewViewModelProvider = NotifierProvider.autoDispose<ReviewViewModel, ReviewState>(ReviewViewModel.new);

/// Hàng đợi duyệt lớp: cập nhật thời gian thực; duyệt xong app giảng viên đổi ngay.
class ReviewViewModel extends Notifier<ReviewState> {
  @override
  ReviewState build() {
    final ui = ref.watch(_reviewUiProvider);
    final classes = ref.watch(_classesByStatusProvider(ui.tab));
    final subjects = ref.watch(_subjectsProvider).value ?? const <Subject>[];
    return ReviewState(
      tab: ui.tab,
      busyId: ui.busyId,
      message: ui.message,
      isError: ui.isError,
      activeSubjects: {for (final s in subjects) if (s.isActive) s.code},
      items: classes.when(
        data: (d) => d.isEmpty ? const Empty() : Ready(d),
        error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
        loading: () => const Loading(),
      ),
    );
  }

  _ReviewUiNotifier get _ui => ref.read(_reviewUiProvider.notifier);

  void setTab(ClassStatus t) => _ui.set(_ReviewUi(tab: t));
  void retry() => ref.invalidate(_classesByStatusProvider(state.tab));
  void messageShown() => _ui.set(_ReviewUi(tab: state.tab, busyId: state.busyId));

  Future<void> approve(SchoolClass c) => _decide(c, approve: true);

  /// Trả false nếu thiếu lý do, màn giữ hộp thoại mở.
  Future<bool> reject(SchoolClass c, String reason) async {
    final r = reason.trim();
    if (r.isEmpty || r.length > 300) return false;
    await _decide(c, approve: false, reason: r);
    return true;
  }

  Future<void> _decide(SchoolClass c, {required bool approve, String? reason}) async {
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    final tab = state.tab;
    _ui.set(_ReviewUi(tab: tab, busyId: c.id));
    try {
      await ref.read(classRepositoryProvider).review(c, approve: approve, reviewerUid: uid, reason: reason);
      await ref.read(analyticsServiceProvider).classReview(decision: approve ? 'approved' : 'rejected', subject: c.subject);
      if (ref.mounted) _ui.set(_ReviewUi(tab: tab, message: approve ? 'Đã duyệt ${c.label}' : 'Đã từ chối ${c.label}'));
    } on AppException catch (e) {
      if (ref.mounted) _ui.set(_ReviewUi(tab: tab, message: e.message, isError: true));
    }
  }
}
