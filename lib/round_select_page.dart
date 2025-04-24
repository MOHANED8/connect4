// round_select_page.dart
import 'package:flutter/material.dart';
import 'game_page.dart';

class RoundSelectPage extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final bool isBotEnabled;
  final String difficulty;

  const RoundSelectPage({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.isBotEnabled,
    required this.difficulty,
  });

  @override
  State<RoundSelectPage> createState() => _RoundSelectPageState();
}

class _RoundSelectPageState extends State<RoundSelectPage> {
  int maxRounds = 3;

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          player1Name: widget.player1Name,
          player2Name: widget.player2Name,
          isBotEnabled: widget.isBotEnabled,
          difficulty: widget.difficulty,
          maxRounds: maxRounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Rounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Rounds:', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: DropdownButton<int>(
                      value: maxRounds,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      dropdownColor: Colors.grey[900],
                      items: [1, 3, 5]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text('$e',
                                  style: const TextStyle(fontSize: 18))))
                          .toList(),
                      onChanged: (value) => setState(() => maxRounds = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startGame,
                  child:
                      const Text('Start Game', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
