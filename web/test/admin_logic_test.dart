import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend_admin/router.dart';
import 'package:quick_attend_admin/viewmodels/announcements_viewmodel.dart';
import 'package:quick_attend_admin/viewmodels/crashes_viewmodel.dart';
import 'package:quick_attend_admin/viewmodels/subjects_viewmodel.dart';
import 'package:quick_attend_core/models/crash_report.dart';
import 'package:quick_attend_core/models/models.dart';

const _subjects = [
  Subject(code: 'PRM393', name: 'Mobile Programming'),
  Subject(code: 'MMA301', name: 'Multiplatform Mobile'),
  Subject(code: 'OLD101', name: 'Môn cũ', status: CatalogStatus.archived),
];

AppUser _user(UserRole r) => AppUser(uid: 'u', role: r, displayName: 'A', email: 'a@x.vn');

void main() {
  group('validateSubject', () {
    test('mã sai định dạng và tên trống đều báo lỗi', () {
      final e = validateSubject('pr', ' ');
      expect(e.keys, containsAll(['code', 'name']));
    });
    test('mã thường được chấp nhận vì sẽ viết hoa khi lưu', () {
      expect(validateSubject('prm393', 'Mobile'), isEmpty);
    });
  });

  group('filterSubjects', () {
    test('tìm theo tên, không phân biệt hoa thường, bỏ môn lưu trữ', () {
      final f = filterSubjects(_subjects, query: 'mobile', archived: false);
      expect(f.map((s) => s.code), ['PRM393', 'MMA301']);
    });
    test('tab lưu trữ chỉ hiện môn lưu trữ', () {
      expect(filterSubjects(_subjects, query: '', archived: true).single.code, 'OLD101');
    });
  });

  test('validateAnnouncement giới hạn độ dài như Security Rules', () {
    expect(validateAnnouncement('a' * 121, 'b').containsKey('title'), isTrue);
    expect(validateAnnouncement('a', 'b' * 1001).containsKey('body'), isTrue);
    expect(validateAnnouncement('a', 'b'), isEmpty);
  });

  group('resolveAdminRedirect', () {
    String? go(String loc, AppUser? u, {String? uid = 'u'}) =>
        resolveAdminRedirect(location: loc, uid: AsyncValue.data(uid), user: AsyncValue.data(u));

    test('chưa đăng nhập về /login', () => expect(go('/dashboard', null, uid: null), '/login'));
    test('chỉ Admin vào được: giảng viên, sinh viên, giáo vụ, tài khoản mới bị chặn', () {
      for (final r in [UserRole.lecturer, UserRole.student, UserRole.staff, UserRole.user]) {
        expect(go('/dashboard', _user(r)), '/denied');
      }
    });
    test('admin vào được mọi trang, kể cả /users và /crashes', () {
      expect(go('/review', _user(UserRole.admin)), isNull);
      expect(go('/users', _user(UserRole.admin)), isNull);
      expect(go('/crashes', _user(UserRole.admin)), isNull);
    });
  });

  group('sự cố', () {
    CrashReport r(CrashKind k) => CrashReport(uid: 'u', role: 'lecturer', kind: k, where: 'w', message: 'm', platform: 'android');
    final items = [r(CrashKind.testCrash), r(CrashKind.nonFatal), r(CrashKind.nonFatal)];

    test('đếm theo loại, loại chưa có thì bằng 0', () {
      expect(countByKind(items), {CrashKind.testCrash: 1, CrashKind.nonFatal: 2, CrashKind.flutterError: 0});
    });
    test('lọc theo loại, null là tất cả', () {
      expect(filterCrashes(items, CrashKind.nonFatal), hasLength(2));
      expect(filterCrashes(items, null), hasLength(3));
    });
    test('cắt câu lỗi dài như Security Rules', () {
      final s = CrashReport.clip('a' * 600, 500);
      expect(s.length, 500);
      expect(s.endsWith('…'), isTrue);
    });
  });
}
