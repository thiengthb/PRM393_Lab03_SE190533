import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/providers.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

/// Kiểm form môn học (hàm thuần, có test). Trả lỗi theo ô.
Map<String, String> validateSubject(String code, String name) {
  final e = <String, String>{};
  if (!RegExp(r'^[A-Z0-9]{3,10}$').hasMatch(code.trim().toUpperCase())) e['code'] = 'Mã môn dạng PRM393';
  final n = name.trim();
  if (n.isEmpty) e['name'] = 'Nhập tên môn';
  if (n.length > 120) e['name'] = 'Tên tối đa 120 ký tự';
  return e;
}

/// Lọc theo mã hoặc tên, không phân biệt hoa thường (hàm thuần, có test).
List<Subject> filterSubjects(List<Subject> all, {required String query, required bool archived}) {
  final q = query.trim().toLowerCase();
  return all
      .where((s) => s.isActive != archived)
      .where((s) => q.isEmpty || s.code.toLowerCase().contains(q) || s.name.toLowerCase().contains(q))
      .toList();
}

class SubjectsState {
  const SubjectsState({
    required this.items,
    this.query = '',
    this.archived = false,
    this.fieldErrors = const {},
    this.saving = false,
    this.message,
    this.isError = false,
  });
  final ViewState<List<Subject>> items;
  final String query;
  final bool archived;
  final Map<String, String> fieldErrors;
  final bool saving;
  final String? message;
  final bool isError;
}

class _SubjectsUi {
  const _SubjectsUi({this.query = '', this.archived = false, this.fieldErrors = const {}, this.saving = false, this.message, this.isError = false});
  final String query;
  final bool archived;
  final Map<String, String> fieldErrors;
  final bool saving;
  final String? message;
  final bool isError;

  _SubjectsUi copy({String? query, bool? archived, Map<String, String>? fieldErrors, bool? saving, String? message, bool isError = false}) =>
      _SubjectsUi(
        query: query ?? this.query,
        archived: archived ?? this.archived,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        saving: saving ?? this.saving,
        message: message,
        isError: isError,
      );
}

final _subjectsUiProvider = NotifierProvider.autoDispose<_SubjectsUiNotifier, _SubjectsUi>(_SubjectsUiNotifier.new);

class _SubjectsUiNotifier extends Notifier<_SubjectsUi> {
  @override
  _SubjectsUi build() => const _SubjectsUi();
  void set(_SubjectsUi v) => state = v;
}

final _allSubjectsProvider = StreamProvider.autoDispose<List<Subject>>((ref) => ref.watch(subjectRepositoryProvider).watchAll());

final subjectsViewModelProvider = NotifierProvider.autoDispose<SubjectsViewModel, SubjectsState>(SubjectsViewModel.new);

class SubjectsViewModel extends Notifier<SubjectsState> {
  @override
  SubjectsState build() {
    final ui = ref.watch(_subjectsUiProvider);
    final all = ref.watch(_allSubjectsProvider);
    return SubjectsState(
      query: ui.query,
      archived: ui.archived,
      fieldErrors: ui.fieldErrors,
      saving: ui.saving,
      message: ui.message,
      isError: ui.isError,
      items: all.when(
        data: (d) {
          final f = filterSubjects(d, query: ui.query, archived: ui.archived);
          return f.isEmpty ? const Empty() : Ready(f);
        },
        error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
        loading: () => const Loading(),
      ),
    );
  }

  _SubjectsUiNotifier get _ui => ref.read(_subjectsUiProvider.notifier);
  _SubjectsUi get _cur => ref.read(_subjectsUiProvider);

  void setQuery(String q) => _ui.set(_cur.copy(query: q));
  void setArchived(bool v) => _ui.set(_cur.copy(archived: v));
  void clearForm() => _ui.set(_cur.copy(fieldErrors: const {}));
  void messageShown() => _ui.set(_cur.copy());
  void retry() => ref.invalidate(_allSubjectsProvider);

  /// Trả true khi lưu xong để màn đóng hộp thoại.
  Future<bool> save(String code, String name, {required bool isNew}) async {
    final e = validateSubject(code, name);
    if (e.isNotEmpty) {
      _ui.set(_cur.copy(fieldErrors: e));
      return false;
    }
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return false;
    _ui.set(_cur.copy(saving: true, fieldErrors: const {}));
    try {
      await ref.read(subjectRepositoryProvider).save(code: code.trim().toUpperCase(), name: name.trim(), actorUid: uid);
      await ref.read(analyticsServiceProvider).subjectSave(action: isNew ? 'create' : 'edit');
      if (ref.mounted) _ui.set(_cur.copy(saving: false, message: 'Đã lưu ${code.trim().toUpperCase()}'));
      return true;
    } on AppException catch (err) {
      if (ref.mounted) _ui.set(_cur.copy(saving: false, message: err.message, isError: true));
      return false;
    }
  }

  Future<void> setSubjectArchived(Subject s, bool archived) async {
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    try {
      await ref.read(subjectRepositoryProvider).setArchived(s.code, archived: archived, actorUid: uid);
      await ref.read(analyticsServiceProvider).subjectSave(action: archived ? 'archive' : 'restore');
      if (ref.mounted) _ui.set(_cur.copy(message: archived ? 'Đã lưu trữ ${s.code}' : 'Đã khôi phục ${s.code}'));
    } on AppException catch (err) {
      if (ref.mounted) _ui.set(_cur.copy(message: err.message, isError: true));
    }
  }
}
