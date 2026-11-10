import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendo_core/firebase/config_service.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import '../providers.dart';
import 'package:attendo_core/services/student_attendance_repository.dart';
import 'package:attendo_core/utils/app_exception.dart';
import 'package:attendo_core/utils/calendar.dart';

// ---------------- SV-001 Buổi vắng của tôi, SV-002 Chi tiết môn ----------------

class MyAttendanceData {
  const MyAttendanceData({
    required this.user,
    required this.term,
    required this.subjects,
    required this.warning,
    this.requests = const {},
  });
  final AppUser user;
  final String term;
  final List<SubjectAttendance> subjects;

  /// Môn cần cảnh báo nhất (dải .D1, .D2, .D3), null nếu không có.
  final SubjectAttendance? warning;

  /// Báo sai đã gửi, theo slotId (SV-002 .D1 ghi kết quả dưới từng buổi).
  final Map<String, CorrectionRequest> requests;

  /// Buổi vắng còn báo sai được: chưa gửi lần nào. Đang chờ duyệt thì hiện trạng thái,
  /// bị từ chối thì không báo lại (Figma SV-002 .D1).
  bool canReport(AttendanceRecord r) => !r.present && (requests[r.slotId] == null);
}

/// Mức dải cảnh báo SV-001 v2.
enum WarnKind {
  /// .D1 còn được vắng 1 buổi.
  oneLeft,

  /// .D2 vắng thêm sẽ fail.
  lastChance,

  /// .D3 đã fail.
  failed,
}

WarnKind? warnKindOf(SubjectAttendance s) {
  if (s.remaining < 0) return WarnKind.failed;
  if (s.absent == 0) return null;
  if (s.remaining == 0) return WarnKind.lastChance;
  if (s.remaining == 1) return WarnKind.oneLeft;
  return null;
}

/// Sinh viên đang đăng nhập (đầu trang web, dòng avatar).
final myAttendanceUserProvider = Provider.autoDispose<AppUser?>((ref) => ref.watch(currentUserProvider).value);

final myRecordsProvider = StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final code = ref.watch(currentUserProvider).value?.studentCode;
  if (code == null) return const Stream.empty();
  return ref.watch(studentAttendanceRepositoryProvider).watchMine(code);
});

final myRequestsProvider = StreamProvider.autoDispose<List<CorrectionRequest>>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(requestRepositoryProvider).watchMine(uid);
});

final myAttendanceViewModelProvider =
    NotifierProvider.autoDispose<MyAttendanceViewModel, ViewState<MyAttendanceData>>(MyAttendanceViewModel.new);

class MyAttendanceViewModel extends Notifier<ViewState<MyAttendanceData>> {
  @override
  ViewState<MyAttendanceData> build() {
    final user = ref.watch(currentUserProvider).value;
    final recs = ref.watch(myRecordsProvider);
    // Báo sai chỉ thêm dòng kết quả; chưa tải xong hoặc lỗi thì vẫn hiện danh sách buổi.
    final reqs = ref.watch(myRequestsProvider).value ?? const <CorrectionRequest>[];
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final now = ref.watch(clockProvider)();
    if (user == null) return const Loading();
    if (recs.hasError) {
      final e = recs.error;
      return Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại');
    }
    if (!recs.hasValue) return const Loading();
    final term = Term.of(now);
    final all = ref.read(aggregatorProvider).bySubject(recs.requireValue, percent: cfg.absenceLimitPercent);
    final subjects = all.where((s) => s.term == term).toList();
    if (subjects.isEmpty) return const Empty();
    SubjectAttendance? warn;
    for (final s in subjects) {
      if (warnKindOf(s) == null) continue;
      if (warn == null || s.remaining < warn.remaining) warn = s;
    }
    return Ready(MyAttendanceData(
      user: user,
      term: term,
      subjects: subjects,
      warning: warn,
      requests: {for (final r in reqs) r.slotId: r},
    ));
  }

  SubjectAttendance? subject(String classId) =>
      state.dataOrNull?.subjects.where((s) => s.classId == classId).firstOrNull;

  void retry() => ref.invalidate(myRecordsProvider);
}

// ---------------- SV-101 Quét mã ----------------

sealed class ScanState {
  const ScanState();
}

/// .D camera đang quét.
class Scanning extends ScanState {
  const Scanning();
}

class Submitting extends ScanState {
  const Submitting();
}

/// .S đã ghi nhận.
class Scanned extends ScanState {
  const Scanned(this.result);
  final ScanResult result;
}

/// .X mã hết hạn / không hợp lệ / không thuộc lớp / mất mạng.
class ScanFailed extends ScanState {
  const ScanFailed(this.reason, {this.typed = false});
  final ScanFailure reason;

  /// Lỗi khi gõ mã số (màn Nhập mã), không phải khi quét.
  final bool typed;

