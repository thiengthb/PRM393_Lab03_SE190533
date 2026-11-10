import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendo_core/config/app_config.dart';
import 'package:attendo_core/firebase/config_service.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import '../providers.dart';
import 'package:attendo_core/services/slot_repository.dart';
import 'package:attendo_core/services/student_attendance_repository.dart';
import 'package:attendo_core/utils/app_exception.dart';
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

/// Roster tabs on the desktop session screen.
enum RosterFilter { all, missing, present }

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
    this.timedOut = false,
    this.canReopen = false,
    this.code,
    this.tvLink,
    this.follower = false,
  });

  final Slot slot;
  final List<Student> roster;
  final Map<String, AttendanceRecord> records;
  final SessionStep step;
  final String? qrText;
  final int rotateIn;
  final Duration remaining;
  final int rotateSeconds;

  /// .D3: mã tự đóng vì hết giờ mở mã (không phải giảng viên bấm Đóng mã).
  final bool timedOut;

  /// Nút “Mở lại mã” chỉ hiện khi slot còn trong giờ học.
  final bool canReopen;

  /// Mã số 6 chữ đang dùng, null khi chưa ghi được hoặc đã đóng mã.
  final String? code;

  /// Link màn chiếu nếu đã bấm Chiếu lên TV.
  final String? tvLink;

  bool isPresent(String code) => records[code]?.present ?? false;
  /// LOI-05: another lecturer device opened the code first and rotates it; this device only
  /// shows the same QR (no 6-digit code) and takes over when that device stops.
  final bool follower;

  int get presentCount => roster.where((s) => isPresent(s.code)).length;
  int get absentCount => roster.length - presentCount;
  List<Student> get missing => roster.where((s) => !isPresent(s.code)).toList();
  List<Student> get scanned => roster.where((s) => isPresent(s.code)).toList();
  List<Student> get absentees => roster.where((s) => !isPresent(s.code)).toList();

  /// Desktop roster: one tab of the class, matching [query] by name or student code
  /// (accents and case ignored for the code, case ignored for the name).
  List<Student> rosterView(RosterFilter filter, String query) {
    final q = query.trim().toLowerCase();
    return [
      for (final s in roster)
        if ((filter == RosterFilter.all ||
                (filter == RosterFilter.present) == isPresent(s.code)) &&
            (q.isEmpty || s.name.toLowerCase().contains(q) || s.code.toLowerCase().contains(q)))
          s,
    ];
  }
}

class _SessionUi {
  const _SessionUi({
    this.step,
    this.token,
    this.expiresAt,
    this.rotateIn = 0,
    this.local = const {},
    this.timedOut = false,
    this.code,
    this.prevCode,
    this.follower = false,
  });

  /// See [SessionData.follower].
  final bool follower;

  /// null: suy ra từ slot (đã chốt → closed, còn lại → open).
  final SessionStep? step;
  final String? token;
  final DateTime? expiresAt;
  final int rotateIn;

  /// Đánh dấu tay chưa về tới máy chủ (hiện ngay, không chờ snapshot).
  final Map<String, bool> local;
  final bool timedOut;

  /// Mã số của token hiện tại và của token vừa thay (còn nhận 1 chu kỳ như qrTokenPrev).
  final String? code;
  final String? prevCode;

  _SessionUi copyWith({
    SessionStep? step,
    String? token,
    DateTime? expiresAt,
    int? rotateIn,
    Map<String, bool>? local,
    bool? timedOut,
    String? code,
    String? prevCode,
    bool? follower,
  }) =>
      _SessionUi(
        step: step ?? this.step,
        token: token ?? this.token,
        expiresAt: expiresAt ?? this.expiresAt,
        rotateIn: rotateIn ?? this.rotateIn,
        local: local ?? this.local,
        timedOut: timedOut ?? this.timedOut,
        code: code ?? this.code,
        prevCode: prevCode ?? this.prevCode,
        follower: follower ?? this.follower,
      );

  /// Bỏ cả hai mã số (sau khi đóng mã).
  _SessionUi withoutCodes() => _SessionUi(
        step: step,
        token: token,
        expiresAt: expiresAt,
        rotateIn: rotateIn,
        local: local,
        timedOut: timedOut,
        follower: follower,
      );
}

