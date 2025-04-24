// player_name_page.dart
import 'package:flutter/material.dart';
import 'round_select_page.dart';

class PlayerNamePage extends StatefulWidget {
  final bool isBotEnabled;
  final String difficulty;

  const PlayerNamePage({
    super.key,
    required this.isBotEnabled,
    required this.difficulty,
  });

  @override
  State<PlayerNamePage> createState() => _PlayerNamePageState();
}

class _PlayerNamePageState extends State<PlayerNamePage> {
  final TextEditingController player1Controller = TextEditingController();
  final TextEditingController player2Controller = TextEditingController();

  @override
  void dispose() {
    player1Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  void _goToNext() {
    final player1Name = player1Controller.text.trim().isEmpty
        ? 'Player 1'
        : player1Controller.text.trim();
    final player2Name = widget.isBotEnabled
        ? 'Bot'
        : player2Controller.text.trim().isEmpty
            ? 'Player 2'
            : player2Controller.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoundSelectPage(
          player1Name: player1Name,
          player2Name: player2Name,
          isBotEnabled: widget.isBotEnabled,
          difficulty: widget.difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Player Names'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: player1Controller,
                decoration:
                    const InputDecoration(labelText: 'Enter Player 1 Name'),
              ),
              const SizedBox(height: 20),
              if (!widget.isBotEnabled)
                TextField(
                  controller: player2Controller,
                  decoration:
                      const InputDecoration(labelText: 'Enter Player 2 Name'),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _goToNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
