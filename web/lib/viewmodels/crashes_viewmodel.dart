import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/crash_report.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/providers.dart';
import 'package:attendo_core/utils/app_exception.dart';

/// Stack đầy đủ, số máy bị ảnh hưởng, phiên bản app: xem trên Crashlytics console.
const crashlyticsConsoleUrl = 'https://console.firebase.google.com/project/hereby-se190533/crashlytics';

/// Số sự cố theo loại, để hiện ba ô tổng trên đầu trang (hàm thuần, có test).
Map<CrashKind, int> countByKind(List<CrashReport> items) => {
      for (final k in CrashKind.values) k: items.where((r) => r.kind == k).length,
    };

/// null = mọi loại.
List<CrashReport> filterCrashes(List<CrashReport> items, CrashKind? kind) =>
    kind == null ? items : items.where((r) => r.kind == kind).toList();

class CrashesState {
  const CrashesState({required this.items, this.counts = const {}, this.kind});
  final ViewState<List<CrashReport>> items;
  final Map<CrashKind, int> counts;
  final CrashKind? kind;
}

final _crashesProvider = StreamProvider.autoDispose<List<CrashReport>>(
    (ref) => ref.watch(crashReportRepositoryProvider).watchLatest(limit: 100));

final _kindFilter = NotifierProvider.autoDispose<_KindFilter, CrashKind?>(_KindFilter.new);

class _KindFilter extends Notifier<CrashKind?> {
  @override
  CrashKind? build() => null;
  void set(CrashKind? k) => state = k;
}

final crashesViewModelProvider = NotifierProvider.autoDispose<CrashesViewModel, CrashesState>(CrashesViewModel.new);

/// Màn Sự cố (chỉ Admin): 100 bản tóm tắt mới nhất app ghi vào `crashReports`.
class CrashesViewModel extends Notifier<CrashesState> {
  @override
  CrashesState build() {
    final kind = ref.watch(_kindFilter);
    return ref.watch(_crashesProvider).when(
          data: (d) {
            final f = filterCrashes(d, kind);
            return CrashesState(kind: kind, counts: countByKind(d), items: f.isEmpty ? const Empty() : Ready(f));
          },
          error: (e, _) => CrashesState(kind: kind, items: Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại')),
          loading: () => CrashesState(kind: kind, items: const Loading()),
        );
  }

  void setKind(CrashKind? k) => ref.read(_kindFilter.notifier).set(k == state.kind ? null : k);
  void retry() => ref.invalidate(_crashesProvider);
}
