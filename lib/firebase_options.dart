// Cấu hình Firebase project hereby-se190533, lấy từ Firebase console.
// Các khóa này không phải bí mật: quyền truy cập do Security Rules quyết định.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Quick Attend chỉ chạy trên Android và web');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBK1guDZ1ExpvVFfMZq4J56CvLwpVRo-RY',
    appId: '1:267439096687:android:2ff4f5daf2cd486c0d5e9a',
    messagingSenderId: '267439096687',
    projectId: 'hereby-se190533',
    storageBucket: 'hereby-se190533.firebasestorage.app',
  );

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