  String get title => switch (reason) {
        ScanFailure.expired => 'Mã đã hết hạn',
        ScanFailure.wrongCode => 'Mã không đúng hoặc đã hết hạn',
        ScanFailure.invalid => 'Mã không hợp lệ',
        ScanFailure.notInClass => 'Em không có trong lớp này',
        ScanFailure.network => 'Mất kết nối mạng',
        ScanFailure.alreadyClosed => 'Slot đã chốt',
      };

  String get detail => switch (reason) {
        ScanFailure.notInClass || ScanFailure.alreadyClosed => 'Hãy báo giảng viên',
        _ => typed ? 'Hãy nhập mã mới trên màn chiếu' : 'Hãy quét lại',
      };
}

/// .X2 trình duyệt hoặc máy chặn camera.
class CameraBlocked extends ScanState {
  const CameraBlocked();
}

final scanViewModelProvider = NotifierProvider.autoDispose<ScanViewModel, ScanState>(ScanViewModel.new);

class ScanViewModel extends Notifier<ScanState> {
  @override
  ScanState build() => const Scanning();

  Future<void> onCode(String raw) async {
    if (state is! Scanning) return; // chỉ xử lý mã đầu tiên
    final payload = QrPayload.tryParse(raw);
    final user = ref.read(currentUserProvider).value;
    if (payload == null || user?.studentCode == null) {
      state = const ScanFailed(ScanFailure.invalid);
      await ref.read(analyticsServiceProvider).qrScan(result: 'invalid');
      return;
    }
    await _submit(payload);
  }

  /// Màn Nhập mã: 6 chữ số trên màn chiếu → đọc `qrCodes/{mã}` → ghi như khi quét.
  Future<void> submitCode(String code) async {
    if (state is Submitting) return;
    final user = ref.read(currentUserProvider).value;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code) || user?.studentCode == null) {
      state = const ScanFailed(ScanFailure.wrongCode, typed: true);
      return;
    }
    state = const Submitting();
    try {
      final payload = await ref.read(studentAttendanceRepositoryProvider).lookupCode(code);
      if (!ref.mounted) return;
      await _submit(payload, typed: true);
    } on ScanException catch (e) {
      if (!ref.mounted) return;
      state = ScanFailed(e.reason, typed: true);
      await ref.read(analyticsServiceProvider).qrScan(result: e.reason.name, method: 'code');
    }
  }

  Future<void> _submit(QrPayload payload, {bool typed = false}) async {
    final user = ref.read(currentUserProvider).value!;
    state = const Submitting();
    try {
      final r = await ref.read(studentAttendanceRepositoryProvider).scan(
            payload,
            studentCode: user.studentCode!,
            studentName: user.displayName,
            uid: user.uid,
          );
      if (!ref.mounted) return;
      state = Scanned(r);
      await ref.read(analyticsServiceProvider).qrScan(result: 'success', method: typed ? 'code' : 'qr');
    } on ScanException catch (e, st) {
      if (!ref.mounted) return;
      state = ScanFailed(e.reason, typed: typed);
      await ref.read(analyticsServiceProvider).qrScan(result: e.reason.name, method: typed ? 'code' : 'qr');
      if (e.reason == ScanFailure.network) {
        await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'qr_scan_network');
      }
    }
  }

  void cameraBlocked() => state = const CameraBlocked();
  void rescan() => state = const Scanning();
}

// ---------------- SV-102 Gửi báo sai ----------------

const reportReasons = [
  'Mạng lỗi, không quét được',
  'Đã quét nhưng không ghi nhận',
  'Quên quét mã',
  'Điện thoại hết pin',
  'Lý do khác',
];

class ReportState {
  const ReportState({this.reason, this.sending = false, this.sent = false, this.error});
  final String? reason;
  final bool sending;
  final bool sent;
  final String? error;
}

final reportViewModelProvider = NotifierProvider.autoDispose<ReportViewModel, ReportState>(ReportViewModel.new);

class ReportViewModel extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  void choose(String r) => state = ReportState(reason: r);

  Future<void> send(AttendanceRecord session, String note) async {
    final reason = state.reason;
    if (reason == null) {
      state = const ReportState(error: 'Chọn lý do');
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.studentCode == null) return;
    state = ReportState(reason: reason, sending: true);
    try {
      await ref.read(requestRepositoryProvider).create(
            studentUid: user.uid,
            studentCode: user.studentCode!,
            studentName: user.displayName,
            session: session,
            reason: reason,
            note: note.trim(),
          );
      await ref.read(analyticsServiceProvider).correctionSubmit(subject: session.subject, reason: reason);
      if (ref.mounted) state = ReportState(reason: reason, sent: true);
    } on AppException catch (e) {
      if (ref.mounted) state = ReportState(reason: reason, error: e.message);
    }
  }
}
