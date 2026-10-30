import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/config_service.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../services/report_service.dart';
import '../utils/app_exception.dart';
import '../utils/calendar.dart';
import 'lecturer_feed.dart';

// ---------------- GV-003 Lớp ----------------

class ClassItem {
  const ClassItem(this.schoolClass, this.attentionCount);
  final SchoolClass schoolClass;
  final int attentionCount;
}

class ClassesData {
  const ClassesData({required this.terms, required this.term, required this.items, required this.currentTerm});
  final List<String> terms;
  final String term;
  final String currentTerm;
  final List<ClassItem> items;
}

final _selectedTermProvider = NotifierProvider<_TermNotifier, String?>(_TermNotifier.new);

class _TermNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String t) => state = t;
}

final classesViewModelProvider = NotifierProvider<ClassesViewModel, ViewState<ClassesData>>(ClassesViewModel.new);

class ClassesViewModel extends Notifier<ViewState<ClassesData>> {
  @override
  ViewState<ClassesData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final selected = ref.watch(_selectedTermProvider);
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final now = ref.watch(clockProvider)();
    return viewStateOf(feed, (f) {
      final current = Term.of(now);
      // Kỳ hiện tại luôn có chip dù chưa có lớp (GV-003 .D2 kỳ mới đứng đầu).
      final terms = {current, ...f.classes.map((c) => c.term)}.toList()
        ..sort((a, b) => Term.sortKey(b).compareTo(Term.sortKey(a)));
      final term = selected ?? current;
      final classes = f.classesOf(term);
      final attention = ref.read(aggregatorProvider).attention(classes, f.records, percent: cfg.absenceLimitPercent);
      return ClassesData(
        terms: terms,
        term: term,
        currentTerm: current,
        items: [for (final c in classes) ClassItem(c, attention.where((a) => a.schoolClass.id == c.id).length)],
      );
    });
  }

  void selectTerm(String t) => ref.read(_selectedTermProvider.notifier).set(t);
  void retry() => ref.invalidate(lecturerFeedProvider);
}

// ---------------- GV-103 Chi tiết lớp ----------------

enum ClassTab { students, sessions }

class ClassDetailData {
  const ClassDetailData({
    required this.schoolClass,
    required this.held,
    required this.limit,
    required this.students,
    required this.sessions,
  });

  final SchoolClass schoolClass;
  final int held;
  final int limit;
  final List<StudentAbsence> students;

  /// Buổi đã học (đã chốt hoặc đã qua), mới nhất trước.
  final List<Slot> sessions;
}

class ClassDetailState {
  const ClassDetailState({
    this.data = const Loading(),
    this.tab = ClassTab.students,
    this.query = '',
    this.export = const ExportIdle(),
  });

  final ViewState<ClassDetailData> data;
  final ClassTab tab;
  final String query;
  final ExportState export;

  ClassDetailState copyWith({ViewState<ClassDetailData>? data, ClassTab? tab, String? query, ExportState? export}) =>
      ClassDetailState(data: data ?? this.data, tab: tab ?? this.tab, query: query ?? this.query, export: export ?? this.export);

  /// Lọc theo tên hoặc MSSV (lọc ở ViewModel, không ở build()).
  List<StudentAbsence> get visibleStudents {
    final d = data.dataOrNull;
    if (d == null) return const [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return d.students;
    return d.students
        .where((s) => s.student.name.toLowerCase().contains(q) || s.student.code.toLowerCase().contains(q))
        .toList();
  }
}

sealed class ExportState {
  const ExportState();
}

class ExportIdle extends ExportState {
  const ExportIdle();
}

class ExportRunning extends ExportState {
  const ExportRunning(this.progress, this.step);
  final double progress;
  final String step;
}

class ExportDone extends ExportState {
  const ExportDone(this.url, this.path, this.sizeKb);
  final String url;
  final String path;
  final int sizeKb;
}

class ExportFailed extends ExportState {
  const ExportFailed(this.message);
  final String message;
}

/// Tab, ô tìm và trạng thái xuất PDF: giữ riêng để không mất khi dữ liệu cập nhật.
final _classUiProvider =
    NotifierProvider.autoDispose.family<_ClassUiNotifier, ClassDetailState, String>((_) => _ClassUiNotifier());

class _ClassUiNotifier extends Notifier<ClassDetailState> {
  @override
  ClassDetailState build() => const ClassDetailState();
  void update(ClassDetailState Function(ClassDetailState) f) => state = f(state);
}

/// Danh sách sinh viên của một lớp (thời gian thực).
final classStudentsProvider = StreamProvider.autoDispose.family<List<Student>, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).watchStudents(classId),
);

