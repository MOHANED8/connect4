// ignore_for_file: unused_element, unused_field, library_private_types_in_public_api

import 'package:connect4_flutter/pages/game_history_page.dart';
import 'package:connect4_flutter/services/game_history_service.dart';
import 'package:flutter/material.dart';

class OnlineGamePage extends StatefulWidget {
  final String playerName;
  const OnlineGamePage({super.key, required this.playerName});

  @override
  _OnlineGamePageState createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  late String _playerName;
  late String _opponentName;
  late int _playerScore;
  late int _opponentScore;

  @override
  void initState() {
    super.initState();
    _playerName = widget.playerName;
    _opponentName = 'Opponent'; // Assuming a default opponent name
    _playerScore = 0;
    _opponentScore = 0;
  }

  void _handleGameEnd(String winner) {
    final isWinner = winner == widget.playerName;
    final opponentName = isWinner ? _opponentName : widget.playerName;
    final score = isWinner ? _playerScore : _opponentScore;

    // Save game history
    GameHistoryService().addGame(GameHistory(
      opponentName: opponentName,
      isWinner: isWinner,
      score: score,
      date: DateTime.now(),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isWinner ? 'You Won!' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $_playerScore - $_opponentScore'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to menu
              },
              child: const Text('Back to Menu'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryPage(),
                  ),
                );
              },
              child: const Text('View Game History'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Implementation of build method
    return Container(); // Placeholder return, actual implementation needed
  }
}
