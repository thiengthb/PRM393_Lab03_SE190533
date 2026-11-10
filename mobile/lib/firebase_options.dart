// Firebase project attendo-app-2611 (decision 001), values from the Firebase console.
// Các khóa này không phải bí mật: quyền truy cập do Security Rules quyết định.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    // Bản desktop (Windows) dùng cấu hình web app: FlutterFire desktop đi qua cùng API REST.
    if (defaultTargetPlatform == TargetPlatform.windows) return web;
    throw UnsupportedError('Attendo chạy trên Android, Windows và web');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrL8GVbLiNbfDvPk68ehqb4cDsLZqwb8M',
    appId: '1:469635173870:android:8701c16e8cfa96901312ff',
    messagingSenderId: '469635173870',
    projectId: 'attendo-app-2611',
    storageBucket: 'attendo-app-2611.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    // Web app "Attendo Web": student web, projector page and the Windows app.
    apiKey: 'AIzaSyA90nfh0NybXZItt8WnhoDwuI7uzdjM3tg',
    appId: '1:469635173870:web:a0c854bcdb5c6e8e1312ff',
    messagingSenderId: '469635173870',
    projectId: 'attendo-app-2611',
    authDomain: 'attendo-app-2611.firebaseapp.com',
    storageBucket: 'attendo-app-2611.firebasestorage.app',
    measurementId: 'G-J90PC7B9QJ',
  );
}
