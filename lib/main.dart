// ignore_for_file: unused_import, avoid_print, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'game_mode_page.dart';
import 'services/sound_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Uncomment if you have this file
// TODO: If you see an error for DefaultFirebaseOptions, run `flutterfire configure` to regenerate firebase_options.dart

void main() async {
  print('MAIN STARTED');
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect Four',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GameModePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
