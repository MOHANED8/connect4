// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connect4_flutter/main.dart';

void main() {
  group('Connect Four App Tests', () {
    testWidgets('App launches and shows game mode screen', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify we're on the game mode screen
      expect(find.text('Select Game Mode'), findsOneWidget);
    });

    testWidgets('Sound buttons work correctly', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find and verify sound buttons
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // Test sound toggle
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      // Test music toggle
      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pump();
      expect(find.byIcon(Icons.music_off), findsOneWidget);
    });
  });
}
