import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are configured only for Android in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCE2vO392oVDPKlMJGwePeAUKQ1w7M3gok',
    appId: '1:118609436441:android:a7fc1bd9dfb49f4556af88',
    messagingSenderId: '118609436441',
    projectId: 'jihc-flew',
    storageBucket: 'jihc-flew.firebasestorage.app',
  );
}
