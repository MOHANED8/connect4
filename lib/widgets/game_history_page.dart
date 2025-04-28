// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/game_history_service.dart';

class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key});

  @override
  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  void _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Clear History?', style: TextStyle(color: Colors.amber)),
        content: const Text('Are you sure you want to clear all game history?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child:
                const Text('Clear', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => GameHistoryService.clearHistory());
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = GameHistoryService.history;
    final isEmpty = history.isEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            const Text('Game History', style: TextStyle(color: Colors.amber)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Clear History',
            onPressed: isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
            const SizedBox(height: 8),
            Text(
              'Your Game History',
              style: TextStyle(
                color: Colors.amber[200],
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See your past winners and matches',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isEmpty
                  ? const Center(
                      child: Text(
                        'No game history yet. Play some games!',
                        style: TextStyle(color: Colors.white38, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final entry = history[history.length - 1 - i];
                        return Card(
                          color: Colors.grey[900],
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.amber.withOpacity(0.15)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              entry.winner == 'Tie'
                                  ? Icons.handshake
                                  : Icons.emoji_events,
                              color: entry.winner == 'Tie'
                                  ? Colors.blue
                                  : Colors.amber,
                              size: 32,
                            ),
                            title: Text(
                              entry.winner == 'Tie'
                                  ? "It's a Tie!"
                                  : '${entry.winner} beat ${entry.loser}',
                              style: TextStyle(
                                color: entry.winner == 'Tie'
                                    ? Colors.blue[200]
                                    : Colors.amber[100],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: entry.date != null
                                ? Text(
                                    entry.date!,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13,
                                    ),
                                  )
                                : null,
                            trailing: entry.winner == 'Tie'
                                ? null
                                : const Icon(
                                    Icons.person,
                                    color: Colors.redAccent,
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
