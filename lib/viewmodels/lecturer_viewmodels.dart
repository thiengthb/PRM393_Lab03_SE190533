import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/config_service.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../utils/app_exception.dart';
import '../utils/calendar.dart';
import 'classes_viewmodels.dart';
import 'lecturer_feed.dart';
import 'session_viewmodel.dart';

// ---------------- GV-101 Chi tiết slot ----------------

class SlotDetailData {
  const SlotDetailData({required this.slot, required this.phase, required this.absentees});
  final Slot slot;
  final SlotPhase phase;

  /// Chỉ có khi đã chốt (.D3).
  final List<Student> absentees;
}

final slotDetailViewModelProvider =
    NotifierProvider.autoDispose.family<SlotDetailViewModel, ViewState<SlotDetailData>, String>(SlotDetailViewModel.new);

class SlotDetailViewModel extends Notifier<ViewState<SlotDetailData>> {
  SlotDetailViewModel(this.slotId);
  final String slotId;

  @override
  ViewState<SlotDetailData> build() {
    final slotV = ref.watch(slotProvider(slotId));
    final recV = ref.watch(slotAttendanceProvider(slotId));
    final err = slotV.error ?? recV.error;
    if (err != null) return Failure(err is AppException ? err.message : 'Có lỗi, hãy thử lại');
    if (!slotV.hasValue || !recV.hasValue) return const Loading();
    final slot = slotV.requireValue;
    if (slot == null) return const Failure('Không tìm thấy slot', canRetry: false);
    final now = ref.watch(clockProvider)();
    final absent = slot.closed
        ? recV.requireValue
            .where((r) => r.isFinal && !r.present)
            .map((r) => Student(code: r.studentCode, name: r.studentName))
            .toList()
        : <Student>[];
    absent.sort((a, b) => a.code.compareTo(b.code));
    return Ready(SlotDetailData(slot: slot, phase: slot.phaseAt(now), absentees: absent));
  }

  void retry() {
    ref.invalidate(slotProvider(slotId));
    ref.invalidate(slotAttendanceProvider(slotId));
  }
}

// ---------------- GV-104 Chú ý ----------------

enum AttentionFilter { all, over, near }

class AttentionData {
  const AttentionData({required this.items, required this.classes, required this.filter, required this.classId, required this.query});
  final List<StudentAbsence> items;
  final List<SchoolClass> classes;
  final AttentionFilter filter;
  final String? classId;
  final String query;

  /// Nhãn chip lớp: mã lớp đang lọc, hoặc “Lớp”.
  String get classChipLabel {
    final id = classId;
    if (id == null) return 'Lớp';
    for (final c in classes) {
      if (c.id == id) return c.code;
    }
    return 'Lớp';
  }
}

class _AttentionUi {
  const _AttentionUi({this.filter = AttentionFilter.all, this.classId, this.query = ''});
  final AttentionFilter filter;
  final String? classId;
  final String query;
}

final _attentionUiProvider = NotifierProvider.autoDispose<_AttentionUiNotifier, _AttentionUi>(_AttentionUiNotifier.new);

class _AttentionUiNotifier extends Notifier<_AttentionUi> {
  @override
  _AttentionUi build() => const _AttentionUi();
  void set(_AttentionUi v) => state = v;
}

final attentionViewModelProvider =
    NotifierProvider.autoDispose<AttentionViewModel, ViewState<AttentionData>>(AttentionViewModel.new);

class AttentionViewModel extends Notifier<ViewState<AttentionData>> {
  @override
  ViewState<AttentionData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final ui = ref.watch(_attentionUiProvider);
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final term = Term.of(ref.watch(clockProvider)());
    return viewStateOf(feed, (f) {
      final classes = f.classesOf(term);
      var items = ref.read(aggregatorProvider).attention(classes, f.records, percent: cfg.absenceLimitPercent);
      items = items.where((a) {
        if (ui.filter == AttentionFilter.over && a.level != AbsenceLevel.over) return false;
        if (ui.filter == AttentionFilter.near && a.level != AbsenceLevel.near) return false;
        if (ui.classId != null && a.schoolClass.id != ui.classId) return false;
        final q = ui.query.trim().toLowerCase();
        return q.isEmpty || a.student.name.toLowerCase().contains(q) || a.student.code.toLowerCase().contains(q);
      }).toList();
      return AttentionData(items: items, classes: classes, filter: ui.filter, classId: ui.classId, query: ui.query);
    });
  }

  _AttentionUi get _ui => ref.read(_attentionUiProvider);
  void _set(_AttentionUi v) => ref.read(_attentionUiProvider.notifier).set(v);

  void setFilter(AttentionFilter f) => _set(_AttentionUi(filter: f, classId: null, query: _ui.query));
  void setClass(String? id) => _set(_AttentionUi(filter: AttentionFilter.all, classId: id, query: _ui.query));
  void setQuery(String q) => _set(_AttentionUi(filter: _ui.filter, classId: _ui.classId, query: q));
  void retry() => ref.invalidate(lecturerFeedProvider);
}

