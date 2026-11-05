import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quick_attend_core/firebase/config_service.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import '../providers.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import 'lecturer_feed.dart';

class OverviewData {
  const OverviewData({
    required this.term,
    required this.today,
    required this.hasClasses,
    required this.classCount,
    required this.studentCount,
    required this.presentPercent,
    required this.pendingCount,
    required this.card,
    required this.cardPhase,
    required this.attention,
    required this.attentionTotal,
    this.inReview = const [],
    this.unread = 0,
    required this.unclosed,
    required this.month,
    required this.monthDots,
    required this.monthSlotCount,
  });

  final String term;
  final DateTime today;

  /// false → GV-001 .E2: ô số “—”, ô trống “Chưa có lịch”.
  final bool hasClasses;
  final int classCount;
  final int studentCount;
  final int? presentPercent;
  final int pendingCount;

  /// Thẻ slot hôm nay: đang diễn ra, nếu không thì sắp tới gần nhất. null → .E.
  final Slot? card;
  final SlotPhase? cardPhase;
  final List<StudentAbsence> attention;
  final int attentionTotal;

  /// Lớp đang chờ giáo vụ hoặc bị từ chối, hiện ngay đầu màn.
  final List<SchoolClass> inReview;
  final int unread;
  /// Slot đã hết giờ mà chưa chốt, mới nhất trước: 1 slot → dải .D3, nhiều slot → dải .D4 mở OV6.
  final List<Slot> unclosed;

  /// Ngày 1 của tháng đang xem ở lịch tháng.
  final DateTime month;
  final Map<int, List<DayDot>> monthDots;
  final int monthSlotCount;
}

/// Tháng đang xem ở lịch tháng GV-001 (0 = tháng này).
final _overviewMonthProvider = NotifierProvider<_MonthOffset, int>(_MonthOffset.new);

class _MonthOffset extends Notifier<int> {
  @override
  int build() => 0;
  void shift(int d) => state += d;
}

final overviewViewModelProvider = NotifierProvider<OverviewViewModel, ViewState<OverviewData>>(OverviewViewModel.new);

/// GV-001 Tổng quan.
class OverviewViewModel extends Notifier<ViewState<OverviewData>> {
  @override
  ViewState<OverviewData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final now = ref.watch(clockProvider)();
    final monthOffset = ref.watch(_overviewMonthProvider);
    return viewStateOf(feed, (f) => compute(f, cfg, now, monthOffset: monthOffset));
  }

  OverviewData compute(LecturerFeed f, AppRemoteConfig cfg, DateTime now, {int monthOffset = 0}) {
    final term = Term.of(now);
    final classes = f.classesOf(term);
    final termSlots = f.slots.where((s) => s.term == term).toList();
    final monday = VnDate.mondayOf(now);
    final week = termSlots.where((s) => s.closed && !s.start.isBefore(monday) && s.start.isBefore(monday.add(const Duration(days: 7))));
    final present = week.fold(0, (n, s) => n + s.presentCount);
    final absent = week.fold(0, (n, s) => n + s.absentCount);

    final today = termSlots.where((s) => VnDate.sameDay(s.start, now)).toList();
    Slot? pick(SlotPhase p) {
      for (final s in today) {
        if (s.phaseAt(now) == p) return s;
      }
      return null;
    }

    final card = pick(SlotPhase.live) ?? pick(SlotPhase.upcoming);
    final unclosed = termSlots.where((s) => s.phaseAt(now) == SlotPhase.unclosed).toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    final month = DateTime(now.year, now.month + monthOffset, 1);
    final inMonth = f.slots.where((s) => s.start.year == month.year && s.start.month == month.month).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final dots = <int, List<DayDot>>{};
    for (final s in inMonth) {
      dots.putIfAbsent(s.start.day, () => []).add(switch (s.phaseAt(now)) {
        SlotPhase.closed => DayDot.closed,
        SlotPhase.unclosed => DayDot.unclosed,
        SlotPhase.live => DayDot.live,
        SlotPhase.upcoming => DayDot.upcoming,
      });
    }
    final attention = ref
        .read(aggregatorProvider)
        .attention(classes, f.records.where((r) => r.term == term), percent: cfg.absenceLimitPercent);

    return OverviewData(
      term: term,
      today: now,
      hasClasses: classes.isNotEmpty,
      classCount: classes.length,
      studentCount: classes.fold(0, (n, c) => n + c.studentCount),
      presentPercent: AttendanceMath.presentPercent(present, absent),
      pendingCount: f.pending.length,
      card: card,
      cardPhase: card?.phaseAt(now),
      attention: attention.take(cfg.attentionPreviewCount).toList(),
      attentionTotal: attention.length,
      inReview: f.inReview.where((c) => c.term == term).toList(),
      unclosed: unclosed,
      month: month,
      monthDots: dots,
      monthSlotCount: inMonth.length,
    );
  }

  void shiftMonth(int delta) => ref.read(_overviewMonthProvider.notifier).shift(delta);

  void retry() => ref.invalidate(lecturerFeedProvider);
}
