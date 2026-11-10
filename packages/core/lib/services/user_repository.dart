import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

abstract class UserRepository {
  Stream<AppUser?> watch(String uid);
  Future<AppUser?> get(String uid);
  Future<void> create(AppUser user);
  Future<void> setReminders(String uid, {bool? beforeSlot, bool? unclosed});
  Future<void> markImported(String uid);

  /// Đánh dấu đã đọc hộp thư đến thời điểm hiện tại.
  Future<void> markInboxRead(String uid);

  /// Chỉ Admin (Security Rules kiểm): danh sách và đổi vai trò.
  Stream<List<AppUser>> watchAll();
  Future<void> setRole(String uid, UserRole role);
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('users').doc(uid);

  @override
  Stream<AppUser?> watch(String uid) =>
      Fs.guard(_doc(uid).snapshots().map((s) => s.exists ? Fs.user(s.id, s.data()!) : null));

  @override
  Future<AppUser?> get(String uid) async {
    try {
      final s = await _doc(uid).get();
      return s.exists ? Fs.user(s.id, s.data()!) : null;
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> create(AppUser user) async {
    try {
      await _doc(user.uid).set({
        'role': user.role.name,
        'displayName': user.displayName,
        'email': user.email,
        if (user.studentCode != null) 'studentCode': user.studentCode,
        'reminderBeforeSlot': true,
        'reminderUnclosed': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> setReminders(String uid, {bool? beforeSlot, bool? unclosed}) async {
    try {
      await _doc(uid).update({
        'reminderBeforeSlot': ?beforeSlot,
        'reminderUnclosed': ?unclosed,
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> markImported(String uid) async {
    try {
      await _doc(uid).update({'lastImportAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> markInboxRead(String uid) async {
    try {
      await _doc(uid).update({'lastInboxReadAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Stream<List<AppUser>> watchAll() => Fs.guard(
        _db.collection('users').snapshots().map(
              (q) => q.docs.map((d) => Fs.user(d.id, d.data())).toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName)),
            ),
      );

  @override
  Future<void> setRole(String uid, UserRole role) async {
    try {
      await _doc(uid).update({'role': role.name});
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