// ---------------- GV-105 Yêu cầu sửa (+ GV-OV5) ----------------

class RequestsState {
  const RequestsState({required this.data, this.busyId, this.message, this.lastApproved});
  final ViewState<List<CorrectionRequest>> data;
  final String? busyId;
  final String? message;

  /// Để “Hoàn tác” sau khi duyệt.
  final CorrectionRequest? lastApproved;
}

class _RequestsUi {
  const _RequestsUi({this.busyId, this.message, this.lastApproved, this.hidden = const {}});
  final String? busyId;
  final String? message;
  final CorrectionRequest? lastApproved;

  /// Thẻ vừa duyệt/từ chối: ẩn ngay, không chờ snapshot.
  final Set<String> hidden;
}

final _requestsUiProvider = NotifierProvider.autoDispose<_RequestsUiNotifier, _RequestsUi>(_RequestsUiNotifier.new);

class _RequestsUiNotifier extends Notifier<_RequestsUi> {
  @override
  _RequestsUi build() => const _RequestsUi();
  void set(_RequestsUi v) => state = v;
}

final requestsViewModelProvider = NotifierProvider.autoDispose<RequestsViewModel, RequestsState>(RequestsViewModel.new);

class RequestsViewModel extends Notifier<RequestsState> {
  @override
  RequestsState build() {
    final feed = ref.watch(lecturerFeedProvider);
    final ui = ref.watch(_requestsUiProvider);
    final data = viewStateOf<LecturerFeed, List<CorrectionRequest>>(
      feed,
      (f) => f.pending.where((r) => !ui.hidden.contains(r.id)).toList(),
    );
    final mapped = switch (data) {
      Ready(:final data) when data.isEmpty => const Empty<List<CorrectionRequest>>(),
      _ => data,
    };
    return RequestsState(data: mapped, busyId: ui.busyId, message: ui.message, lastApproved: ui.lastApproved);
  }

  _RequestsUi get _ui => ref.read(_requestsUiProvider);
  void _set(_RequestsUi v) => ref.read(_requestsUiProvider.notifier).set(v);

  Future<void> approve(CorrectionRequest r) async {
    _set(_RequestsUi(busyId: r.id, hidden: _ui.hidden));
    try {
      await ref.read(requestRepositoryProvider).approve(r);
      await ref.read(analyticsServiceProvider).correctionReview(decision: 'approved');
      _set(_RequestsUi(message: 'Đã duyệt', lastApproved: r, hidden: {..._ui.hidden, r.id}));
    } on AppException catch (e) {
      _set(_RequestsUi(message: e.message, hidden: _ui.hidden));
    }
  }

  Future<void> undoApprove() async {
    final r = _ui.lastApproved;
    if (r == null) return;
    try {
      await ref.read(requestRepositoryProvider).undoApprove(r);
      _set(_RequestsUi(hidden: {..._ui.hidden}..remove(r.id)));
    } on AppException catch (e) {
      _set(_RequestsUi(message: e.message, hidden: _ui.hidden));
    }
  }

  Future<void> reject(CorrectionRequest r, {required String reason, required String note}) async {
    _set(_RequestsUi(busyId: r.id, hidden: _ui.hidden));
    try {
      await ref.read(requestRepositoryProvider).reject(r, reason: reason, note: note);
      await ref.read(analyticsServiceProvider).correctionReview(decision: 'rejected', reason: reason);
      _set(_RequestsUi(message: 'Đã từ chối', hidden: {..._ui.hidden, r.id}));
    } on AppException catch (e) {
      _set(_RequestsUi(message: e.message, hidden: _ui.hidden));
    }
  }

  void messageShown() => _set(_RequestsUi(lastApproved: _ui.lastApproved, hidden: _ui.hidden));
  void retry() => ref.invalidate(lecturerFeedProvider);
}

// ---------------- GV-201 Hồ sơ sinh viên (+ GV-OV3) ----------------

class StudentProfileData {
  const StudentProfileData({required this.absence, required this.absentSessions, required this.email});
  final StudentAbsence absence;
  final List<AttendanceRecord> absentSessions;
  final String? email;
}

