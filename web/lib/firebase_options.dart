// Firebase project attendo-app-2611 (decision 001), web app "Attendo Admin": its own app so
// Analytics separates the admin from the student web. Not secrets: Security Rules decide access.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA90nfh0NybXZItt8WnhoDwuI7uzdjM3tg',
    appId: '1:469635173870:web:9ed5ec4416eb48151312ff',
    messagingSenderId: '469635173870',
    projectId: 'attendo-app-2611',
    authDomain: 'attendo-app-2611.firebaseapp.com',
    storageBucket: 'attendo-app-2611.firebasestorage.app',
    measurementId: 'G-MRQ8C9P6SE',
  );
}
