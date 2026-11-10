import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

/// Danh mục môn: giáo vụ quản lý ở web admin, app đọc khi nhập lớp.
abstract class SubjectRepository {
  Stream<List<Subject>> watchAll();

  /// Mã các môn đang dùng (app kiểm file nhập lớp).
  Future<Set<String>> activeCodes();

  /// Tạo hoặc sửa theo mã môn.
  Future<void> save({required String code, required String name, required String actorUid});

  /// Không xóa cứng: lớp cũ vẫn trỏ tới mã môn.
  Future<void> setArchived(String code, {required bool archived, required String actorUid});
}

class FirestoreSubjectRepository implements SubjectRepository {
  FirestoreSubjectRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('subjects');

  @override
  Stream<List<Subject>> watchAll() => Fs.guard(
        _col.snapshots().map(
              (q) => q.docs.map((d) => Fs.subject(d.id, d.data())).toList()..sort((a, b) => a.code.compareTo(b.code)),
            ),
      );

  @override
  Future<Set<String>> activeCodes() async {
    try {
      final q = await _col.where('status', isEqualTo: CatalogStatus.active.name).get();
      return q.docs.map((d) => d.id).toSet();
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> save({required String code, required String name, required String actorUid}) async {
    try {
      await _col.doc(code).set({
        'code': code,
        'name': name,
        'status': CatalogStatus.active.name,
        'updatedBy': actorUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> setArchived(String code, {required bool archived, required String actorUid}) async {
    try {
      await _col.doc(code).update({
        'status': archived ? CatalogStatus.archived.name : CatalogStatus.active.name,
        'updatedBy': actorUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
