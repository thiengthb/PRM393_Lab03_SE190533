import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../utils/calendar.dart';
import 'lecturer_feed.dart';

enum ScheduleView { today, week, month }

class DaySlots {
  const DaySlots(this.day, this.slots);
  final DateTime day;
  final List<Slot> slots;
}

class ScheduleData {
  const ScheduleData({
    required this.view,
    required this.now,
    required this.term,
    required this.hasClasses,
    required this.days,
    required this.anchor,
    required this.selectedDay,
    required this.daysWithSlots,
    required this.nextUpcomingId,
  });

  final ScheduleView view;
  final DateTime now;
  final String term;
  final bool hasClasses;

  /// Nhóm theo ngày: 1 ngày (Hôm nay, ngày chọn trong tháng) hoặc 7 ngày (Tuần).
  final List<DaySlots> days;

  /// Thứ Hai của tuần đang xem, hoặc ngày 1 của tháng đang xem.
  final DateTime anchor;
  final DateTime selectedDay;
  final Set<int> daysWithSlots;

  /// Slot sắp tới gần nhất: chỉ thẻ này có đồng hồ xám.
  final String? nextUpcomingId;

  bool get isEmpty => days.every((d) => d.slots.isEmpty);
}

class ScheduleUi {
  const ScheduleUi({this.view = ScheduleView.today, this.weekOffset = 0, this.monthOffset = 0, this.selectedDay});
  final ScheduleView view;
  final int weekOffset;
  final int monthOffset;
  final DateTime? selectedDay;

  ScheduleUi copyWith({ScheduleView? view, int? weekOffset, int? monthOffset, DateTime? selectedDay}) => ScheduleUi(
        view: view ?? this.view,
        weekOffset: weekOffset ?? this.weekOffset,
        monthOffset: monthOffset ?? this.monthOffset,
        selectedDay: selectedDay ?? this.selectedDay,
      );
}

final _scheduleUiProvider = NotifierProvider<_ScheduleUiNotifier, ScheduleUi>(_ScheduleUiNotifier.new);

class _ScheduleUiNotifier extends Notifier<ScheduleUi> {
  @override
  ScheduleUi build() => const ScheduleUi();
  void set(ScheduleUi v) => state = v;
}

final scheduleViewModelProvider = NotifierProvider<ScheduleViewModel, ViewState<ScheduleData>>(ScheduleViewModel.new);

/// GV-002 Lịch: Hôm nay / Tuần / Tháng.
class ScheduleViewModel extends Notifier<ViewState<ScheduleData>> {
  @override
  ViewState<ScheduleData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final ui = ref.watch(_scheduleUiProvider);
    final now = ref.watch(clockProvider)();
    return viewStateOf(feed, (f) => _compute(f, ui, now));
  }

  ScheduleData _compute(LecturerFeed f, ScheduleUi ui, DateTime now) {
    final term = Term.of(now);
    List<Slot> on(DateTime d) => f.slots.where((s) => VnDate.sameDay(s.start, d)).toList();
    final upcoming = f.slots.where((s) => s.phaseAt(now) == SlotPhase.upcoming).toList();
    final next = upcoming.isEmpty ? null : upcoming.first.id; // slots đã xếp theo giờ

    late final DateTime anchor;
    late final List<DaySlots> days;
    var selected = ui.selectedDay ?? VnDate.dateOnly(now);
    final withSlots = <int>{};
    switch (ui.view) {
      case ScheduleView.today:
        anchor = VnDate.dateOnly(now);
        days = [DaySlots(anchor, on(anchor))];
      case ScheduleView.week:
        anchor = VnDate.mondayOf(now).add(Duration(days: 7 * ui.weekOffset));
        days = [
          for (var i = 0; i < 7; i++) DaySlots(anchor.add(Duration(days: i)), on(anchor.add(Duration(days: i)))),
        ].where((d) => d.slots.isNotEmpty).toList();
      case ScheduleView.month:
        anchor = DateTime(now.year, now.month + ui.monthOffset, 1);
        if (selected.month != anchor.month || selected.year != anchor.year) selected = anchor;
        for (final s in f.slots) {
          if (s.start.year == anchor.year && s.start.month == anchor.month) withSlots.add(s.start.day);
        }
        days = [DaySlots(selected, on(selected))];
    }
    return ScheduleData(
      view: ui.view,
      now: now,
      term: term,
      hasClasses: f.classesOf(term).isNotEmpty,
      days: days,
      anchor: anchor,
      selectedDay: selected,
      daysWithSlots: withSlots,
      nextUpcomingId: next,
    );
  }

  ScheduleUi get _ui => ref.read(_scheduleUiProvider);

  void setView(ScheduleView v) => ref.read(_scheduleUiProvider.notifier).set(ScheduleUi(view: v));
  void shift(int delta) {
    final u = _ui;
    ref.read(_scheduleUiProvider.notifier).set(u.view == ScheduleView.week
        ? u.copyWith(weekOffset: u.weekOffset + delta)
        : u.copyWith(monthOffset: u.monthOffset + delta));
  }

  void selectDay(DateTime d) => ref.read(_scheduleUiProvider.notifier).set(_ui.copyWith(selectedDay: d));
  void retry() => ref.invalidate(lecturerFeedProvider);
}