/// Link màn chiếu TV-001 để gõ trên máy phòng học.
String tvLinkOf(String key) => '${AppConfig.tvBase}/tv/$key';

final slotProvider = StreamProvider.autoDispose.family<Slot?, String>(
  (ref, id) => ref.watch(slotRepositoryProvider).watchSlot(id),
);

final slotAttendanceProvider = StreamProvider.autoDispose.family<List<AttendanceRecord>, String>(
  (ref, id) => ref.watch(slotRepositoryProvider).watchAttendance(id),
);

final _sessionUiProvider =
    NotifierProvider.autoDispose.family<_SessionUiNotifier, _SessionUi, String>(_SessionUiNotifier.new);

/// Giữ đồng hồ đổi mã ở đây: notifier này không build lại theo dữ liệu,
/// nên timer chỉ dừng khi rời màn.
class _SessionUiNotifier extends Notifier<_SessionUi> {
  _SessionUiNotifier(this.slotId);
  final String slotId;

  Timer? ticker;

  /// This device rotates the code right now (LOI-05). Leaving the screen releases the lease
  /// so another lecturer device takes over at its next tick instead of waiting for expiry.
  bool leading = false;
  DateTime? openedAt;
  DateTime? sessionEnd;
  bool started = false;

  /// CR-20: lần chốt gần nhất đã nằm trong hàng đợi Firestore (mất mạng). false nghĩa là server
  /// đã từ chối, nên "Thử lại" phải chốt lại chứ không chỉ chờ hàng đợi.
  bool closeQueued = false;

  /// CR-42: bumped on every queued close, so a background check from an older attempt does not
  /// clear [closeQueued] for a newer one that is still waiting in the queue.
  int closeAttempt = 0;

  /// Tokens this device wrote (LOI-05): a token on the slot that is not one of these was
  /// written by another lecturer device.
  final Set<String> own = {};

  /// Last token write still in flight. Releasing the lease before it lands would let that
  /// write put the lease back, so the next device stays a follower until it expires.
  Future<void> lastWrite = Future<void>.value();

  /// Khoá màn chiếu vừa tạo trong phiên này (trước khi snapshot slot có tvKey).
  String? tvKey;

  @override
  _SessionUi build() {
    final repo = ref.read(slotRepositoryProvider);
    ref.onDispose(() {
      ticker?.cancel();
      if (leading) {
        lastWrite.whenComplete(() => repo.releaseQr(slotId).catchError((Object _) {}));
      }
    });
    return const _SessionUi();
  }

