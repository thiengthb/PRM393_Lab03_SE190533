import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/firebase/config_service.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/providers.dart';
import 'package:quick_attend_core/services/dashboard_repository.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

class DashboardData {
  const DashboardData({required this.figures, required this.rates});
  final DashboardFigures figures;

  /// Môn có tỉ lệ có mặt thấp nhất đứng đầu: việc cần xem trước.
  final List<SubjectRate> rates;
}

final dashboardViewModelProvider =
    NotifierProvider.autoDispose<DashboardViewModel, ViewState<DashboardData>>(DashboardViewModel.new);

class DashboardViewModel extends Notifier<ViewState<DashboardData>> {
  @override
  ViewState<DashboardData> build() {
    Future.microtask(load);
    return const Loading();
  }

  /// Aggregation query không có thời gian thực: tải khi mở màn và khi bấm Tải lại.
  Future<void> load() async {
    state = const Loading();
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final cfg = ref.read(remoteConfigProvider).value ?? const AppRemoteConfig();
      final figures = await repo.figures();
      final subjects = await ref.read(subjectRepositoryProvider).activeCodes();
      final rates = await repo.rateBySubject(subjects);
      if (!ref.mounted) return;
      final empty = figures.pendingClasses == 0 && figures.approvedClasses == 0 && figures.closedSlots == 0;
      state = empty
          ? const Empty()
          : Ready(DashboardData(figures: figures, rates: rates.take(cfg.dashboardTopSubjects).toList()));
    } on AppException catch (e) {
      if (ref.mounted) state = Failure(e.message);
    }
  }
}
