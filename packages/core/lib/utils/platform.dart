import 'package:flutter/foundation.dart';

/// Bản desktop (Windows) của app giảng viên, build từ cùng mã `mobile/`.
///
/// FlutterFire trên Windows có Core, Auth, Firestore, Remote Config, App Check. Crashlytics, FCM,
/// Analytics và Google Sign-In không có bản Windows, nên app tắt các phần đó khi
/// [isDesktop] đúng: đăng nhập bằng email, Gợi ý AI tắt.
bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);
