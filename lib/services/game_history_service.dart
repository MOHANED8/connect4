// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameHistory {
  final String opponentName;
  final bool isWinner;
  final int score;
  final DateTime date;

  GameHistory({
    required this.opponentName,
    required this.isWinner,
    required this.score,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'opponentName': opponentName,
        'isWinner': isWinner,
        'score': score,
        'date': date.toIso8601String(),
      };

  factory GameHistory.fromJson(Map<String, dynamic> json) => GameHistory(
        opponentName: json['opponentName'] as String,
        isWinner: json['isWinner'] as bool,
        score: json['score'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class GameHistoryService {
  static final GameHistoryService _instance = GameHistoryService._internal();
  factory GameHistoryService() => _instance;
  GameHistoryService._internal();

  static SharedPreferences? _prefs;
  static const String _historyKey = 'game_history';
  List<GameHistory> _history = [];

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _instance._loadHistory();
    } catch (e) {
      _prefs = null;
    }
  }

  void _loadHistory() {
    try {
      if (_prefs == null) {
        return;
      }

      final historyJson = _prefs!.getStringList(_historyKey) ?? [];

      _history = historyJson
          .map((json) => GameHistory.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      _history = [];
    }
  }

  void _saveHistory() {
    try {
      if (_prefs == null) {
        return;
      }

      final historyJson =
          _history.map((game) => jsonEncode(game.toJson())).toList();

      _prefs!.setStringList(_historyKey, historyJson);
    } catch (e) {}
  }

  List<GameHistory> getHistory() => List.unmodifiable(_history);

  void addGame(GameHistory game) {
    // Çift kayıtları önlemek için son eklenen oyunla aynı olup olmadığını kontrol et
    if (_history.isNotEmpty) {
      final lastGame = _history[0];
      // Aynı rakibe karşı, aynı sonucu aldıysak ve son 5 saniye içinde kaydedildiyse ekleme
      if (lastGame.opponentName == game.opponentName &&
          lastGame.isWinner == game.isWinner &&
          lastGame.score == game.score &&
          DateTime.now().difference(lastGame.date).inSeconds < 5) {
        return;
      }
    }

    _history.insert(0, game);
    _saveHistory();
    // Kaydettikten sonra tekrar yükle (web için önemli)
    _loadHistory();
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
  }
}
