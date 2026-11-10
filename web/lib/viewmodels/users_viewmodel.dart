import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/providers.dart';
import 'package:attendo_core/utils/app_exception.dart';

class UsersState {
  const UsersState({required this.items, this.query = '', this.meUid, this.message, this.isError = false});
  final ViewState<List<AppUser>> items;
  final String query;
  final String? meUid;
  final String? message;
  final bool isError;
}

class _Ui {
  const _Ui({this.query = '', this.message, this.isError = false});
  final String query;
  final String? message;
  final bool isError;
}

final _usersUi = NotifierProvider.autoDispose<_UsersUi, _Ui>(_UsersUi.new);

class _UsersUi extends Notifier<_Ui> {
  @override
  _Ui build() => const _Ui();
  void set(_Ui v) => state = v;
}

final _usersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) => ref.watch(userRepositoryProvider).watchAll());

final usersViewModelProvider = NotifierProvider.autoDispose<UsersViewModel, UsersState>(UsersViewModel.new);

/// Màn Người dùng (chỉ Admin): cấp vai trò. Không ai đổi được vai trò của chính mình.
class UsersViewModel extends Notifier<UsersState> {
  @override
  UsersState build() {
    final ui = ref.watch(_usersUi);
    final q = ui.query.trim().toLowerCase();
    return UsersState(
      query: ui.query,
      message: ui.message,
      isError: ui.isError,
      meUid: ref.watch(currentUserProvider).value?.uid,
      items: ref.watch(_usersProvider).when(
            data: (d) {
              final f = d
                  .where((u) => q.isEmpty || u.displayName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
                  .toList();
              return f.isEmpty ? const Empty() : Ready(f);
            },
            error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
            loading: () => const Loading(),
          ),
    );
  }

  void setQuery(String q) => ref.read(_usersUi.notifier).set(_Ui(query: q));
  void messageShown() => ref.read(_usersUi.notifier).set(_Ui(query: state.query));
  void retry() => ref.invalidate(_usersProvider);

  Future<void> setRole(AppUser u, UserRole role) async {
    if (u.uid == state.meUid || u.role == role) return;
    final q = state.query;
    try {
      await ref.read(userRepositoryProvider).setRole(u.uid, role);
      await ref.read(analyticsServiceProvider).roleChange(role: role.name);
      if (ref.mounted) ref.read(_usersUi.notifier).set(_Ui(query: q, message: 'Đã đổi vai trò'));
    } on AppException catch (e) {
      if (ref.mounted) ref.read(_usersUi.notifier).set(_Ui(query: q, message: e.message, isError: true));
    }
  }
}