final classDetailViewModelProvider =
    NotifierProvider.autoDispose.family<ClassDetailViewModel, ClassDetailState, String>(ClassDetailViewModel.new);

class ClassDetailViewModel extends Notifier<ClassDetailState> {
  ClassDetailViewModel(this.classId);

  final String classId;
  bool _logged = false;

  @override
  ClassDetailState build() {
    final feed = ref.watch(lecturerFeedProvider);
    final students = ref.watch(classStudentsProvider(classId));
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final now = ref.watch(clockProvider)();
    final ui = ref.watch(_classUiProvider(classId));

    final ViewState<ClassDetailData> data;
    if (feed.hasError || students.hasError) {
      final e = feed.error ?? students.error;
      data = Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại');
    } else if (!feed.hasValue || !students.hasValue) {
      data = const Loading();
    } else {
      final d = _compute(feed.requireValue, students.requireValue, cfg, now);
      data = d == null ? const Failure('Không tìm thấy lớp', canRetry: false) : Ready(d);
    }
    if (data is Ready<ClassDetailData> && !_logged) {
      _logged = true;
      final c = data.data.schoolClass;
      ref.read(analyticsServiceProvider).viewClass(classId: c.id, subject: c.subject);
    }
    return ClassDetailState(data: data, tab: ui.tab, query: ui.query, export: ui.export);
  }

  ClassDetailData? _compute(LecturerFeed f, List<Student> students, AppRemoteConfig cfg, DateTime now) {
    final c = f.classes.where((x) => x.id == classId).firstOrNull;
    if (c == null) return null;
    final slots = f.slots.where((s) => s.classId == classId).toList();
    final held = slots.where((s) => s.closed).toList()..sort((a, b) => b.start.compareTo(a.start));
    final past = slots.where((s) => !s.closed && s.start.isBefore(now)).toList();
    final sessions = [...held, ...past]..sort((a, b) => b.start.compareTo(a.start));
    return ClassDetailData(
      schoolClass: c,
      held: held.length,
      limit: AttendanceMath.limit(c.totalSlots, cfg.absenceLimitPercent),
      students: ref.read(aggregatorProvider).roster(c, students, f.records, percent: cfg.absenceLimitPercent),
      sessions: sessions,
    );
  }

  _ClassUiNotifier get _ui => ref.read(_classUiProvider(classId).notifier);
  void setTab(ClassTab t) => _ui.update((u) => u.copyWith(tab: t));
  void setQuery(String q) => _ui.update((u) => u.copyWith(query: q));
  void _setExport(ExportState e) => _ui.update((u) => u.copyWith(export: e));
  void retry() {
    ref.invalidate(classStudentsProvider(classId));
    ref.invalidate(lecturerFeedProvider);
  }

  /// Sinh PDF đúng nội dung màn đang hiện, tải lên Storage, trả URL.
  Future<void> exportPdf() async {
    final d = state.data.dataOrNull;
    final user = ref.read(currentUserProvider).value;
    if (d == null || user == null) return;
    _setExport(const ExportRunning(0, 'Đang tạo PDF'));
    try {
      final Uint8List bytes = await ref.read(reportServiceProvider).buildClassReport(ClassReport(
            schoolClass: d.schoolClass,
            rows: d.students,
            heldSlots: d.held,
            limit: d.limit,
            generatedAt: ref.read(clockProvider)(),
            lecturerName: user.displayName,
          ));
      final now = ref.read(clockProvider)();
      final name = '${d.schoolClass.subject}-${d.schoolClass.code}-'
          '${now.year}${VnDate.two(now.month)}${VnDate.two(now.day)}-${VnDate.two(now.hour)}${VnDate.two(now.minute)}.pdf';
      await for (final p in ref.read(storageServiceProvider).uploadReport(user.uid, name, bytes)) {
        if (!ref.mounted) return;
        if (p.done) {
          final kb = (bytes.length / 1024).ceil();
          _setExport(ExportDone(p.url!, p.path ?? name, kb));
          await ref.read(analyticsServiceProvider).exportReport(classId: d.schoolClass.id, fileSizeKb: kb);
        } else {
          _setExport(ExportRunning(p.fraction, 'Đang tải lên'));
        }
      }
    } on AppException catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'export_report');
      if (ref.mounted) _setExport(ExportFailed(e.message));
    } catch (e, st) {
      await ref.read(crashServiceProvider).recordNonFatal(e, st, where: 'export_report');
      if (ref.mounted) _setExport(const ExportFailed('Không tạo được PDF'));
    }
  }

  void clearExport() => _setExport(const ExportIdle());
}
