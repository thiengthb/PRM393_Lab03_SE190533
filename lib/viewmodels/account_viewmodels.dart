import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/config_service.dart';
import '../models/import_models.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../services/import_service.dart';
import '../utils/app_exception.dart';
import '../utils/calendar.dart';
import 'classes_viewmodels.dart';
import 'lecturer_feed.dart';

// ---------------- GV-004 Tài khoản (và tài khoản sinh viên) ----------------

final accountViewModelProvider = NotifierProvider.autoDispose<AccountViewModel, ViewState<AppUser>>(AccountViewModel.new);

class AccountViewModel extends Notifier<ViewState<AppUser>> {
  @override
  ViewState<AppUser> build() {
    final u = ref.watch(currentUserProvider);
    final user = u.value;
    if (user != null) return Ready(user);
    if (u.hasError) return const Failure('Mất kết nối mạng');
    return const Loading();
  }

  Future<void> setBeforeSlot(bool v) => _setReminders(beforeSlot: v);
  Future<void> setUnclosed(bool v) => _setReminders(unclosed: v);

  Future<void> _setReminders({bool? beforeSlot, bool? unclosed}) async {
    final u = state.dataOrNull;
    if (u == null) return;
    try {
      await ref.read(userRepositoryProvider).setReminders(u.uid, beforeSlot: beforeSlot, unclosed: unclosed);
      if (beforeSlot == true || unclosed == true) {
        await ref.read(localNotificationServiceProvider).requestPermission();
      }
    } on AppException {
      // Firestore giữ thay đổi trên máy khi mất mạng.
    }
  }

  Future<void> signOut() async {
    await ref.read(analyticsServiceProvider).logout();
    await ref.read(analyticsServiceProvider).setUser(null);
    await ref.read(crashServiceProvider).setUser(null);
    await ref.read(authServiceProvider).signOut();
  }
}

/// Lên lịch thông báo nhắc mỗi khi lịch hoặc cài đặt đổi (chỉ app giảng viên).
final reminderSchedulerProvider = Provider<void>((ref) {
  final feed = ref.watch(lecturerFeedProvider).value;
  if (feed == null) return;
  final u = feed.user;
  unawaited(ref.read(localNotificationServiceProvider).scheduleSlotReminders(
        feed.slots,
        beforeSlot: u.reminderBeforeSlot,
        unclosed: u.reminderUnclosed,
        now: ref.read(clockProvider)(),
      ));
});

// ---------------- GV-100 Nhập lớp ----------------

enum ImportStep { pick, preview, importing, errors, done }

class ImportState {
  const ImportState({
    this.step = ImportStep.pick,
    this.preview,
    this.done = 0,
    this.total = 0,
    this.message,
    this.pickedName,
  });

  final ImportStep step;
  final ImportPreview? preview;
  final int done;
  final int total;
  final String? message;
  final String? pickedName;
}

final importViewModelProvider = NotifierProvider.autoDispose<ImportViewModel, ImportState>(ImportViewModel.new);

class ImportViewModel extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  Future<void> pick() async {
    try {
      final f = await ref.read(filePickerServiceProvider).pickImportFile();
      if (f == null) return; // người dùng đóng hộp chọn file
      final p = ref.read(importServiceProvider).parse(f.bytes, f.name, now: ref.read(clockProvider)());
      if (!ref.mounted) return;
      if (p.hasErrors) {
        // Lỗi dòng là đường lỗi thật: ghi non-fatal để thấy trên Crashlytics.
        await ref.read(crashServiceProvider).recordNonFatal(
              AppException(AppErrorKind.invalid, '${p.errors.length} import row errors'),
              StackTrace.current,
              where: 'import_parse',
            );
      }
      state = ImportState(step: p.hasErrors ? ImportStep.errors : ImportStep.preview, preview: p, pickedName: f.name);
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'import_open');
      if (ref.mounted) state = ImportState(message: e.message);
    }
  }

  /// “Bỏ qua” ở .X: nhập các dòng hợp lệ.
  void skipErrors() {
    final p = state.preview;
    if (p == null || p.classes.isEmpty) {
      state = const ImportState(message: 'Không còn lớp hợp lệ');
      return;
    }
    state = ImportState(step: ImportStep.preview, preview: p, pickedName: state.pickedName);
  }

  Future<void> commit() async {
    final p = state.preview;
    final user = ref.read(currentUserProvider).value;
    if (p == null || user == null) return;
    state = ImportState(step: ImportStep.importing, preview: p, total: p.classes.length);
    try {
      await ref.read(classRepositoryProvider).importClasses(
        user.uid,
        p,
        now: ref.read(clockProvider)(),
        onProgress: (d, t) {
          if (ref.mounted) state = ImportState(step: ImportStep.importing, preview: p, done: d, total: t);
        },
      );
      await ref.read(userRepositoryProvider).markImported(user.uid);
      await ref.read(analyticsServiceProvider).importClasses(
            classCount: p.classes.length,
            studentCount: p.classes.fold(0, (n, c) => n + c.students.length),
            rowErrors: p.errors.length,
          );
      await ref.read(crashServiceProvider).setUser(user.uid, role: 'lecturer', term: p.term);
      if (ref.mounted) state = ImportState(step: ImportStep.done, preview: p, done: p.classes.length, total: p.classes.length);
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'import_commit');
      if (ref.mounted) state = ImportState(step: ImportStep.preview, preview: p, message: e.message);
    }
  }

  void reset() => state = const ImportState();

  Future<void> copyTemplate() async {
    await Clipboard.setData(const ClipboardData(text: ImportService.template));
    state = ImportState(step: state.step, preview: state.preview, message: 'Đã chép file mẫu (CSV)');
  }

  void messageShown() => state = ImportState(step: state.step, preview: state.preview, pickedName: state.pickedName);
}

