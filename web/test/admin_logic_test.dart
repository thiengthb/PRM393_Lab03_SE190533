import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend_admin/router.dart';
import 'package:quick_attend_admin/viewmodels/announcements_viewmodel.dart';
import 'package:quick_attend_admin/viewmodels/subjects_viewmodel.dart';
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
    test('giảng viên, sinh viên, tài khoản mới bị chặn', () {
      for (final r in [UserRole.lecturer, UserRole.student, UserRole.user]) {
        expect(go('/dashboard', _user(r)), '/denied');
      }
    });
    test('giáo vụ vào được trang nhưng không vào /users', () {
      expect(go('/review', _user(UserRole.staff)), isNull);
      expect(go('/users', _user(UserRole.staff)), '/dashboard');
    });
    test('admin vào được /users', () => expect(go('/users', _user(UserRole.admin)), isNull));
  });
}
