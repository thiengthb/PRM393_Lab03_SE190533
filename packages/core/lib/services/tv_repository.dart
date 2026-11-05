import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

/// Màn chiếu TV-001 đọc đúng một tài liệu `tv/{key}`, không cần đăng nhập.
abstract class TvRepository {
  /// null khi khoá sai, link đã hết hạn (luật từ chối) hoặc tài liệu chưa có.
  Stream<TvFrame?> watch(String key);
}

class FirestoreTvRepository implements TvRepository {
  FirestoreTvRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<TvFrame?> watch(String key) => _db
      .collection('tv')
      .doc(key)
      .snapshots()
      .map<TvFrame?>((s) => s.exists ? Fs.tv(s.data()!) : null)
      // Khoá sai hoặc hết hạn: luật từ chối đọc, màn hiện .E thay vì lỗi.
      .transform(StreamTransformer<TvFrame?, TvFrame?>.fromHandlers(handleError: (e, st, sink) {
        if (e is FirebaseException && (e.code == 'permission-denied' || e.code == 'not-found')) {
          sink.add(null);
        } else {
          sink.addError(e, st);
        }
      }));
}
