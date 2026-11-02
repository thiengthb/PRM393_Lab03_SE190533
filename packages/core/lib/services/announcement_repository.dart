import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

/// Thông báo chung (web admin ghi) và tin riêng trong `users/{uid}/inbox` (app đọc).
abstract class AnnouncementRepository {
  /// App: thông báo đang đăng cho vai trò này, cập nhật thời gian thực.
  Stream<List<Announcement>> watchFor(UserRole role);

  /// App: tin riêng của người dùng.
  Stream<List<InboxItem>> watchPersonal(String uid);

  /// Web: mọi thông báo, cả đã lưu trữ.
  Stream<List<Announcement>> watchAll();

  Future<void> publish({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    required String actorUid,
  });
  Future<void> setArchived(String id, {required bool archived});
}

class FirestoreAnnouncementRepository implements AnnouncementRepository {
  FirestoreAnnouncementRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('announcements');

  static int _newestFirst(Announcement a, Announcement b) =>
      (b.publishedAt ?? DateTime(9999)).compareTo(a.publishedAt ?? DateTime(9999));

  @override
  Stream<List<Announcement>> watchFor(UserRole role) {
    final audiences = [
      AnnouncementAudience.all.name,
      if (role == UserRole.lecturer) AnnouncementAudience.lecturer.name,
      if (role == UserRole.student) AnnouncementAudience.student.name,
    ];
    return Fs.guard(
      _col
          .where('status', isEqualTo: 'published')
          .where('audience', whereIn: audiences)
          .snapshots()
          .map((q) => q.docs.map((d) => Fs.announcement(d.id, d.data())).toList()..sort(_newestFirst)),
    );
  }

  @override
  Stream<List<InboxItem>> watchPersonal(String uid) => Fs.guard(
        _db.collection('users').doc(uid).collection('inbox').snapshots().map(
              (q) => q.docs.map((d) => Fs.inbox(d.id, d.data())).toList(),
            ),
      );

  @override
  Stream<List<Announcement>> watchAll() =>
      Fs.guard(_col.snapshots().map((q) => q.docs.map((d) => Fs.announcement(d.id, d.data())).toList()..sort(_newestFirst)));

  @override
  Future<void> publish({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    required String actorUid,
  }) async {
    try {
      await _col.add({
        'title': title,
        'body': body,
        'audience': audience.name,
        'status': 'published',
        'createdBy': actorUid,
        'publishedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    try {
      await _col.doc(id).update({'status': archived ? 'archived' : 'published'});
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
