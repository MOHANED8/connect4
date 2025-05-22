// ignore_for_file: deprecated_member_use, unused_local_variable, unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/game_history_service.dart';
import '../widgets/page_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key});

  @override
  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  List<GameHistory> _history = [];
  int _selectedIndex = 0;
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    // SharedPreferences'ın durumunu kontrol et
    SharedPreferences.getInstance().then((prefs) {
      final historyList = prefs.getStringList('game_history') ?? [];
    }).catchError((e) {});

    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      _history = GameHistoryService().getHistory();
    });
  }

  void _deleteAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All History'),
        content: const Text(
            'Are you sure you want to delete all game history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      GameHistoryService().clearHistory();
      setState(() {
        _history = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _deleteAllHistory,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete All',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF181C3A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final itemExtent = (availableHeight / 8).clamp(70.0, 120.0);
          final padding = (availableHeight / 32).clamp(12.0, 32.0);
          return Padding(
            padding: EdgeInsets.all(padding),
            child: _history.isEmpty
                ? Center(
                    child: Text(
                      'No game history yet.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: itemExtent * 0.25),
                    ),
                  )
                : ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: itemExtent,
                    diameterRatio: 2.2,
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    squeeze: 1.1,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index >= _history.length) return null;
                        final game = _history[index];
                        Color resultColor;
                        String resultText;
                        IconData resultIcon;
                        if (game.opponentName == 'Draw') {
                          resultColor = Colors.blueGrey;
                          resultText = 'Draw';
                          resultIcon = Icons.handshake;
                        } else if (game.isWinner) {
                          resultColor = Colors.green;
                          resultText = 'Won';
                          resultIcon = Icons.emoji_events;
                        } else {
                          resultColor = Colors.purpleAccent;
                          resultText = 'Lost';
                          resultIcon = Icons.sports_esports;
                        }
                        final isSelected = index == _selectedIndex;
                        return Transform.scale(
                          scale: isSelected ? 1.08 : 0.95,
                          child: Opacity(
                            opacity: isSelected ? 1.0 : 0.7,
                            child: Card(
                              color: const Color(0xFF23275A)
                                  .withOpacity(isSelected ? 0.95 : 0.75),
                              elevation: isSelected ? 16 : 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: isSelected
                                    ? BorderSide(
                                        color: resultColor.withOpacity(0.5),
                                        width: 2)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      resultColor.withOpacity(0.18),
                                  child: Icon(resultIcon, color: resultColor),
                                ),
                                title: Text(
                                  game.opponentName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: itemExtent * 0.22,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat.yMMMd().add_Hm().format(game.date),
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: itemExtent * 0.18),
                                ),
                                trailing: Text(
                                  resultText,
                                  style: TextStyle(
                                    color: resultColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: itemExtent * 0.22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
