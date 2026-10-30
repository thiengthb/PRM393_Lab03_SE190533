import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/config_service.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../providers.dart';
import '../utils/calendar.dart';
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
  });

  final String term;
  final DateTime today;

  /// false → GV-001 .E2: ô số “—”, ô trống “Chưa có lịch”.
  final bool hasClasses;
  final int classCount;
  final int studentCount;
  final int? presentPercent;
  final int pendingCount;

  /// Thẻ slot cần làm nhất hôm nay (chưa chốt > đang diễn ra > sắp tới). null → .E.
  final Slot? card;
  final SlotPhase? cardPhase;
  final List<StudentAbsence> attention;
  final int attentionTotal;
}

final overviewViewModelProvider = NotifierProvider<OverviewViewModel, ViewState<OverviewData>>(OverviewViewModel.new);

/// GV-001 Tổng quan.
class OverviewViewModel extends Notifier<ViewState<OverviewData>> {
  @override
  ViewState<OverviewData> build() {
    final feed = ref.watch(lecturerFeedProvider);
    final cfg = ref.watch(remoteConfigProvider).value ?? const AppRemoteConfig();
    final now = ref.watch(clockProvider)();
    return viewStateOf(feed, (f) => compute(f, cfg, now));
  }

  OverviewData compute(LecturerFeed f, AppRemoteConfig cfg, DateTime now) {
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

    final card = pick(SlotPhase.unclosed) ?? pick(SlotPhase.live) ?? pick(SlotPhase.upcoming);
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
    );
  }

  void retry() => ref.invalidate(lecturerFeedProvider);
}
