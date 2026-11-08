import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend_core/services/auth_service.dart';

String msg(String code) {
  final e = FirebaseAuthException(code: code);
  return emailSignInError(mapAuthError(e), e).message;
}

void main() {
  group('Lỗi đăng nhập email', () {
    test('mã chuẩn của web/Android', () {
      expect(msg('invalid-credential'), 'Sai email hoặc mật khẩu');
      expect(msg('wrong-password'), 'Sai email hoặc mật khẩu');
    });
    test('mã chung của bản Windows (C++ SDK) vẫn báo sai email hoặc mật khẩu', () {
      expect(msg('internal-error'), 'Sai email hoặc mật khẩu');
      expect(msg('unknown'), 'Sai email hoặc mật khẩu');
    });
    test('các mã khác giữ nguyên', () {
      expect(msg('network-request-failed'), 'Mất kết nối mạng');
      expect(msg('too-many-requests'), 'Thử lại sau ít phút');
      expect(msg('user-disabled'), 'Tài khoản đã bị khoá');
    });
  });
}
