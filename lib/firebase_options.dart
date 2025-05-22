import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwaUqQ0nqppdw5YeM-WjYrvNQz7qoHyq8',
    appId: '1:347753597066:web:c3cb329d3e4a2ce6408573',
    messagingSenderId: '347753597066',
    projectId: 'connect4-67b1c',
    authDomain: 'connect4-67b1c.firebaseapp.com',
    databaseURL: 'https://connect4-67b1c-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'connect4-67b1c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwaUqQ0nqppdw5YeM-WjYrvNQz7qoHyq8',
    appId: '1:347753597066:web:c3cb329d3e4a2ce6408573',
    messagingSenderId: '347753597066',
    projectId: 'connect4-67b1c',
    databaseURL: 'https://connect4-67b1c-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'connect4-67b1c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwaUqQ0nqppdw5YeM-WjYrvNQz7qoHyq8',
    appId: '1:347753597066:web:c3cb329d3e4a2ce6408573',
    messagingSenderId: '347753597066',
    projectId: 'connect4-67b1c',
    databaseURL: 'https://connect4-67b1c-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'connect4-67b1c.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwaUqQ0nqppdw5YeM-WjYrvNQz7qoHyq8',
    appId: '1:347753597066:web:c3cb329d3e4a2ce6408573',
    messagingSenderId: '347753597066',
    projectId: 'connect4-67b1c',
    databaseURL: 'https://connect4-67b1c-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'connect4-67b1c.firebasestorage.app',
  );
} 