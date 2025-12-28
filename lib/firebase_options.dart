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
    apiKey: 'AIzaSyDDtiZHaVC9RL4U-lJdHg1eUIyiVhjfcr8',
    appId: '1:303699574698:web:c191f1d26cd8db71b475d3',
    messagingSenderId: '303699574698',
    projectId: 'checkers-27bb3',
    authDomain: 'checkers-27bb3.firebaseapp.com',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
    measurementId: 'G-JC3PVQLBE3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDBpEivWosFdIn-Z2Z4rJXLR4Zfn6xiJBg',
    appId: '1:303699574698:android:fcb12928dffa2515b475d3',
    messagingSenderId: '303699574698',
    projectId: 'checkers-27bb3',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBpEivWosFdIn-Z2Z4rJXLR4Zfn6xiJBg',
    appId: '1:303699574698:ios:on8r1jd2ehg0al69f0da6trs1kmnkf79',
    messagingSenderId: '303699574698',
    projectId: 'checkers-27bb3',
    databaseURL: 'https://checkers-27bb3-default-rtdb.firebaseio.com',
    storageBucket: 'checkers-27bb3.firebasestorage.app',
    iosBundleId: 'com.example.masterCheckers',
  );
}
