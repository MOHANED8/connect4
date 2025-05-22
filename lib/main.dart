// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'game_mode_page.dart';
import 'services/sound_service.dart';
import 'services/online_game_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'intro_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/game_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_name_page.dart';
import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Uncomment if you have this file
// TODO: If you see an error for DefaultFirebaseOptions, run `flutterfire configure` to regenerate firebase_options.dart

final String kWebSocketHost =
    Platform.isAndroid ? '10.0.2.2:8080' : 'localhost:8080';
// For physical device, replace with your LAN IP, e.g.:
// final String kWebSocketHost = Platform.isAndroid ? '192.168.1.x:8080' : 'localhost:8080';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // SharedPreferences'ı başlat
  try {
    final prefs = await SharedPreferences.getInstance();
    print('SharedPreferences instance obtained in main()');

    // Önceki kayıtların düzgün başlatıldığını kontrol et
    final previousHistory = prefs.getStringList('game_history') ?? [];
    print('Previous game history count: ${previousHistory.length}');

    // GameHistoryService'i başlat
    await GameHistoryService.init();
    print('GameHistoryService initialized');
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect Four',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const IntroScreen(),
    );
  }
}

void testFirebaseWrite() async {
  try {
    await FirebaseDatabase.instance.ref('test').set({'test': 'ok'});
    print('Firebase write test: OK');
  } catch (e) {
    print('Firebase write test failed: $e');
  }
}

void createRoomTest() async {
  final ref = FirebaseDatabase.instance.ref('rooms/TEST123');
  await ref.set({
    'host': 'Ali',
    'players': {
      'Ali': {'isHost': true, 'joinedAt': ServerValue.timestamp}
    },
    'createdAt': ServerValue.timestamp,
  });
  print('Room created!');
}
