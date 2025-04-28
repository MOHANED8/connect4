import '../widgets/game_history_box.dart';

class GameHistoryService {
  static final List<GameHistoryEntry> _history = [];

  static List<GameHistoryEntry> get history => List.unmodifiable(_history);

  static void addGameResult(
      {required String winner, required String loser, String? date}) {
    _history.add(GameHistoryEntry(winner: winner, loser: loser, date: date));
    if (_history.length > 20) {
      _history.removeAt(0); // Keep only the last 20 games
    }
  }

  static void clearHistory() {
    _history.clear();
  }
}
