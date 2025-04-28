// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class GameHistoryBox extends StatelessWidget {
  final List<GameHistoryEntry> history;
  const GameHistoryBox({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No game history yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game History',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...history.reversed.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      entry.winner,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(' beat '),
                    Text(
                      entry.loser,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entry.date != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${entry.date})',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ]
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class GameHistoryEntry {
  final String winner;
  final String loser;
  final String? date;
  GameHistoryEntry({required this.winner, required this.loser, this.date});
}
