// ignore_for_file: unused_import, deprecated_member_use, duplicate_ignore, depend_on_referenced_packages
// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'services/sound_service.dart';
import 'services/online_game_service.dart';
import 'widgets/page_template.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class OnlineGamePage extends StatefulWidget {
  final String matchId;
  final String playerName;

  const OnlineGamePage({
    super.key,
    required this.matchId,
    required this.playerName,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  static const int rows = 6;
  static const int cols = 7;
  List<List<int>> board = List.generate(rows, (_) => List.filled(cols, 0));
  int currentPlayer = 1;
  String? player1Name;
  String? player2Name;
  bool isPlayer1 = false;
  bool isGameOver = false;
  String? winnerId;
  String? roomStatus;
  final SoundService _soundService = SoundService();
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _initializeWebSocket() {
    // TODO: If you want to distinguish host/joiner, pass an isHost flag to OnlineGamePage and use createRoom for host, joinRoom for joiner.
    _channel = OnlineGameService().joinRoom(widget.playerName, widget.matchId);
    _wsSubscription = _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      setState(() {
        if (data['type'] == 'state') {
          player1Name = data['player1'];
          player2Name = data['player2'];
          isPlayer1 = data['player'] == 1;
          board = data['board'] != null
              ? List<List<int>>.from(
                  (data['board'] as List).map((row) => List<int>.from(row)))
              : List.generate(rows, (_) => List.filled(cols, 0));
          currentPlayer = data['currentPlayer'] ?? 1;
          isGameOver = data['isGameOver'] ?? false;
          winnerId = data['winner'];
          roomStatus = data['status'];
        } else if (data['type'] == 'opponent_left') {
          _showErrorAndExit('Opponent left the game.');
        } else if (data['type'] == 'error') {
          _showErrorAndExit(data['message'] ?? 'Error occurred.');
        }
      });
    });
  }

  void _showErrorAndExit(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> makeMove(int col) async {
    if (isGameOver || roomStatus != 'active') return;
    if ((isPlayer1 && currentPlayer != 1) ||
        (!isPlayer1 && currentPlayer != 2)) {
      return; // Not your turn
    }
    OnlineGameService().sendMove(_channel!, col, isPlayer1 ? 1 : 2);
    _soundService.playPieceDrop();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Online Game',
      child: _buildOnlineGameContent(context),
      onBack: () {
        // Clean up room before leaving
        if (roomStatus == 'active') {
          OnlineGameService().leaveRoom(_channel!);
        }
        Navigator.pop(context);
      },
      onSettings: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings clicked')));
      },
      onTrophy: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Trophy clicked')));
      },
    );
  }

  Widget _buildOnlineGameContent(BuildContext context) {
    if (roomStatus == null || roomStatus == 'waiting') {
      // Waiting for opponent
      return Card(
        color: Colors.white.withOpacity(0.08),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Room Code:',
                  style: TextStyle(color: Colors.amber[200], fontSize: 18)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(widget.matchId,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    tooltip: 'Copy Room Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.matchId));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room code copied!')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Waiting for opponent to join...',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  OnlineGameService().leaveRoom(_channel!);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }
    if (roomStatus == 'completed') {
      // Game over
      String resultText = 'Game Over!';
      if (winnerId != null) {
        final isWinner =
            (isPlayer1 && winnerId == '1') || (!isPlayer1 && winnerId == '2');
        resultText = isWinner ? 'You Win!' : 'You Lose!';
      }
      return Card(
        color: Colors.white.withOpacity(0.08),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(resultText,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }
    // Active game
    return Card(
      color: Colors.white.withOpacity(0.08),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (player1Name != null && player2Name != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPlayerInfo(
                    player1Name!,
                    Colors.amber,
                    currentPlayer == 1,
                    18,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPlayerInfo(
                    player2Name!,
                    Colors.red,
                    currentPlayer == 2,
                    18,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Game board
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  for (int row = 0; row < rows; row++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int col = 0; col < cols; col++)
                          GestureDetector(
                            onTap: () => makeMove(col),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getCellColor(board[row][col]),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (isGameOver) ...[
              const SizedBox(height: 24),
              const Text(
                'Game Over!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (player1Name == null || player2Name == null)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(
    String name,
    Color color,
    bool isCurrentTurn,
    double fontSize,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.75,
        vertical: fontSize * 0.5,
      ),
      decoration: BoxDecoration(
        color: isCurrentTurn ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getCellColor(int value) {
    switch (value) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.red;
      default:
        return Colors.white.withOpacity(0.1);
    }
  }
}
