import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend/firebase/ai_service.dart';
import 'package:quick_attend/viewmodels/account_viewmodels.dart';
import 'package:quick_attend/viewmodels/inbox_viewmodel.dart';
import 'package:quick_attend_core/models/import_models.dart';
import 'package:quick_attend_core/models/models.dart';

void main() {
  group('ReminderDraft.parse', () {
    test('đọc JSON đúng lược đồ', () {
      final d = ReminderDraft.parse({'tone': 'firm', 'message': 'Em đã vắng 3 buổi.', 'next_step': 'Em nên gặp thầy.'});
      expect(d?.fullText, 'Em đã vắng 3 buổi. Em nên gặp thầy.');
    });
    test('từ chối thiếu trường, sai tone, quá dài', () {
      expect(ReminderDraft.parse({'tone': 'firm', 'message': 'x'}), isNull);
      expect(ReminderDraft.parse({'tone': 'giận', 'message': 'x', 'next_step': ''}), isNull);
      expect(ReminderDraft.parse({'tone': 'firm', 'message': 'a' * 400, 'next_step': ''}), isNull);
    });
  });

  test('prompt chỉ chứa mã môn và số liệu', () {
    final p = buildReminderPrompt('{subject} {absent}/{limit} {held}/{total}',
        const ReminderInput(subject: 'PRM393', absent: 3, limit: 4, held: 6, total: 20));
    expect(p, 'PRM393 3/4 6/20');
  });

  group('hộp thư', () {
    final items = mergeInbox(
      [Announcement(id: 'a', title: 'A', body: '', audience: AnnouncementAudience.all, archived: false, publishedAt: DateTime(2026, 11, 1))],
      [InboxItem(id: 'p', title: 'P', body: '', at: DateTime(2026, 11, 2), personal: true)],
    );
    test('mới nhất đứng đầu', () => expect(items.map((i) => i.id), ['p', 'a']));
    test('đếm chưa đọc theo mốc', () {
      expect(unreadCount(items, null), 2);
      expect(unreadCount(items, DateTime(2026, 11, 1, 12)), 1);
      expect(unreadCount(items, DateTime(2026, 11, 3)), 0);
    });
  });

  group('checkSubjects', () {
    ImportPreview preview() => ImportPreview(
          fileName: 'f.csv',
          term: 'Fall 2026',
          weeks: 10,
          errors: const [],
          classes: [ImportedClass(subject: 'PRM393', code: 'SE1801'), ImportedClass(subject: 'XYZ999', code: 'SE1802')],
        );
    test('danh mục trống thì không kiểm', () => expect(checkSubjects(preview(), const {}).hasErrors, isFalse));
    test('môn ngoài danh mục thành dòng lỗi và bị loại khỏi lớp nhập', () {
      final p = checkSubjects(preview(), const {'PRM393'});
      expect(p.classes.single.subject, 'PRM393');
      expect(p.errors.single.message, contains('XYZ999'));
    });
  });
}
