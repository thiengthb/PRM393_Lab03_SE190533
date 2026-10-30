import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend/firebase/config_service.dart';
import 'package:quick_attend/models/models.dart';
import 'package:quick_attend/models/view_state.dart';
import 'package:quick_attend/providers.dart';
import 'package:quick_attend/viewmodels/lecturer_feed.dart';
import 'package:quick_attend/viewmodels/overview_viewmodel.dart';

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
}
