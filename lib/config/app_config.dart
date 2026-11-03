import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Cấu hình lúc build (`--dart-define`). Không chứa bí mật.
abstract final class AppConfig {
  /// lecturer | student. Mặc định: web là sinh viên, Android là giảng viên (D-L3-01).
  static const _portal = String.fromEnvironment('PORTAL');

  static UserRole get portal {
    if (_portal == 'student') return UserRole.student;
    if (_portal == 'lecturer') return UserRole.lecturer;
    return kIsWeb ? UserRole.student : UserRole.lecturer;
  }

  /// Web client ID (OAuth) của dự án Firebase, cần cho Google Sign-In trên Android
  /// (Credential Manager). Lấy trong Firebase console → Authentication → Google.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '267439096687-3lgkii1tgak84btrnou9nq2pebvsprem.apps.googleusercontent.com',
  );

  /// Địa chỉ web sinh viên (Firebase Hosting), dùng cho link màn chiếu TV-001.
  static const webBase = String.fromEnvironment('WEB_BASE', defaultValue: 'https://hereby-se190533.web.app');

  /// Tên miền email theo vai trò (D-16). Để trống thì không kiểm, dùng cho tài khoản test.
  static const lecturerDomain = String.fromEnvironment('LECTURER_DOMAIN');
  static const studentDomain = String.fromEnvironment('STUDENT_DOMAIN');
}