// ---------------- Khu demo Firebase ----------------

class DemoState {
  const DemoState({
    this.token,
    this.permission,
    this.export = const ExportIdle(),
    this.selectedClassId,
    this.message,
    this.refreshing = false,
  });

  final String? token;
  final bool? permission;
  final ExportState export;
  final String? selectedClassId;
  final String? message;
  final bool refreshing;

  DemoState copyWith({String? token, bool? permission, ExportState? export, String? selectedClassId, String? message, bool? refreshing}) =>
      DemoState(
        token: token ?? this.token,
        permission: permission ?? this.permission,
        export: export ?? this.export,
        selectedClassId: selectedClassId ?? this.selectedClassId,
        message: message,
        refreshing: refreshing ?? this.refreshing,
      );
}

final firebaseDemoViewModelProvider =
    NotifierProvider.autoDispose<FirebaseDemoViewModel, DemoState>(FirebaseDemoViewModel.new);

class FirebaseDemoViewModel extends Notifier<DemoState> {
  @override
  DemoState build() {
    Future.microtask(_loadToken);
    return const DemoState();
  }

  AppRemoteConfig get config => ref.read(remoteConfigProvider).value ?? const AppRemoteConfig();

  Future<void> _loadToken() async {
    final t = await ref.read(messagingServiceProvider).token();
    if (ref.mounted) state = state.copyWith(token: t ?? '');
  }

  Future<void> requestPermission() async {
    final ok = await ref.read(messagingServiceProvider).requestPermission();
    if (ref.mounted) state = state.copyWith(permission: ok, message: ok ? 'Đã cho phép thông báo' : 'Thông báo đang bị chặn');
    await _loadToken();
  }

  Future<void> copyToken() async {
    final t = state.token;
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    state = state.copyWith(message: 'Đã chép FCM token');
  }

  Future<void> refreshConfig() async {
    state = state.copyWith(refreshing: true);
    try {
      await ref.read(configServiceProvider).refresh();
      if (ref.mounted) state = state.copyWith(refreshing: false, message: 'Đã tải Remote Config');
    } catch (_) {
      if (ref.mounted) state = state.copyWith(refreshing: false, message: 'Mất kết nối mạng');
    }
  }

  void selectClass(String id) => state = state.copyWith(selectedClassId: id);

  /// Xuất báo cáo của lớp đã chọn (dùng chung luồng với GV-103).
  Future<void> exportSelected(List<SchoolClass> classes) async {
    final id = state.selectedClassId ?? (classes.isEmpty ? null : classes.first.id);
    if (id == null) {
      state = state.copyWith(message: 'Chưa có lớp để xuất');
      return;
    }
    // Giữ provider sống trong lúc xuất (autoDispose).
    final sub = ref.listen(classDetailViewModelProvider(id), (_, s) {
      if (ref.mounted) state = state.copyWith(export: s.export);
    });
    final vm = ref.read(classDetailViewModelProvider(id).notifier);
    // Chờ dữ liệu lớp sẵn sàng rồi xuất.
    for (var i = 0; i < 50 && ref.read(classDetailViewModelProvider(id)).data is! Ready; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    try {
      await vm.exportPdf();
    } finally {
      if (ref.mounted) state = state.copyWith(export: ref.read(classDetailViewModelProvider(id)).export);
      sub.close();
    }
  }

  /// Lỗi xử lý được từ một đường lỗi thật: đọc file nhập lớp hỏng.
  Future<void> nonFatal() async {
    try {
      ref.read(importServiceProvider).fromRows(const [['khong_co_cot']], 'demo.csv', now: DateTime.now());
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'demo_import_parse');
      if (ref.mounted) state = state.copyWith(message: 'Đã gửi lỗi non-fatal');
    }
  }

  void crash() => ref.read(crashServiceProvider).testCrash();
  void messageShown() => state = state.copyWith();
}

// ---------------- Trung tâm thông báo ----------------

final notificationsProvider =
    StreamProvider.autoDispose<List<ReceivedNotification>>((ref) => ref.watch(messagingServiceProvider).watchInbox());

final notificationsViewModelProvider =
    NotifierProvider.autoDispose<NotificationsViewModel, ViewState<List<ReceivedNotification>>>(NotificationsViewModel.new);

class NotificationsViewModel extends Notifier<ViewState<List<ReceivedNotification>>> {
  @override
  ViewState<List<ReceivedNotification>> build() {
    final v = viewStateOf<List<ReceivedNotification>, List<ReceivedNotification>>(ref.watch(notificationsProvider), (l) => l);
    return switch (v) {
      Ready(:final data) when data.isEmpty => const Empty(),
      _ => v,
    };
  }

  Future<void> clear() => ref.read(messagingServiceProvider).clearInbox();
}

/// Dùng ở khu demo: danh sách lớp kỳ hiện tại để chọn xuất báo cáo.
final demoClassesProvider = Provider.autoDispose<List<SchoolClass>>((ref) {
  final f = ref.watch(lecturerFeedProvider).value;
  if (f == null) return const [];
  return f.classesOf(Term.of(ref.watch(clockProvider)()));
});
