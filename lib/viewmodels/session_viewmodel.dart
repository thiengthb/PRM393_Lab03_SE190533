import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/config_service.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../services/slot_repository.dart';
import '../services/student_attendance_repository.dart';
import '../utils/app_exception.dart';
import 'classes_viewmodels.dart';

/// Các bước của GV-102 (hậu tố Lab 2).
enum SessionStep {
  /// .D1 mã đang mở, đếm thời gian thực.
  open,

  /// .D2 đã đóng mã, xem ngoại lệ, bật tay.
  review,

  /// .L đang chốt.
  closing,

  /// .X / GV-OV2 chưa gửi được.
  offline,

  /// .S đã chốt, có Hoàn tác.
  closed,
}

class SessionData {
  const SessionData({
    required this.slot,
    required this.roster,
    required this.records,
    required this.step,
    required this.qrText,
    required this.rotateIn,
    required this.remaining,
    required this.rotateSeconds,
  });

  final Slot slot;
  final List<Student> roster;
  final Map<String, AttendanceRecord> records;
  final SessionStep step;
  final String? qrText;
  final int rotateIn;
  final Duration remaining;
  final int rotateSeconds;

  bool isPresent(String code) => records[code]?.present ?? false;
  int get presentCount => roster.where((s) => isPresent(s.code)).length;
  int get absentCount => roster.length - presentCount;
  List<Student> get missing => roster.where((s) => !isPresent(s.code)).toList();
  List<Student> get scanned => roster.where((s) => isPresent(s.code)).toList();
  List<Student> get absentees => roster.where((s) => !isPresent(s.code)).toList();
}

class _SessionUi {
  const _SessionUi({this.step, this.token, this.expiresAt, this.rotateIn = 0, this.local = const {}});

  /// null: suy ra từ slot (đã chốt → closed, còn lại → open).
  final SessionStep? step;
  final String? token;
  final DateTime? expiresAt;
  final int rotateIn;

  /// Đánh dấu tay chưa về tới máy chủ (hiện ngay, không chờ snapshot).
  final Map<String, bool> local;

  _SessionUi copyWith({SessionStep? step, String? token, DateTime? expiresAt, int? rotateIn, Map<String, bool>? local}) =>
      _SessionUi(
        step: step ?? this.step,
        token: token ?? this.token,
        expiresAt: expiresAt ?? this.expiresAt,
        rotateIn: rotateIn ?? this.rotateIn,
        local: local ?? this.local,
      );
}

final slotProvider = StreamProvider.autoDispose.family<Slot?, String>(
  (ref, id) => ref.watch(slotRepositoryProvider).watchSlot(id),
);

final slotAttendanceProvider = StreamProvider.autoDispose.family<List<AttendanceRecord>, String>(
  (ref, id) => ref.watch(slotRepositoryProvider).watchAttendance(id),
);

final _sessionUiProvider =
    NotifierProvider.autoDispose.family<_SessionUiNotifier, _SessionUi, String>((_) => _SessionUiNotifier());

/// Giữ đồng hồ đổi mã ở đây: notifier này không build lại theo dữ liệu,
/// nên timer chỉ dừng khi rời màn.
class _SessionUiNotifier extends Notifier<_SessionUi> {
  Timer? ticker;
  DateTime? openedAt;
  DateTime? sessionEnd;
  bool started = false;

  @override
  _SessionUi build() {
    ref.onDispose(() => ticker?.cancel());
    return const _SessionUi();
  }

  void update(_SessionUi Function(_SessionUi) f) => state = f(state);
}

final sessionViewModelProvider =
    NotifierProvider.autoDispose.family<SessionViewModel, ViewState<SessionData>, String>(SessionViewModel.new);

/// GV-102 Phiên điểm danh (+ GV-OV1, GV-OV2).
class SessionViewModel extends Notifier<ViewState<SessionData>> {
  SessionViewModel(this.slotId);

  final String slotId;
  DateTime? get _openedAt => _ui.openedAt;
  set _openedAt(DateTime? v) => _ui.openedAt = v;
  bool get _started => _ui.started;
  set _started(bool v) => _ui.started = v;

  _SessionUiNotifier get _ui => ref.read(_sessionUiProvider(slotId).notifier);

  @override
  ViewState<SessionData> build() {
    final slotV = ref.watch(slotProvider(slotId));
    final recV = ref.watch(slotAttendanceProvider(slotId));
    final ui = ref.watch(_sessionUiProvider(slotId));
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final slot0 = slotV.value;
    final rosterV = slot0 == null ? null : ref.watch(classStudentsProvider(slot0.classId));

    final err = slotV.error ?? recV.error ?? rosterV?.error;
    if (err != null) return Failure(err is AppException ? err.message : 'Có lỗi, hãy thử lại');
    if (!slotV.hasValue || !recV.hasValue || rosterV == null || !rosterV.hasValue) return const Loading();
    final slot = slotV.requireValue;
    if (slot == null) return const Failure('Không tìm thấy slot', canRetry: false);

    final records = {for (final r in recV.requireValue) r.studentCode: r};
    ui.local.forEach((code, present) {
      final r = records[code];
      records[code] = AttendanceRecord(
        slotId: slotId,
        studentCode: code,
        studentName: r?.studentName ?? '',
        present: present,
        source: AttendanceSource.manual,
        isFinal: r?.isFinal ?? false,
      );
    });

    final now = ref.read(clockProvider)();
    // Slot đã hết giờ mà chưa chốt (FL-2 “Chốt ngay”) vào thẳng .D2, không mở mã.
    final step = ui.step ??
        switch (slot.phaseAt(now)) {
          SlotPhase.closed => SessionStep.closed,
          SlotPhase.unclosed => SessionStep.review,
          _ => SessionStep.open,
        };
    if (step == SessionStep.open && !_started) {
      _started = true;
      // Mở mã sau khi build xong (không ghi Firestore trong build()).
      Future.microtask(() => _openQr(cfg));
    }
    return Ready(SessionData(
      slot: slot,
      roster: rosterV.requireValue,
      records: records,
      step: step,
      qrText: step == SessionStep.open && ui.token != null ? QrPayload(slotId, ui.token!).encode() : null,
      rotateIn: ui.rotateIn,
      remaining: _sessionEnd == null ? Duration.zero : _sessionEnd!.difference(now),
      rotateSeconds: cfg.qrRotateSeconds,
    ));
  }

