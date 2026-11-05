import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend/firebase/crash_service.dart';
import 'package:quick_attend_core/models/crash_report.dart';

void main() {
  group('FirebaseCrashService ghi kèm bản tóm tắt cho web admin', () {
    late List<(CrashKind, String, String)> sent;
    late FirebaseCrashService crash;

    setUp(() {
      sent = [];
      crash = FirebaseCrashService(null, report: (k, w, m) async => sent.add((k, w, m)));
    });

    test('lỗi non-fatal ghi loại, nơi xảy ra và câu lỗi', () async {
      await crash.recordNonFatal(StateError('hỏng'), null, where: 'import_open');
      expect(sent.single.$1, CrashKind.nonFatal);
      expect(sent.single.$2, 'import_open');
      expect(sent.single.$3, contains('hỏng'));
    });

    test('test crash ghi tóm tắt trước khi app thoát', () async {
      await expectLater(crash.testCrash(), throwsStateError);
      expect(sent.single.$1, CrashKind.testCrash);
    });
  });
}
