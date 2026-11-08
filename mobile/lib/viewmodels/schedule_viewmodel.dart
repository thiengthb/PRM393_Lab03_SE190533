import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import '../providers.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'lecturer_feed.dart';

/// GV-002 Điểm danh v2: hàng chuyển tuần, dải T2 đến CN, bấm ngày xem slot của ngày đó.
class ScheduleData {
  const ScheduleData({
    required this.now,
    required this.term,
    required this.hasClasses,
    required this.weekStart,
    required this.selectedDay,
    required this.slots,
    required this.daysWithSlots,
    required this.nextUpcomingId,
    this.weekSlots = const [],
  });

  final DateTime now;
  final String term;
  final bool hasClasses;

  /// Thứ Hai của tuần đang xem.
  final DateTime weekStart;
  final DateTime selectedDay;

  /// Slot của ngày đang chọn, theo giờ.
  final List<Slot> slots;

  /// Ngày trong tuần có slot (0 = T2 … 6 = CN).
  final Set<int> daysWithSlots;

  /// Slot sắp tới gần nhất: chỉ thẻ này có đồng hồ xám.
  final String? nextUpcomingId;

  /// Desktop week grid: every slot of the week being viewed.
  final List<Slot> weekSlots;

  List<DateTime> get week => [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
  bool get isEmpty => slots.isEmpty;
}

class ScheduleUi {
  const ScheduleUi({this.weekOffset = 0, this.selectedDay});
  final int weekOffset;
  final DateTime? selectedDay;
}

final _scheduleUiProvider = NotifierProvider<_ScheduleUiNotifier, ScheduleUi>(_ScheduleUiNotifier.new);

class _ScheduleUiNotifier extends Notifier<ScheduleUi> {
  @override
  ScheduleUi build() => const ScheduleUi();
  void set(ScheduleUi v) => state = v;
}

final scheduleViewModelProvider = NotifierProvider<ScheduleViewModel, ViewState<ScheduleData>>(ScheduleViewModel.new);

class ScheduleViewModel extends Notifier<ViewState<ScheduleData>> {
  @override
  ViewState<ScheduleData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final ui = ref.watch(_scheduleUiProvider);
    final now = ref.watch(clockProvider)();
    return viewStateOf(feed, (f) => compute(f, ui, now));
  }

  ScheduleData compute(LecturerFeed f, ScheduleUi ui, DateTime now) {
    final term = Term.of(now);
    final weekStart = VnDate.mondayOf(now).add(Duration(days: 7 * ui.weekOffset));
    final weekEnd = weekStart.add(const Duration(days: 7));
    var selected = ui.selectedDay ?? VnDate.dateOnly(now);
    if (selected.isBefore(weekStart) || !selected.isBefore(weekEnd)) {
      // Chuyển tuần mà chưa chọn ngày: giữ đúng thứ đang chọn.
      selected = weekStart.add(Duration(days: selected.weekday - 1));
    }
    final upcoming = f.slots.where((s) => s.phaseAt(now) == SlotPhase.upcoming).toList();
    final withSlots = <int>{
      for (final s in f.slots)
        if (!s.start.isBefore(weekStart) && s.start.isBefore(weekEnd)) s.start.weekday - 1,
    };
    return ScheduleData(
      now: now,
      term: term,
      hasClasses: f.classesOf(term).isNotEmpty,
      weekStart: weekStart,
      selectedDay: selected,
      slots: f.slots.where((s) => VnDate.sameDay(s.start, selected)).toList(),
      weekSlots: f.slots.where((s) => !s.start.isBefore(weekStart) && s.start.isBefore(weekEnd)).toList(),
      daysWithSlots: withSlots,
      nextUpcomingId: upcoming.isEmpty ? null : upcoming.first.id, // slots đã xếp theo giờ
    );
  }

  ScheduleUi get _ui => ref.read(_scheduleUiProvider);
  void _set(ScheduleUi u) => ref.read(_scheduleUiProvider.notifier).set(u);

  void shiftWeek(int delta) {
    final u = _ui;
    final sel = u.selectedDay;
    _set(ScheduleUi(weekOffset: u.weekOffset + delta, selectedDay: sel?.add(Duration(days: 7 * delta))));
  }

  void selectDay(DateTime d) => _set(ScheduleUi(weekOffset: _ui.weekOffset, selectedDay: VnDate.dateOnly(d)));

  /// Từ lịch tháng ở Tổng quan: mở đúng tuần và ngày đã bấm.
  void showDay(DateTime d) {
    final now = ref.read(clockProvider)();
    final weeks = (VnDate.mondayOf(d).difference(VnDate.mondayOf(now)).inHours / (24 * 7)).round();
    _set(ScheduleUi(weekOffset: weeks, selectedDay: VnDate.dateOnly(d)));
  }

  /// Desktop "Hôm nay": back to the current week, today selected.
  void thisWeek() => _set(const ScheduleUi());

  void retry() => ref.invalidate(lecturerFeedProvider);
}