  DateTime? get _sessionEnd => _ui.sessionEnd;
  set _sessionEnd(DateTime? v) => _ui.sessionEnd = v;
  Timer? get _ticker => _ui.ticker;
  set _ticker(Timer? t) => _ui.ticker = t;

  static String _newToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _openQr(AppRemoteConfig cfg) async {
    if (!ref.mounted) return;
    final repo = ref.read(slotRepositoryProvider);
    final slot = ref.read(slotProvider(slotId)).value;
    final now = ref.read(clockProvider)();
    _openedAt ??= now;
    _sessionEnd ??= now.add(Duration(minutes: cfg.sessionMinutes));
    final period = cfg.qrRotateSeconds;
    Future<void> rotate() async {
      final t = _newToken();
      // Mã hết hạn sau 1 chu kỳ + 3 giây trễ mạng.
      final exp = ref.read(clockProvider)().add(Duration(seconds: period + 3));
      _ui.update((u) => u.copyWith(token: t, expiresAt: exp, rotateIn: period));
      try {
        await repo.openQr(slotId, t, exp);
      } on AppException catch (e, st) {
        await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_open_qr');
      }
    }

    await rotate();
    if (slot != null) {
      unawaited(ref.read(analyticsServiceProvider).sessionOpen(classId: slot.classId, subject: slot.subject, slotNo: slot.slotNo));
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!ref.mounted) return;
      final ui = ref.read(_sessionUiProvider(slotId));
      if (ui.step != null && ui.step != SessionStep.open) return;
      final end = _sessionEnd;
      if (end != null && !ref.read(clockProvider)().isBefore(end)) {
        closeQr(); // hết giờ mở mã → sang .D2
        return;
      }
      final next = ui.rotateIn - 1;
      if (next <= 0) {
        rotate();
      } else {
        _ui.update((u) => u.copyWith(rotateIn: next));
      }
    });
  }

  /// Nút “Chốt” ở .D1: đóng mã, sang .D2 xem ngoại lệ.
  Future<void> closeQr() async {
    _ticker?.cancel();
    _ui.update((u) => u.copyWith(step: SessionStep.review));
    try {
      await ref.read(slotRepositoryProvider).closeQr(slotId);
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_close_qr');
    }
  }

  /// Nút “Mở lại” ở .D2.
  Future<void> reopen() async {
    _ui.update((u) => _SessionUi(local: u.local, step: SessionStep.open));
    _sessionEnd = null;
    await _openQr(ref.read(remoteConfigProvider).value ?? const AppRemoteConfig());
  }

  /// Công tắc trên hàng sinh viên.
  Future<void> toggle(Student s, bool present) async {
    final d = state.dataOrNull;
    if (d == null) return;
    _ui.update((u) => u.copyWith(local: {...u.local, s.code: present}));
    try {
      await ref.read(slotRepositoryProvider).markManual(d.slot, s, present);
    } on AppException catch (e, st) {
      // Vẫn giữ trên máy; Firestore gửi lại khi có mạng.
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_mark_manual');
    }
  }

  /// Sau khi giảng viên xác nhận ở GV-OV1.
  Future<void> confirmClose() async {
    final d = state.dataOrNull;
    if (d == null) return;
    _ticker?.cancel();
    _ui.update((u) => u.copyWith(step: SessionStep.closing));
    final started = _openedAt ?? ref.read(clockProvider)();
    var offline = false;
    try {
      await ref.read(slotRepositoryProvider).closeSession(d.slot, d.roster, d.records);
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.closed, local: const {}));
    } on SavedOfflineException catch (e, st) {
      offline = true;
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'attendance_close_offline');
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.offline));
    } on AppException catch (e, st) {
      offline = true;
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'attendance_close');
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.offline));
    }
    await ref.read(analyticsServiceProvider).attendanceClose(
          classId: d.slot.classId,
          present: d.presentCount,
          absent: d.absentCount,
          manual: d.records.values.where((r) => r.source == AttendanceSource.manual && r.present).length,
          durationSec: ref.read(clockProvider)().difference(started).inSeconds,
          offline: offline,
        );
  }

  /// GV-OV2 “Thử lại”.
  Future<void> retrySync() async {
    _ui.update((u) => u.copyWith(step: SessionStep.closing));
    try {
      await ref.read(slotRepositoryProvider).waitForSync();
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.closed, local: const {}));
    } on AppException {
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.offline));
    }
  }

  /// Toast “Đã chốt · Hoàn tác” → quay về .D2.
  Future<void> undo() async {
    final d = state.dataOrNull;
    if (d == null) return;
    try {
      await ref.read(slotRepositoryProvider).undoClose(d.slot, d.roster);
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'attendance_undo');
    }
    if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.review));
  }

  /// GV-101 .D3 “Sửa”: mở lại kết quả đã chốt để sửa.
  void edit() => _ui.update((u) => u.copyWith(step: SessionStep.review));

  void retry() {
    ref.invalidate(slotProvider(slotId));
    ref.invalidate(slotAttendanceProvider(slotId));
  }
}
