import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for StyleMorph environments (`stylemorph-dev`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForLocalAndDevEnvWeb123',
    appId: '1:100000000000:web:stylemorphdev001',
    messagingSenderId: '100000000000',
    projectId: 'stylemorph-dev',
    authDomain: 'stylemorph-dev.firebaseapp.com',
    storageBucket: 'stylemorph-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForLocalAndDevEnvAnd123',
    appId: '1:100000000000:android:stylemorphdev001',
    messagingSenderId: '100000000000',
    projectId: 'stylemorph-dev',
    storageBucket: 'stylemorph-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForLocalAndDevEnvIos123',
    appId: '1:100000000000:ios:stylemorphdev001',
    messagingSenderId: '100000000000',
    projectId: 'stylemorph-dev',
    storageBucket: 'stylemorph-dev.appspot.com',
    iosBundleId: 'com.stylemorph.app',
  );
}
