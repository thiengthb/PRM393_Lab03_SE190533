import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend_core/firebase/config_service.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend/providers.dart';
import 'package:quick_attend_core/services/slot_repository.dart';
import 'package:quick_attend/viewmodels/lecturer_feed.dart';
import 'package:quick_attend/viewmodels/overview_viewmodel.dart';
import 'package:quick_attend/viewmodels/schedule_viewmodel.dart';

/// ViewModel test với dữ liệu giả: không cần Firebase vì service được tiêm qua provider.
void main() {
  final now = DateTime(2026, 10, 20, 7, 30); // Thứ Ba, slot 1 đang diễn ra
  const user = AppUser(uid: 'L1', role: UserRole.lecturer, displayName: 'Nguyễn Minh Quân', email: 'quanm@fe.edu.vn');
  const classA = SchoolClass(
      id: 'A', lecturerId: 'L1', term: 'Fall 2026', subject: 'PRM393', code: 'SE1801', studentCount: 35, totalSlots: 20);

  Slot slot(String id, DateTime start, {bool closed = false}) => Slot(
        id: id,
        lecturerId: 'L1',
        classId: 'A',
        subject: 'PRM393',
        classCode: 'SE1801',
        term: 'Fall 2026',
        start: start,
        end: start.add(const Duration(hours: 2, minutes: 15)),
        slotNo: 1,
        room: 'P.305',
        studentCount: 35,
        totalSlots: 20,
        closed: closed,
        presentCount: closed ? 34 : 0,
        absentCount: closed ? 1 : 0,
      );

  AttendanceRecord absent(String code, int day) => AttendanceRecord(
        slotId: 's$day',
        studentCode: code,
        studentName: 'Lê Thu Trang',
        present: false,
        source: AttendanceSource.auto,
        isFinal: true,
        classId: 'A',
        term: 'Fall 2026',
      );

  ProviderContainer make(LecturerFeed feed, {AppRemoteConfig cfg = const AppRemoteConfig()}) => ProviderContainer(overrides: [
        lecturerFeedProvider.overrideWith((ref) => Stream.value(feed)),
        remoteConfigProvider.overrideWith((ref) => Stream.value(cfg)),
        clockProvider.overrideWithValue(() => now),
      ]);

  Future<OverviewData> ready(ProviderContainer c) async {
    final sub = c.listen(overviewViewModelProvider, (_, _) {});
    for (var i = 0; i < 20 && c.read(overviewViewModelProvider) is! Ready; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    sub.close();
    return (c.read(overviewViewModelProvider) as Ready<OverviewData>).data;
  }

  test('GV-102: chỉ mở lại mã khi slot còn trong giờ học', () {
    final live = slot('today', DateTime(2026, 10, 20, 7));
    expect(live.canReopenQrAt(now), isTrue);
    // Slot hôm qua chưa chốt (FL-2 “Chốt ngay”): chỉ chốt tay, không mở lại mã.
    expect(slot('mon', DateTime(2026, 10, 19, 7)).canReopenQrAt(now), isFalse);
    expect(live.canReopenQrAt(live.end), isFalse);
    expect(slot('done', DateTime(2026, 10, 20, 7), closed: true).canReopenQrAt(now), isFalse);
  });

  test('GV-001 .D: thẻ slot đang diễn ra, Chú ý 5/4', () async {
    final c = make(LecturerFeed(
      user: user,
      classes: const [classA],
      slots: [slot('today', DateTime(2026, 10, 20, 7)), slot('mon', DateTime(2026, 10, 19, 7), closed: true)],
      records: [for (var d = 1; d <= 5; d++) absent('SE190142', d)],
      pending: const [],
    ));
    addTearDown(c.dispose);
    final d = await ready(c);
    expect(d.hasClasses, isTrue);
    expect(d.card?.id, 'today');
    expect(d.cardPhase, SlotPhase.live);
    expect(d.presentPercent, 97); // 34 / 35 trong tuần
    expect(d.attention.single.absent, 5);
    expect(d.attention.single.level, AbsenceLevel.over);
  });

  test('GV-001: hôm nay không còn slot thì thẻ là slot kế tiếp ở ngày sau', () async {
    final c = make(LecturerFeed(
      user: user,
      classes: const [classA],
      slots: [
        slot('done', DateTime(2026, 10, 13, 7), closed: true),
        slot('next', DateTime(2026, 10, 27, 7)),
        slot('later', DateTime(2026, 11, 3, 7)),
      ],
      records: const [],
      pending: const [],
    ));
    addTearDown(c.dispose);
    final d = await ready(c);
    expect(d.card?.id, 'next');
    expect(d.cardPhase, SlotPhase.upcoming);
  });

  test('GV-001 .E2: kỳ chưa có lớp', () async {
    final c = make(const LecturerFeed(user: user, classes: [], slots: [], records: [], pending: []));
    addTearDown(c.dispose);
    final d = await ready(c);
    expect(d.hasClasses, isFalse);
    expect(d.card, isNull);
  });

  test('Remote Config attention_preview_count giới hạn số hàng', () async {
    final records = [
      for (final code in ['SE190142', 'SE190155', 'SE190233'])
        for (var d = 1; d <= 3; d++) absent(code, d),
    ];
    final c = make(
      LecturerFeed(user: user, classes: const [classA], slots: const [], records: records, pending: const []),
      cfg: const AppRemoteConfig(attentionPreviewCount: 2),
    );
    addTearDown(c.dispose);
    final d = await ready(c);
    expect(d.attention, hasLength(2));
    expect(d.attentionTotal, 3);
  });

  test('GV-001 .D3: slot quên chốt ra dải riêng, thẻ là slot đang diễn ra; lịch tháng có chấm', () async {
    final c = make(LecturerFeed(
      user: user,
      classes: const [classA],
      slots: [
        slot('mon', DateTime(2026, 10, 19, 7)), // hết giờ, chưa chốt
        slot('today', DateTime(2026, 10, 20, 7)),
        slot('done', DateTime(2026, 10, 13, 7), closed: true),
        slot('next', DateTime(2026, 10, 27, 7)),
      ],
      records: const [],
      pending: const [],
    ));
    addTearDown(c.dispose);
    final d = await ready(c);
    expect(d.unclosed.map((s) => s.id), ['mon']);
    expect(d.card?.id, 'today');
    expect(d.monthSlotCount, 4);
    expect(d.monthDots[19], [DayDot.unclosed]);
    expect(d.monthDots[20], [DayDot.live]);
    expect(d.monthDots[13], [DayDot.closed]);
    expect(d.monthDots[27], [DayDot.upcoming]);
  });

  test('GV-002 v2: tuần chứa ngày đang chọn, chuyển tuần giữ thứ', () {
    final vm = ScheduleViewModel();
    final f = LecturerFeed(
      user: user,
      classes: const [classA],
      slots: [slot('mon', DateTime(2026, 10, 19, 7)), slot('today', DateTime(2026, 10, 20, 7))],
      records: const [],
      pending: const [],
    );
    final d = vm.compute(f, const ScheduleUi(), now);
    expect(d.weekStart, DateTime(2026, 10, 19));
    expect(d.selectedDay, DateTime(2026, 10, 20));
    expect(d.slots.single.id, 'today');
    expect(d.daysWithSlots, {0, 1});
    final next = vm.compute(f, const ScheduleUi(weekOffset: 1), now);
    expect(next.selectedDay, DateTime(2026, 10, 27));
    expect(next.slots, isEmpty);
  });

  test('GV-001 .X: báo Mất mạng khi lịch lấy từ bộ nhớ đệm, kèm giờ khớp máy chủ lần cuối', () async {
    final cache = StreamController<bool>();
    final c = ProviderContainer(overrides: [
      currentUserProvider.overrideWith((ref) => Stream.value(user)),
      slotRepositoryProvider.overrideWithValue(_CacheOnlySlotRepository(cache.stream)),
      offlineGraceProvider.overrideWithValue(Duration.zero),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    addTearDown(cache.close);
    final sub = c.listen(lecturerOfflineViewModelProvider, (_, _) {});
    addTearDown(sub.close);
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await settle();
    cache.add(false);
    await settle();
    expect(c.read(lecturerOfflineViewModelProvider), isNull);
    cache.add(true);
    await settle();
    expect(c.read(lecturerOfflineViewModelProvider)?.lastSync, now);
    cache.add(false);
    await settle();
    expect(c.read(lecturerOfflineViewModelProvider), isNull);
  });
}

/// Chỉ cần watchFromCache cho test mất mạng; các hàm khác không được gọi.
class _CacheOnlySlotRepository implements SlotRepository {
  _CacheOnlySlotRepository(this.cache);
  final Stream<bool> cache;

  @override
  Stream<bool> watchFromCache(String lecturerId) => cache;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
