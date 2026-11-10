import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendo_core/services/firestore_mappers.dart';
import 'package:attendo_core/utils/app_exception.dart';

void main() {
  test('FirebaseException keeps its code mapping', () {
    final e = Fs.error(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
    expect(e.kind, AppErrorKind.permission);
  });

  // LOI-14: on web, aggregation queries throw the raw JS FirebaseError, not a FirebaseException.
  test('raw web FirebaseError with a missing index maps to the index message', () {
    final e = Fs.error(Exception(
        'FirebaseError: [code=failed-precondition]: The query requires an index. You can create it here: https://x'));
    expect(e.kind, AppErrorKind.invalid);
    expect(e.message, 'Thiếu chỉ mục dữ liệu');
  });

  test('raw web error in plugin format maps by code', () {
    expect(Fs.error(Exception('[cloud_firestore/unavailable] offline')).kind, AppErrorKind.network);
  });

  test('error without a code stays unknown', () {
    expect(Fs.error(StateError('boom')).kind, AppErrorKind.unknown);
  });
}
