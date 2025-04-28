import 'package:flutter/material.dart';
import 'dart:math';

class GameStyles {
  static BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.indigo.shade900,
        Colors.black,
      ],
    ),
  );

  static BoxDecoration containerDecoration = BoxDecoration(
    color: Colors.black38,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white12),
  );

  static Map<String, double> calculateSizes(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final baseSize = min(width / 1.2, height / 1.5);

    return {
      'padding': baseSize * 0.04,
      'fontSize': baseSize * 0.04,
      'iconSize': baseSize * 0.05,
      'maxWidth': width > 800 ? 800.0 : width * 0.95,
    };
  }

  static ButtonStyle primaryButtonStyle(double padding) =>
      ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: padding * 0.75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      );

  static InputDecoration textFieldDecoration(String label, double padding) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.75,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.white10,
      );
}
