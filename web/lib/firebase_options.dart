// Cấu hình Firebase project hereby-se190533 cho web admin: dùng chung web app với cổng sinh viên
// (mobile/lib/firebase_options.dart). Các khóa này không phải bí mật: quyền do Security Rules quyết định.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZfWiWk8qdjnnl4IlXcPkUZnv1ZY7Srfw',
    appId: '1:267439096687:web:baa1626d160077770d5e9a',
    messagingSenderId: '267439096687',
    projectId: 'hereby-se190533',
    authDomain: 'hereby-se190533.firebaseapp.com',
    storageBucket: 'hereby-se190533.firebasestorage.app',
    measurementId: 'G-MVQMLTZJKZ',
  );
}
