import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/providers.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

/// Kiểm form thông báo (hàm thuần, có test).
Map<String, String> validateAnnouncement(String title, String body) {
  final e = <String, String>{};
  final t = title.trim();
  final b = body.trim();
  if (t.isEmpty) e['title'] = 'Nhập tiêu đề';
  if (t.length > 120) e['title'] = 'Tiêu đề tối đa 120 ký tự';
  if (b.isEmpty) e['body'] = 'Nhập nội dung';
  if (b.length > 1000) e['body'] = 'Nội dung tối đa 1000 ký tự';
  return e;
}

class AnnouncementsState {
  const AnnouncementsState({
    required this.items,
    this.audience = AnnouncementAudience.all,
    this.fieldErrors = const {},
    this.sending = false,
    this.sentCount = 0,
    this.message,
    this.isError = false,
  });
  final ViewState<List<Announcement>> items;
  final AnnouncementAudience audience;
  final Map<String, String> fieldErrors;
  final bool sending;

  /// Tăng sau mỗi lần đăng: màn xóa form khi số này đổi.
  final int sentCount;
  final String? message;
  final bool isError;
}

class _Ui {
  const _Ui({this.audience = AnnouncementAudience.all, this.fieldErrors = const {}, this.sending = false, this.sentCount = 0, this.message, this.isError = false});
  final AnnouncementAudience audience;
  final Map<String, String> fieldErrors;
  final bool sending;
  final int sentCount;
  final String? message;
  final bool isError;

  _Ui copy({AnnouncementAudience? audience, Map<String, String>? fieldErrors, bool? sending, int? sentCount, String? message, bool isError = false}) => _Ui(
        audience: audience ?? this.audience,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        sending: sending ?? this.sending,
        sentCount: sentCount ?? this.sentCount,
        message: message,
        isError: isError,
      );
}

final _uiProvider = NotifierProvider.autoDispose<_UiNotifier, _Ui>(_UiNotifier.new);

class _UiNotifier extends Notifier<_Ui> {
  @override
  _Ui build() => const _Ui();
  void set(_Ui v) => state = v;
}

final _allProvider = StreamProvider.autoDispose<List<Announcement>>((ref) => ref.watch(announcementRepositoryProvider).watchAll());

final announcementsViewModelProvider =
    NotifierProvider.autoDispose<AnnouncementsViewModel, AnnouncementsState>(AnnouncementsViewModel.new);

class AnnouncementsViewModel extends Notifier<AnnouncementsState> {
  @override
  AnnouncementsState build() {
    final ui = ref.watch(_uiProvider);
    final all = ref.watch(_allProvider);
    return AnnouncementsState(
      audience: ui.audience,
      fieldErrors: ui.fieldErrors,
      sending: ui.sending,
      sentCount: ui.sentCount,
      message: ui.message,
      isError: ui.isError,
      items: all.when(
        data: (d) => d.isEmpty ? const Empty() : Ready(d),
        error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
        loading: () => const Loading(),
      ),
    );
  }

  _UiNotifier get _n => ref.read(_uiProvider.notifier);
  _Ui get _c => ref.read(_uiProvider);

  void setAudience(AnnouncementAudience a) => _n.set(_c.copy(audience: a));
  void messageShown() => _n.set(_c.copy());
  void retry() => ref.invalidate(_allProvider);

  Future<void> publish(String title, String body) async {
    final e = validateAnnouncement(title, body);
    if (e.isNotEmpty) {
      _n.set(_c.copy(fieldErrors: e));
      return;
    }
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    _n.set(_c.copy(sending: true, fieldErrors: const {}));
    try {
      await ref.read(announcementRepositoryProvider).publish(
            title: title.trim(),
            body: body.trim(),
            audience: _c.audience,
            actorUid: uid,
          );
      await ref.read(analyticsServiceProvider).announcementPublish(audience: _c.audience.name);
      if (ref.mounted) _n.set(_c.copy(sending: false, sentCount: _c.sentCount + 1, message: 'Đã đăng thông báo'));
    } on AppException catch (err) {
      if (ref.mounted) _n.set(_c.copy(sending: false, message: err.message, isError: true));
    }
  }

  Future<void> setArchived(Announcement a, bool archived) async {
    try {
      await ref.read(announcementRepositoryProvider).setArchived(a.id, archived: archived);
      if (ref.mounted) _n.set(_c.copy(message: archived ? 'Đã lưu trữ' : 'Đã đăng lại'));
    } on AppException catch (err) {
      if (ref.mounted) _n.set(_c.copy(message: err.message, isError: true));
    }
  }
}