  void update(_SessionUi Function(_SessionUi) f) => state = f(state);
  SessionStep? get step => state.step;
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
      qrText: step != SessionStep.open
          ? null
          : ui.follower
              ? (slot.qrToken == null ? null : QrPayload.forSlot(slot, slot.qrToken!).encode())
              : (ui.token == null ? null : QrPayload.forSlot(slot, ui.token!).encode()),
      rotateIn: ui.rotateIn,
      remaining: _sessionEnd == null ? Duration.zero : _sessionEnd!.difference(now),
      rotateSeconds: cfg.qrRotateSeconds,
      timedOut: ui.timedOut,
      canReopen: slot.canReopenQrAt(now),
      code: step == SessionStep.open && !ui.follower ? ui.code : null,
      follower: step == SessionStep.open && ui.follower,
      tvLink: _tvKeyOf(slot) == null ? null : tvLinkOf(_tvKeyOf(slot)!),
    ));
  }

  String? _tvKeyOf(Slot slot) => slot.tvKey ?? _ui.tvKey;

  DateTime? get _sessionEnd => _ui.sessionEnd;
  set _sessionEnd(DateTime? v) => _ui.sessionEnd = v;
  Timer? get _ticker => _ui.ticker;
  set _ticker(Timer? t) => _ui.ticker = t;

  static String _newToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String _newCode(Set<String> avoid) {
    final r = Random.secure();
    while (true) {
      final c = r.nextInt(1000000).toString().padLeft(6, '0');
      if (!avoid.contains(c)) return c;
    }
  }

  /// Khung màn chiếu theo trạng thái hiện tại. Số đã quét chỉ cập nhật mỗi lần đổi mã
  /// (trễ tối đa 1 chu kỳ) để giữ số lần ghi thấp.
  TvWrite? _tvWrite(Slot slot, {required bool open, String? qr, String? code, DateTime? rotatedAt, int? rotateSeconds}) {
    final key = _tvKeyOf(slot);
    if (key == null) return null;
    final d = state.dataOrNull;
    final end = _sessionEnd;
    return TvWrite(
      key: key,
      lecturerId: slot.lecturerId,
      slotId: slot.id,
      frame: TvFrame(
        title: slot.classLabel,
        subtitle: '${slot.room} · ${_hm(slot.start)} – ${_hm(slot.end)}',
        open: open,
        present: d?.presentCount ?? slot.presentCount,
        total: d?.roster.length ?? slot.studentCount,
        qr: open ? qr : null,
        code: open ? code : null,
        rotatedAt: open ? rotatedAt : null,
        rotateSeconds: rotateSeconds ?? 12,
        endsAt: open ? end : null,
        validUntil: _tvValidUntil(slot),
      ),
    );
  }

  /// Link sống tới hết giờ slot, hoặc hết giờ mở mã nếu mở muộn hơn.
  DateTime _tvValidUntil(Slot slot) {
    final end = _sessionEnd;
    final base = end != null && end.isAfter(slot.end) ? end : slot.end;
    return base.add(const Duration(minutes: 15));
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _openQr(AppRemoteConfig cfg) async {
    if (!ref.mounted) return;
    final repo = ref.read(slotRepositoryProvider);
    final slot = ref.read(slotProvider(slotId)).value;
    final now = ref.read(clockProvider)();
    _openedAt ??= now;
    _sessionEnd ??= now.add(Duration(minutes: cfg.sessionMinutes));
    final period = cfg.qrRotateSeconds;
    Future<void> rotate() async {
      final at = ref.read(clockProvider)();
      // LOI-05: if a fresh token on the slot was written by another device, follow it instead
      // of overwriting it; take over once it expires (that device left or closed its screen).
      final cur = ref.read(slotProvider(slotId)).value;
      // Slot not loaded yet (first open on this device): try again next second instead of
      // claiming the lease and skipping the write, which left no code for a whole period.
      if (cur == null) {
        _ui.update((u) => u.copyWith(rotateIn: 1));
        return;
      }
      final foreign = cur.qrOpen &&
          cur.qrToken != null &&
          !_ui.own.contains(cur.qrToken) &&
          (cur.qrLeaseUntil ?? cur.qrExpiresAt) != null &&
          (cur.qrLeaseUntil ?? cur.qrExpiresAt)!.isAfter(at);
      if (foreign) {
        _ui.leading = false;
        // Check again soon: the other device may release the lease any moment.
        _ui.update((u) => u.copyWith(follower: true, rotateIn: 3));
        return;
      }
      _ui.leading = true;
      final t = _newToken();
      _ui.own.add(t);
      if (_ui.own.length > 6) _ui.own.remove(_ui.own.first); // keep the newest few (insertion order)
      // Mã hết hạn sau 1 chu kỳ + 3 giây trễ mạng.
      final exp = at.add(Duration(seconds: period + 3));
      // Mã vừa thay còn nhận thêm 1 chu kỳ: sinh viên quét chậm hoặc gõ mã số không bị báo hết hạn.
      final before = ref.read(_sessionUiProvider(slotId));
      final keepPrev = before.token != null && before.expiresAt != null && before.expiresAt!.isAfter(at);
      _ui.update((u) => u.copyWith(token: t, expiresAt: exp, rotateIn: period, follower: false));
      final s = ref.read(slotProvider(slotId)).value;
      if (s == null) return;
      final payload = QrPayload.forSlot(s, t).encode();
      // Mã số của token vừa thay vẫn giữ (như qrTokenPrev); mã của token trước nữa thì xoá.
      final drop = [
        if (before.prevCode != null) before.prevCode!,
        if (!keepPrev && before.code != null) before.code!,
      ];
      final avoid = {?before.code, ?before.prevCode};
      for (var attempt = 0; attempt < 3; attempt++) {
        final code = _newCode(avoid);
        try {
          final write = repo.openQr(
            slotId,
            t,
            exp,
            prevToken: keepPrev ? before.token : null,
            prevExpiresAt: keepPrev ? exp : null,
            code: QrCodeEntry(
              code: code,
              lecturerId: s.lecturerId,
              slotId: s.id,
              classId: s.classId,
              payload: payload,
              // Mã số sống như token của nó: hạn chính, cộng 1 chu kỳ khi là mã vừa thay.
              expiresAt: exp.add(Duration(seconds: period)),
            ),
            dropCodes: drop,
            tv: _tvWrite(s, open: true, qr: payload, code: code, rotatedAt: at, rotateSeconds: period),
          );
          _ui.lastWrite = write.then((_) {}, onError: (Object _) {});
          await write;
          if (!ref.mounted) return;
          // Token đã đổi tiếp trong lúc chờ mạng thì bỏ kết quả này.
          if (ref.read(_sessionUiProvider(slotId)).token != t) return;
          _ui.update((u) => _SessionUi(
                step: u.step,
                token: u.token,
                expiresAt: u.expiresAt,
                rotateIn: u.rotateIn,
                local: u.local,
                timedOut: u.timedOut,
                code: code,
                prevCode: keepPrev ? before.code : null,
              ));
          return;
        } on AppException catch (e, st) {
          // Trùng mã số với lớp khác: thử mã khác. Lỗi khác thì dừng.
          avoid.add(code);
          if (e.kind == AppErrorKind.permission && attempt < 2) continue;
          await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_open_qr');
          return;
        }
      }
    }

    await rotate();
    // CR-21: giảng viên rời màn trong lúc ghi mã đầu tiên thì ref đã huỷ; đọc tiếp sẽ ném lỗi.
    if (!ref.mounted) return;
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
        _ui.update((u) => u.copyWith(timedOut: true));
        closeQr(); // hết giờ mở mã → .D3 (như .D2, kèm thông báo)
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

  /// Nút “Đóng mã” ở .D1: đóng mã, sang .D2 xem ngoại lệ.
  Future<void> closeQr() async {
    _ticker?.cancel();
    _ui.leading = false;
    final before = ref.read(_sessionUiProvider(slotId));
    _ui.update((u) => u.copyWith(step: SessionStep.review).withoutCodes());
    final slot = ref.read(slotProvider(slotId)).value;
    try {
      await ref.read(slotRepositoryProvider).closeQr(
            slotId,
            dropCodes: [?before.code, ?before.prevCode],
            tv: slot == null ? null : _tvWrite(slot, open: false),
          );
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_close_qr');
    }
  }

  /// Nút “Chiếu lên TV”: tạo link màn chiếu (một lần cho mỗi slot) rồi đẩy khung hiện tại.
  /// Trả về link, hoặc null nếu chưa ghi được.
  Future<String?> startTv() async {
    final slot = ref.read(slotProvider(slotId)).value;
    if (slot == null) return null;
    final existing = _tvKeyOf(slot);
    if (existing != null) return tvLinkOf(existing);
    final key = _newToken();
    _ui.tvKey = key;
    final ui = ref.read(_sessionUiProvider(slotId));
    final cfg = ref.read(remoteConfigProvider).value ?? const AppRemoteConfig();
    final open = ui.step == null || ui.step == SessionStep.open;
    final tv = _tvWrite(
      slot,
      open: open && ui.token != null,
      qr: ui.token == null ? null : QrPayload.forSlot(slot, ui.token!).encode(),
      code: ui.code,
      rotatedAt: ui.token == null
          ? null
          : ref.read(clockProvider)().subtract(Duration(seconds: cfg.qrRotateSeconds - ui.rotateIn)),
      rotateSeconds: cfg.qrRotateSeconds,
    )!;
    try {
      await ref.read(slotRepositoryProvider).createTv(tv);
    } on AppException catch (e, st) {
      _ui.tvKey = null;
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_start_tv');
      return null;
    }
    if (ref.mounted) ref.invalidateSelf();
    return tvLinkOf(key);
  }

  /// Nút “Mở lại mã” ở .D2.
  Future<void> reopen() async {
    final slot = state.dataOrNull?.slot;
    if (slot == null || !slot.canReopenQrAt(ref.read(clockProvider)())) return;
    _ui.update((u) => _SessionUi(local: u.local, step: SessionStep.open));
    _sessionEnd = null;
    await _openQr(ref.read(remoteConfigProvider).value ?? const AppRemoteConfig());
  }

  /// Công tắc trên hàng sinh viên.
  Future<void> toggle(Student s, bool present) async {
    final d = state.dataOrNull;
    if (d == null) return;
    final was = d.records[s.code]?.present ?? false;
    _ui.update((u) => u.copyWith(local: {...u.local, s.code: present}));
    try {
      await ref.read(slotRepositoryProvider).markManual(d.slot, s, present, wasPresent: was);
    } on AppException catch (e, st) {
      // Vẫn giữ trên máy; Firestore gửi lại khi có mạng.
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'session_mark_manual');
    }
  }

  /// Nút “Chốt” ở .D2. Bản v2 bỏ hộp xác nhận OV1 vì đã có Hoàn tác ở .S.
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
      final tv = ref.mounted ? _tvWrite(d.slot, open: false) : null;
      if (tv != null) unawaited(ref.read(slotRepositoryProvider).pushTv(tv).catchError((_) {}));
    } on SavedOfflineException catch (e, st) {
      offline = true;
      _ui.closeQueued = true;
      _ui.closeAttempt++;
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'attendance_close_offline');
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.offline));
      _finishWhenSynced();
    } on AppException catch (e, st) {
      offline = true;
      _ui.closeQueued = false;
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

  /// Dải .X “Thử lại”.
  Future<void> retrySync() async {
    // CR-20: server đã từ chối lần chốt (vd lớp chưa được duyệt) thì SDK đã bỏ lần ghi đó;
    // chỉ chờ hàng đợi sẽ báo "Đã chốt" trong khi slot vẫn mở. Chốt lại thật.
    if (!_ui.closeQueued) return confirmClose();
    final d = state.dataOrNull;
    if (d == null) return;
    _ui.update((u) => u.copyWith(step: SessionStep.closing));
    final attempt = _ui.closeAttempt;
    try {
      final repo = ref.read(slotRepositoryProvider);
      await repo.waitForSync();
      // CR-31: hàng đợi gửi xong không có nghĩa server đã nhận lần chốt.
      final closed = await repo.isClosedOnServer(d.slot.id);
      if (!ref.mounted || attempt != _ui.closeAttempt) return;
      if (closed) {
        _ui.update((u) => u.copyWith(step: SessionStep.closed, local: const {}));
      } else {
        // Server đã bỏ lần chốt: lần Thử lại sau phải chốt lại thật.
        _ui.closeQueued = false;
        _ui.update((u) => u.copyWith(step: SessionStep.offline));
      }
    } on AppException {
      if (ref.mounted) _ui.update((u) => u.copyWith(step: SessionStep.offline));
      _finishWhenSynced();
    }
  }

  /// Lần chốt đã nằm trong hàng đợi của Firestore: có mạng lại thì SDK tự gửi. Chờ ngầm để dải
  /// .X tự đổi sang “Đã chốt”, không bắt giảng viên bấm Thử lại đúng lúc SDK đã nối lại (test web
  /// 06/11: có mạng lại, lần Thử lại đầu vẫn hết 8 giây vì SDK chưa nối, lần hai mới qua).
  void _finishWhenSynced() {
    final repo = ref.read(slotRepositoryProvider);
    final slotId = state.dataOrNull?.slot.id;
    if (slotId == null) return;
    final attempt = _ui.closeAttempt;
    unawaited(repo.waitForSync(timeout: const Duration(minutes: 10)).then((_) async {
      // CR-31: đọc lại từ server; bị từ chối thì giữ dải .X để giảng viên chốt lại.
      final closed = await repo.isClosedOnServer(slotId);
      if (!ref.mounted || attempt != _ui.closeAttempt || _ui.step != SessionStep.offline) return;
      if (closed) {
        _ui.update((u) => u.copyWith(step: SessionStep.closed, local: const {}));
      } else {
        _ui.closeQueued = false;
      }
    }, onError: (_) {}).catchError((_) {}));
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
