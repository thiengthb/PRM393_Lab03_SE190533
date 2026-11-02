import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../utils/app_exception.dart';

class SignedIn {
  const SignedIn({required this.uid, required this.email, required this.displayName, required this.isNew});
  final String uid;
  final String email;
  final String displayName;
  final bool isNew;
}

/// Đăng nhập, đăng ký, xác nhận email, quên mật khẩu, đăng xuất.
abstract class AuthService {
  Stream<String?> uidChanges();
  String? get currentUid;
  String? get currentEmail;
  bool get emailVerified;

  /// true nếu tài khoản đăng nhập bằng Google (bỏ qua bước xác nhận email).
  bool get isGoogleUser;

  Future<SignedIn> signInWithEmail(String email, String password);
  Future<SignedIn> signInWithGoogle();
  Future<SignedIn> signUp({required String email, required String password, required String displayName});
  Future<void> sendEmailVerification();
  Future<bool> reloadVerified();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;
  bool _googleReady = false;

  @override
  Stream<String?> uidChanges() => _auth.authStateChanges().map((u) => u?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  bool get emailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  bool get isGoogleUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID) ?? false;

  @override
  Future<SignedIn> signInWithEmail(String email, String password) async {
    try {
      final c = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _toSignedIn(c);
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<SignedIn> signInWithGoogle() async {
    try {
      final UserCredential c;
      if (kIsWeb) {
        c = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final g = GoogleSignIn.instance;
        if (!_googleReady) {
          await g.initialize(
            serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
          );
          _googleReady = true;
        }
        // Mở hộp chọn tài khoản Google của hệ thống (tương tác native cho test ARTEMIS).
        final account = await g.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) throw const AppException(AppErrorKind.auth, 'Google không trả mã đăng nhập');
        c = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      }
      return _toSignedIn(c);
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<SignedIn> signUp({required String email, required String password, required String displayName}) async {
    try {
      final c = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await c.user?.updateDisplayName(displayName.trim());
      await c.user?.sendEmailVerification();
      return SignedIn(uid: c.user!.uid, email: email.trim(), displayName: displayName.trim(), isNew: true);
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<bool> reloadVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Không chặn đăng xuất Firebase nếu Google đã tự hết phiên.
      }
    }
    await _auth.signOut();
  }

  SignedIn _toSignedIn(UserCredential c) {
    final u = c.user!;
    return SignedIn(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName ?? '',
      isNew: c.additionalUserInfo?.isNewUser ?? false,
    );
  }

  AppException _map(Object e) {
    if (e is AppException) return e;
    if (e is GoogleSignInException) {
      if (e.code == GoogleSignInExceptionCode.canceled) return AppException.cancelled;
      return AppException(AppErrorKind.auth, 'Không đăng nhập được với Google', cause: e);
    }
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' =>
          AppException(AppErrorKind.auth, 'Sai email hoặc mật khẩu', cause: e),
        'email-already-in-use' => AppException(AppErrorKind.invalid, 'Email đã có tài khoản', cause: e),
        'weak-password' => AppException(AppErrorKind.invalid, 'Mật khẩu cần ít nhất 6 ký tự', cause: e),
        'network-request-failed' => AppException(AppErrorKind.network, 'Mất kết nối mạng', cause: e),
        'too-many-requests' => AppException(AppErrorKind.quota, 'Thử lại sau ít phút', cause: e),
        'popup-closed-by-user' || 'cancelled-popup-request' || 'web-context-canceled' => AppException.cancelled,
        _ => AppException(AppErrorKind.auth, 'Không đăng nhập được', cause: e),
      };
    }
    return AppException(AppErrorKind.unknown, 'Có lỗi, hãy thử lại', cause: e);
  }
}
