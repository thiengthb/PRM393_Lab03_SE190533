// File này được THAY bằng `flutterfire configure --project=<project-id>`
// (xem README, mục Cài đặt). Bản giữ chỗ dưới đây chỉ để mã biên dịch được
// trước khi cấu hình; chạy app với bản này sẽ báo lỗi rõ ràng.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Chưa cấu hình Firebase. Chạy: dart pub global activate flutterfire_cli && '
      'flutterfire configure --project=<project-id> --platforms=android,web',
    );
  }
}
