import 'package:flutter/material.dart';
import 'game_mode_page.dart';

void main() => runApp(const ConnectFourApp());

class ConnectFourApp extends StatelessWidget {
  const ConnectFourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect Four Setup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily:
                  'Roboto', // 👈 Replace 'Roboto' with your desired font
              bodyColor: Colors.white, // 👈 Make all body text white
              displayColor: Colors.white, // 👈 Make headline text white
            ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
        ),
      ),
      home: const GameModePage(),
    );
  }
}
