import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend/models/models.dart';
import 'package:quick_attend/router.dart';
import 'package:quick_attend/services/attendance_aggregator.dart';
import 'package:quick_attend/services/import_service.dart';
import 'package:quick_attend/services/student_attendance_repository.dart';
import 'package:quick_attend/utils/app_exception.dart';
import 'package:quick_attend/utils/calendar.dart';

SchoolClass cls(String id, {int total = 20}) =>
    SchoolClass(id: id, lecturerId: 'L1', term: 'Fall 2026', subject: 'PRM393', code: id, studentCount: 3, totalSlots: total);

AttendanceRecord rec(String classId, String code, bool present, {bool fin = true, int day = 1}) => AttendanceRecord(
      slotId: '$classId-$day',
      studentCode: code,
      studentName: 'SV $code',
      present: present,
      source: AttendanceSource.auto,
      isFinal: fin,
      classId: classId,
      subject: 'PRM393',
      classCode: classId,
      term: 'Fall 2026',
      start: DateTime(2026, 10, day),
      totalSlots: 20,
    );

void main() {
  group('Term và lịch', () {
    test('kỳ theo tháng (D-18)', () {
      expect(Term.of(DateTime(2026, 10, 20)), 'Fall 2026');
      expect(Term.of(DateTime(2027, 2, 1)), 'Spring 2027');
      expect(Term.of(DateTime(2026, 6, 1)), 'Summer 2026');
      expect(Term.sortKey('Spring 2027') > Term.sortKey('Fall 2026'), isTrue);
    });

    test('ngày tiếng Việt như Figma', () {
      expect(VnDate.dayLabel(DateTime(2026, 10, 20)), 'Thứ Ba, 20/10');
      expect(VnDate.range(DateTime(2026, 1, 1, 7), DateTime(2026, 1, 1, 9, 15)), '07:00 – 09:15');
      expect(VnDate.countdown(const Duration(minutes: 4, seconds: 12)), '04:12');
    });

    test('ngưỡng vắng 20% của 20 buổi là 4', () {
      expect(AttendanceMath.limit(20, 20), 4);
      expect(AttendanceMath.limit(0, 20), 0);
      expect(AttendanceMath.presentPercent(94, 6), 94);
      expect(AttendanceMath.presentPercent(0, 0), isNull);
    });
  });

  group('AttendanceAggregator', () {
    const agg = AttendanceAggregator();

    test('chỉ đếm bản ghi đã chốt; 5/4 là vượt, 3/4 là sắp chạm', () {
      final records = [
        for (var d = 1; d <= 5; d++) rec('A', 'SE190142', false, day: d), // 5 vắng
        for (var d = 1; d <= 3; d++) rec('A', 'SE190155', false, day: d), // 3 vắng
        rec('A', 'SE190101', false, day: 1),
        rec('A', 'SE190101', false, day: 2, fin: false), // chưa chốt: không tính
      ];
      final list = agg.attention([cls('A')], records, percent: 20);
      expect(list.map((a) => '${a.student.code}:${a.absent}/${a.limit}:${a.level.name}'), [
        'SE190142:5/4:over',
        'SE190155:3/4:near',
      ]);
    });

    test('Remote Config đổi ngưỡng thì danh sách đổi theo', () {
      final records = [for (var d = 1; d <= 3; d++) rec('A', 'SE190155', false, day: d)];
      expect(agg.attention([cls('A')], records, percent: 20), hasLength(1));
      expect(agg.attention([cls('A')], records, percent: 40), isEmpty); // ngưỡng 8
    });

    test('bySubject: 7/10 có mặt, còn 1 buổi được vắng → near', () {
      final mine = [
        for (var d = 1; d <= 7; d++) rec('A', 'SE190601', true, day: d),
        for (var d = 8; d <= 10; d++) rec('A', 'SE190601', false, day: d),
      ];
      final s = agg.bySubject(mine, percent: 20).single;
      expect(s.attended, 7);
      expect(s.held, 10);
      expect(s.remaining, 1);
      expect(s.level, AbsenceLevel.near);
      expect(s.sessions.first.start, DateTime(2026, 10, 10)); // mới nhất trước
    });
  });

  group('ImportService', () {
    const svc = ImportService();
    final now = DateTime(2026, 10, 20);

    test('file mẫu đọc được 2 lớp, không lỗi', () {
      final p = svc.parse(Uint8List.fromList(utf8.encode(ImportService.template)), 'mau.csv', now: now);
      expect(p.errors, isEmpty);
      expect(p.classes.map((c) => c.label), ['MMA301 · SE1805', 'PRM393 · SE1801']);
      expect(p.weeklySlotCount, 4);
      expect(p.term, 'Fall 2026');
    });

    test('GV-100 .X: thiếu MSSV và MSSV trùng thành lỗi dòng', () {
      const csv = 'mon;lop;mssv;ho_ten;lich\n'
          'PRM393;SE1801;SE190142;Lê Thu Trang;T3-S1-P.305\n'
          'PRM393;SE1801;;Không MSSV;\n'
          'PRM393;SE1801;SE190142;Trùng;\n';
      final p = svc.parse(Uint8List.fromList(utf8.encode(csv)), 'lop.csv', now: now);
      expect(p.errors.map((e) => '${e.row}:${e.message}'), ['3:Thiếu MSSV', '4:MSSV SE190142 bị trùng']);
      expect(p.classes.single.students, hasLength(1));
    });

    test('thiếu cột bắt buộc → AppException', () {
      expect(
        () => svc.parse(Uint8List.fromList(utf8.encode('ten,lop\nA,B\n')), 'x.csv', now: now),
        throwsA(isA<AppException>()),
      );
    });

    test('CR-05: đọc được file .xlsx (ô chữ, ô số, ô ngày)', () {
      final book = Excel.createExcel();
      final sheet = book['Sheet1'];
      sheet.appendRow([for (final h in ['mon', 'lop', 'mssv', 'ho_ten', 'lich', 'bat_dau']) TextCellValue(h)]);
      sheet.appendRow([
        TextCellValue('PRN221'),
        TextCellValue('SE1810'),
        TextCellValue('SE190377'),
        TextCellValue('Võ Thị Hạnh'),
        TextCellValue('T4-S4-P.210;T6-S3-P.210'),
        DateCellValue(year: 2026, month: 9, day: 7),
      ]);
      final bytes = Uint8List.fromList(book.save()!);
      final p = svc.parse(bytes, 'lop.xlsx', now: now);
      expect(p.errors, isEmpty);
      expect(p.classes.single.label, 'PRN221 · SE1810');
      expect(p.classes.single.students.single.name, 'Võ Thị Hạnh');
      expect(p.classes.single.termStart, DateTime(2026, 9, 7));
      expect(ImportService.cellText(DoubleCellValue(12.0)), '12');
    });

    test('lịch sai định dạng', () {
      expect(ImportService.parseSchedule('T3-S1-P.305;T5-S1-P.305'), hasLength(2));
      expect(ImportService.parseSchedule('Thu3 slot1'), isNull);
      expect(ImportService.parseSchedule('T3-S9-P.1'), isNull);
    });
  });

  group('QrPayload', () {
    test('mã hợp lệ và mã lạ', () {
      final p = QrPayload.tryParse(const QrPayload(
        slotId: 'slot1',
        token: 'ABC123',
        classId: 'A',
        subject: 'PRM393',
        startMs: 1792371600000,
        slotNo: 1,
        room: 'P.305',
        totalSlots: 20,
      ).encode());
      expect(p?.slotId, 'slot1');
      expect(p?.slotNo, 1);
      expect(p?.room, 'P.305');
      expect(QrPayload.tryParse('qa1|slot1|ABC'), isNull); // định dạng cũ
      expect(QrPayload.tryParse('https://example.com'), isNull);
    });
  });

  group('Điều hướng theo vai trò', () {
    const lecturer = AppUser(uid: 'u', role: UserRole.lecturer, displayName: 'Nguyễn Minh Quân', email: 'q@fe.edu.vn');
    String? go(String loc, {AppUser? user = lecturer, bool verified = true, UserRole portal = UserRole.lecturer, String? uid = 'u'}) =>
        resolveRedirect(
          location: loc,
          uid: AsyncData(uid),
          user: AsyncData(user),
          emailVerified: verified,
          googleUser: false,
          portal: portal,
        );

    test('chưa đăng nhập → /login', () => expect(go('/overview', uid: null), '/login'));
    test('chưa xác nhận email → /verify', () => expect(go('/overview', verified: false), '/verify'));
    test('đăng ký xong → GV-093', () => expect(go('/verify'), '/start'));
    test('giảng viên không vào web sinh viên', () => expect(go('/me'), '/overview'));
    test('sai vai trò → /blocked', () => expect(go('/overview', portal: UserRole.student), '/blocked'));
    test('chưa có hồ sơ → điền nốt', () => expect(go('/overview', user: null), '/signup?complete=1'));
  });
}
