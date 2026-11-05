import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM token của từng máy, lưu ở `users/{uid}/fcmTokens/{token}`.
///
/// Token do Firebase Messaging cấp cho một lần cài app trên một máy (không phải cho người dùng).
/// App ghi token vào Firestore để phía gửi (script Admin SDK ở `tool/fcm/`) biết gửi tới máy nào
/// của người nào. Token đổi khi cài lại app hoặc xoá dữ liệu: app ghi lại khi nhận onTokenRefresh.
abstract class FcmTokenRepository {
  Future<void> save(String uid, String token, {required String platform});
  Future<void> remove(String uid, String token);
}

class FirestoreFcmTokenRepository implements FcmTokenRepository {
  FirestoreFcmTokenRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String token) =>
      _db.collection('users').doc(uid).collection('fcmTokens').doc(token);

  @override
  Future<void> save(String uid, String token, {required String platform}) =>
      _doc(uid, token).set({'token': token, 'platform': platform, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> remove(String uid, String token) => _doc(uid, token).delete();
}