class StudentProfileState {
  const StudentProfileState({required this.data, this.sentToday = false, this.sending = false, this.message});
  final ViewState<StudentProfileData> data;
  final bool sentToday;
  final bool sending;
  final String? message;
}

typedef StudentKey = ({String classId, String code});

class _ProfileUi {
  const _ProfileUi({this.sentToday = false, this.sending = false, this.message});
  final bool sentToday;
  final bool sending;
  final String? message;
}

final _profileUiProvider =
    NotifierProvider.autoDispose.family<_ProfileUiNotifier, _ProfileUi, StudentKey>((_) => _ProfileUiNotifier());

class _ProfileUiNotifier extends Notifier<_ProfileUi> {
  @override
  _ProfileUi build() => const _ProfileUi();
  void set(_ProfileUi v) => state = v;
}

final studentProfileViewModelProvider = NotifierProvider.autoDispose
    .family<StudentProfileViewModel, StudentProfileState, StudentKey>(StudentProfileViewModel.new);

class StudentProfileViewModel extends Notifier<StudentProfileState> {
  StudentProfileViewModel(this.key);
  final StudentKey key;
  bool _checked = false;

  @override
  StudentProfileState build() {
    final feed = ref.watch(lecturerFeedProvider);
    final studentsV = ref.watch(classStudentsProvider(key.classId));
    final ui = ref.watch(_profileUiProvider(key));
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();

    if (!_checked) {
      _checked = true;
      Future.microtask(_checkSent);
    }

    final err = feed.error ?? studentsV.error;
    final ViewState<StudentProfileData> data;
    if (err != null) {
      data = Failure(err is AppException ? err.message : 'Có lỗi, hãy thử lại');
    } else if (!feed.hasValue || !studentsV.hasValue) {
      data = const Loading();
    } else {
      final f = feed.requireValue;
      final c = f.classes.where((x) => x.id == key.classId).firstOrNull;
      final st = studentsV.requireValue.where((s) => s.code == key.code).firstOrNull;
      if (c == null || st == null) {
        data = const Failure('Không tìm thấy sinh viên', canRetry: false);
      } else {
        final absentSessions = f.records
            .where((r) => r.classId == c.id && r.studentCode == st.code && r.isFinal && !r.present)
            .toList()
          ..sort((a, b) => (b.start ?? DateTime(0)).compareTo(a.start ?? DateTime(0)));
        final absence = StudentAbsence(
          student: st,
          schoolClass: c,
          absent: absentSessions.length,
          limit: AttendanceMath.limit(c.totalSlots, cfg.absenceLimitPercent),
        );
        data = Ready(StudentProfileData(absence: absence, absentSessions: absentSessions, email: st.email));
      }
    }
    return StudentProfileState(data: data, sentToday: ui.sentToday, sending: ui.sending, message: ui.message);
  }

  void _set(_ProfileUi v) => ref.read(_profileUiProvider(key).notifier).set(v);

  Future<void> _checkSent() async {
    try {
      final sent = await ref.read(reminderRepositoryProvider).sentToday(key.classId, key.code, ref.read(clockProvider)());
      if (ref.mounted) _set(_ProfileUi(sentToday: sent));
    } on AppException {
      // Không chặn màn; nút Nhắc nhở vẫn bấm được.
    }
  }

  /// Nội dung soạn sẵn ở GV-OV3.
  String draftMessage() {
    final d = state.data.dataOrNull;
    if (d == null) return '';
    return 'Em đã vắng ${d.absence.absent} buổi ${d.absence.schoolClass.subject}.';
  }

  void logView() {
    final d = state.data.dataOrNull;
    if (d == null) return;
    ref.read(analyticsServiceProvider).viewStudent(classId: key.classId, absent: d.absence.absent, limit: d.absence.limit);
  }

  Future<void> send(String message) async {
    final d = state.data.dataOrNull;
    final user = ref.read(currentUserProvider).value;
    if (d == null || user == null) return;
    _set(const _ProfileUi(sending: true));
    try {
      await ref.read(reminderRepositoryProvider).send(
            lecturerId: user.uid,
            classId: key.classId,
            studentCode: key.code,
            toEmail: d.email ?? '',
            message: message.trim().isEmpty ? draftMessage() : message.trim(),
            now: ref.read(clockProvider)(),
          );
      await ref.read(analyticsServiceProvider).reminderSend(classId: key.classId, absent: d.absence.absent);
      _set(const _ProfileUi(sentToday: true, message: 'Đã gửi'));
    } on AppException catch (e) {
      _set(_ProfileUi(message: e.message));
    }
  }

  void messageShown() => _set(_ProfileUi(sentToday: state.sentToday));
}
