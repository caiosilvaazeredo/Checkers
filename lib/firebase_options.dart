import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMvHXsh2FIb9JKD4XfQCMDUd5b3w2TPsA',
    appId: '1:953618224657:web:d8f8e8c8a8b8c8d8e8f8g8',
    messagingSenderId: '953618224657',
    projectId: 'checkers-27bb3',
    authDomain: 'checkers-27bb3.firebaseapp.com',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMvHXsh2FIb9JKD4XfQCMDUd5b3w2TPsA',
    appId: '1:953618224657:android:a1b2c3d4e5f6g7h8i9j0',
    messagingSenderId: '953618224657',
    projectId: 'checkers-27bb3',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMvHXsh2FIb9JKD4XfQCMDUd5b3w2TPsA',
    appId: '1:953618224657:ios:z9y8x7w6v5u4t3s2r1q0',
    messagingSenderId: '953618224657',
    projectId: 'checkers-27bb3',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
    iosBundleId: 'com.example.masterCheckers',
  );
}
