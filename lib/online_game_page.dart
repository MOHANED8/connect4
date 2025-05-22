// ignore_for_file: unused_import, deprecated_member_use, duplicate_ignore, depend_on_referenced_packages, avoid_print, unnecessary_null_comparison, unused_local_variable, unused_element
// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'services/sound_service.dart';
import 'services/online_game_service.dart';
import 'widgets/page_template.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/player_info.dart';
import 'pages/game_history_page.dart';
import 'services/game_history_service.dart';

class OnlineGamePage extends StatefulWidget {
  final String matchId;
  final String playerName;
  final bool isHost;

  const OnlineGamePage({
    super.key,
    required this.matchId,
    required this.playerName,
    this.isHost = false,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage>
    with SingleTickerProviderStateMixin {
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
  DatabaseReference? _roomRef;
  StreamSubscription? _roomSubscription;
  int round = 1;
  int maxRounds = 3;
  int player1Score = 0;
  int player2Score = 0;
  Timer? _turnTimer;
  int timeLeft = 10;
  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;
  List<Map<String, dynamic>> gameHistory = [];
  int previousRound = 1;
  bool _gameHistoryAdded = false;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.linear,
    ));

    // Her yeni oyunda geçmiş ekleme bayrağını sıfırla
    _gameHistoryAdded = false;

    // Host ise player1, değilse player2 olmalı
    if (widget.isHost) {
      isPlayer1 = true;
      player1Name = widget.playerName;
    } else {
      isPlayer1 = false;
      player2Name = widget.playerName;
    }

    _initializeRoom();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _turnTimer?.cancel();
    _timerAnimationController.dispose();
    if (_roomRef != null) {
      OnlineGameService().leaveRoom(_roomRef!.key!, widget.playerName);
    }
    super.dispose();
  }

  void startTurnTimer() {
    if (roomStatus == 'matchCompleted') return; // Prevent timer after match
    _turnTimer?.cancel();
    setState(() {
      timeLeft = 10;
    });
    _timerAnimationController.reset();
    _timerAnimationController.forward();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          if (timeLeft <= 3 && timeLeft > 0) {
            _soundService.playTimerTick();
          }
        });
      } else {
        timer.cancel();
        if (_roomRef != null &&
            roomStatus == 'active' &&
            !isGameOver &&
            roomStatus != 'matchCompleted') {
          if ((isPlayer1 && currentPlayer == 1) ||
              (!isPlayer1 && currentPlayer == 2)) {
            _roomRef!
                .child('gameState/currentPlayer')
                .set(currentPlayer == 1 ? 2 : 1);
          }
        }
      }
    });
  }

  void stopTurnTimer() {
    _turnTimer?.cancel();
  }

  Future<void> _initializeRoom() async {
    try {
      print(
          'Initializing room. isHost: ${widget.isHost}, matchId: ${widget.matchId}, playerName: ${widget.playerName}');
      if (widget.isHost) {
        _roomRef = await OnlineGameService()
            .createRoom(widget.playerName, widget.matchId);
        print('Room created: $_roomRef');
      } else {
        _roomRef = await OnlineGameService()
            .joinRoom(widget.playerName, widget.matchId);
        print('Joined room: $_roomRef');
      }

      _roomSubscription =
          OnlineGameService().watchRoom(_roomRef!.key!).listen((data) {
        print('Room data updated: $data');
        final value = data.snapshot.value;
        if (value == null) return;

        setState(() {
          final players = (value as Map)["players"] as Map<dynamic, dynamic>;
          final gameState = (value)["gameState"] as Map<dynamic, dynamic>;

          // Update player information
          player1Name = (value)["host"] as String;

          // Diğer oyuncuyu bul (host olmayan)
          if (players.length > 1) {
            player2Name = players.entries
                .firstWhere((entry) => entry.key != player1Name,
                    orElse: () => const MapEntry('', null))
                .key;
          }

          // Hangi oyuncu olduğumuzu belirle
          isPlayer1 = widget.playerName == player1Name;

          // --- PATCH START: Set game status to 'active' when both players are present ---
          if (players.length == 2 &&
              gameState != null &&
              gameState['status'] == 'waiting') {
            if (isPlayer1 && _roomRef != null) {
              _roomRef!.child('gameState/status').set('active');
            }
          }
          // --- PATCH END ---

          // Update game state
          if (gameState != null) {
            final boardData = gameState['board'] as List<dynamic>;
            board = List.generate(
                rows,
                (i) => List<int>.from(
                    boardData.sublist(i * cols, (i + 1) * cols)));
            int newCurrentPlayer = gameState['currentPlayer'] as int;
            // Only reset/start timer if the turn actually changed
            if (currentPlayer != newCurrentPlayer) {
              stopTurnTimer();
              startTurnTimer();
            }
            currentPlayer = newCurrentPlayer;
            roomStatus = gameState['status'] as String;
            int newRound = (gameState['round'] ?? 1) as int;
            maxRounds = (gameState['maxRounds'] ?? 3) as int;
            player1Score = (gameState['player1Score'] ?? 0) as int;
            player2Score = (gameState['player2Score'] ?? 0) as int;
            winnerId = gameState['winner'] as String?;

            // Oyun durumu güncellendi, log yazdır
            print(
                'Game state updated: status=$roomStatus, round=$newRound/$maxRounds, winner=$winnerId');

            // Show round start dialog if round increased (but not on first load)
            if (previousRound != newRound &&
                newRound > 1 &&
                newRound <= maxRounds) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showRoundStartDialog(newRound);
              });
            }
            previousRound = newRound;
            round = newRound;

            // Oyun tamamen bitti mi kontrol et
            isGameOver = roomStatus == 'matchCompleted';

            // After updating player1Score/player2Score and round, check for best-of-three win
            if ((player1Score == 2 || player2Score == 2) &&
                roomStatus != 'matchCompleted') {
              // Someone has won 2 rounds, match is over
              if (_roomRef != null) {
                _roomRef!.child('gameState/status').set('matchCompleted');
                if (player1Score == 2) {
                  _roomRef!.child('gameState/winner').set('1');
                } else if (player2Score == 2) {
                  _roomRef!.child('gameState/winner').set('2');
                }
              }
            }
          }
        });
      });
      startTurnTimer();
    } catch (e, st) {
      print('Failed to join/create room: $e\n$st');
      _showErrorAndExit('Failed to join room: $e');
    }
  }

  void _showErrorAndExit(String message) {
    if (mounted) {
      _soundService.playButtonClick();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _showRoundDialog(String message, {bool isDraw = false}) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final baseSize = width < height ? width : height;
    final fontSize = baseSize * 0.04;
    final padding = baseSize * 0.04;
    final isMatchOver = (player1Score == 2 || player2Score == 2) ||
        (round >= maxRounds && player1Score == player2Score);

    print(
        'Showing round dialog: round=$round, maxRounds=$maxRounds, isMatchOver=$isMatchOver');

    // Save to game history if match is over
    if (isMatchOver && !_gameHistoryAdded) {
      String opponentName =
          isPlayer1 ? (player2Name ?? '-') : (player1Name ?? '-');
      bool isWinner = false;
      bool matchDraw = false;
      if (winnerId == null || winnerId == '0') {
        matchDraw = true;
      } else if (winnerId != null) {
        if ((isPlayer1 && winnerId == '1') || (!isPlayer1 && winnerId == '2')) {
          isWinner = true;
        }
      }
      GameHistoryService().addGame(GameHistory(
        opponentName: matchDraw ? 'Draw' : opponentName,
        isWinner: isWinner,
        score: isPlayer1 ? player1Score : player2Score,
        date: DateTime.now(),
      ));
      _gameHistoryAdded = true;
      print('Game history added in round dialog against $opponentName');
    }

    if (!isDraw && winnerId != null) _soundService.playWinCelebration();
    if (isDraw) _soundService.playDraw();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: isDraw
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDraw ? Icons.handshake : Icons.emoji_events,
                color: isDraw ? Colors.blue : Colors.amber,
                size: fontSize * 2,
              ),
            ),
            SizedBox(height: padding * 0.5),
            Text(
              isMatchOver
                  ? (player1Score == player2Score
                      ? "It's a Draw!"
                      : ((isPlayer1 && player1Score > player2Score) ||
                              (!isPlayer1 && player2Score > player1Score))
                          ? 'You Win!'
                          : 'You Lose!')
                  : message,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding * 0.75),
            Container(
              padding: EdgeInsets.all(padding * 0.75),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMatchOver
                                ? (winnerId == null || winnerId == '0'
                                        ? Icons.handshake // Draw
                                        : ((winnerId == '1' &&
                                                    player1Name ==
                                                        (isPlayer1
                                                            ? widget.playerName
                                                            : player1Name)) ||
                                                (winnerId == '2' &&
                                                    player1Name ==
                                                        (isPlayer1
                                                            ? player2Name
                                                            : player1Name)))
                                            ? Icons.emoji_emotions // Winner
                                            : Icons
                                                .sentiment_dissatisfied // Loser
                                    )
                                : Icons.emoji_emotions,
                            color: isMatchOver
                                ? (winnerId == null || winnerId == '0'
                                    ? Colors.blue
                                    : ((winnerId == '1' &&
                                                player1Name ==
                                                    (isPlayer1
                                                        ? widget.playerName
                                                        : player1Name)) ||
                                            (winnerId == '2' &&
                                                player1Name ==
                                                    (isPlayer1
                                                        ? player2Name
                                                        : player1Name)))
                                        ? Colors.amber
                                        : Colors.redAccent)
                                : Colors.amber,
                            size: fontSize * 1.2,
                          ),
                          SizedBox(width: padding * 0.5),
                          Text(player1Name ?? '-',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: padding * 0.5),
                        padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.25),
                        decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(player1Score.toString(),
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMatchOver
                                ? (winnerId == null || winnerId == '0'
                                        ? Icons.handshake // Draw
                                        : ((winnerId == '2' &&
                                                    player2Name ==
                                                        (isPlayer1
                                                            ? player2Name
                                                            : widget
                                                                .playerName)) ||
                                                (winnerId == '1' &&
                                                    player2Name ==
                                                        (isPlayer1
                                                            ? player1Name
                                                            : widget
                                                                .playerName)))
                                            ? Icons.emoji_emotions // Winner
                                            : Icons
                                                .sentiment_dissatisfied // Loser
                                    )
                                : Icons.emoji_emotions,
                            color: isMatchOver
                                ? (winnerId == null || winnerId == '0'
                                    ? Colors.blue
                                    : ((winnerId == '2' &&
                                                player2Name ==
                                                    (isPlayer1
                                                        ? player2Name
                                                        : widget.playerName)) ||
                                            (winnerId == '1' &&
                                                player2Name ==
                                                    (isPlayer1
                                                        ? player1Name
                                                        : widget.playerName)))
                                        ? Colors.amber
                                        : Colors.redAccent)
                                : Colors.redAccent,
                            size: fontSize * 1.2,
                          ),
                          SizedBox(width: padding * 0.5),
                          Text(player2Name ?? '-',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(left: padding * 0.5),
                        padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.75,
                            vertical: padding * 0.25),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(player2Score.toString(),
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 0.75),
            if (!isMatchOver)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _soundService.playButtonClick();
                    Navigator.pop(context);
                    if (!isMatchOver && isPlayer1 && _roomRef != null) {
                      _roomRef!.update({
                        'gameState/board': List.generate(42, (_) => 0),
                        'gameState/currentPlayer': 1, // or alternate who starts
                        'gameState/status': 'active',
                        'gameState/round': round + 1,
                        'gameState/winner': null,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Next Round',
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.bold)),
                ),
              ),
            if (isMatchOver)
              ElevatedButton(
                onPressed: () {
                  _soundService.playButtonClick();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to menu
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Back to Menu',
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
              ),
            if (isMatchOver)
              ElevatedButton(
                onPressed: () {
                  _soundService.playButtonClick();
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameHistoryPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('View Game History',
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  void _showRoundStartDialog(int roundNum) {
    _soundService.playButtonClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              'Round $roundNum Start!',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text('Good luck!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> makeMove(int col) async {
    if (isGameOver ||
        roomStatus == 'matchCompleted' ||
        (roomStatus != 'active' && roomStatus != 'completed')) {
      return;
    }
    if ((isPlayer1 && currentPlayer != 1) ||
        (!isPlayer1 && currentPlayer != 2)) {
      return; // Not your turn
    }
    if (_roomRef != null) {
      await OnlineGameService()
          .makeMove(_roomRef!.key!, col, isPlayer1 ? 1 : 2);
      _soundService.playPieceDrop();
      setState(() {
        gameHistory.add({
          'player': isPlayer1 ? player1Name : player2Name,
          'column': col,
          'timestamp': DateTime.now().toString(),
        });
      });
      if (roomStatus == 'active' || roomStatus == 'completed') {
        await Future.delayed(const Duration(milliseconds: 300));
        if (roomStatus == 'completed' && winnerId != null) {
          int winner = int.tryParse(winnerId!) ?? 0;
          if (winner == 1 || winner == 2) {
            _showRoundDialog(
                '${winner == 1 ? player1Name : player2Name} wins this round!');
            print('Current round: $round, Max rounds: $maxRounds');
            print('Score - Player1: $player1Score, Player2: $player2Score');
          }
        } else if (roomStatus == 'completed' && winnerId == null) {
          _showRoundDialog("It's a Draw!", isDraw: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kaynakları temizle
        if (_roomRef != null) {
          await OnlineGameService()
              .leaveRoom(_roomRef!.key!, widget.playerName);
          _roomRef = null;
        }
        _roomSubscription?.cancel();
        _turnTimer?.cancel();
        print('Resources cleaned up in WillPopScope');
        return true; // Sayfadan çıkışa izin ver
      },
      child: PageTemplate(
        title: 'Online Game',
        child: _buildOnlineGameContent(context),
        onBack: () {
          if (_roomRef != null) {
            OnlineGameService().leaveRoom(_roomRef!.key!, widget.playerName);
            _roomRef = null;
          }
          _roomSubscription?.cancel();
          _turnTimer?.cancel();
          Navigator.pop(context);
        },
        onSettings: () {
          _soundService.playButtonClick();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Settings clicked')));
        },
        onTrophy: () {
          _soundService.playButtonClick();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Trophy clicked')));
        },
      ),
    );
  }

  Widget _buildOnlineGameContent(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final baseSize = width < height ? width : height;
    final fontSize = baseSize * 0.04;
    final padding = baseSize * 0.04;
    final boardSize = baseSize * 0.7;

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
                      _soundService.playButtonClick();
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
                  _soundService.playButtonClick();
                  OnlineGameService()
                      .leaveRoom(_roomRef!.key!, widget.playerName);
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

    // Maç tamamen bitti mi kontrolü
    if (roomStatus == 'matchCompleted') {
      // Game over
      String resultText = 'Game Over!';
      bool isDraw = false;
      bool isWinner = false;
      if (winnerId == null || winnerId == '0') {
        resultText = "It's a Draw!";
        isDraw = true;
      } else {
        isWinner =
            (isPlayer1 && winnerId == '1') || (!isPlayer1 && winnerId == '2');
        resultText = isWinner ? 'You Win!' : 'You Lose!';
      }

      // Game history'e ekle - sadece bir kez
      if (!_gameHistoryAdded) {
        final opponentName = isDraw
            ? (isPlayer1 ? (player2Name ?? '-') : (player1Name ?? '-'))
            : (isPlayer1 ? (player2Name ?? '-') : (player1Name ?? '-'));
        final score = isPlayer1 ? player1Score : player2Score;
        GameHistoryService().addGame(GameHistory(
          opponentName: isDraw ? 'Draw' : opponentName,
          isWinner: isWinner,
          score: score,
          date: DateTime.now(),
        ));
        _gameHistoryAdded = true;
        print('Game history added for match against $opponentName');
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
                  _soundService.playButtonClick();
                  // Odadan çıkış yap ve kaynakları temizle
                  if (_roomRef != null) {
                    OnlineGameService()
                        .leaveRoom(_roomRef!.key!, widget.playerName);
                    _roomRef = null;
                  }
                  _roomSubscription?.cancel();
                  _turnTimer?.cancel();

                  // Ana ekrana dön
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

    // Active game UI (match local game page)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: padding),
        // Player info and round
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: padding * 0.5),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PlayerInfo(
                      name: player1Name ?? '-',
                      color: Colors.amber,
                      score: player1Score,
                      fontSize: fontSize,
                      isActive: currentPlayer == 1,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.75,
                        vertical: padding * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: fontSize * 1.2,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PlayerInfo(
                      name: player2Name ?? '-',
                      color: Colors.redAccent,
                      score: player2Score,
                      fontSize: fontSize,
                      isActive: currentPlayer == 2,
                    ),
                  ],
                ),
                SizedBox(height: padding),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Round $round of $maxRounds',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: padding),
        // Game board
        Container(
          height: 400,
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: AspectRatio(
            aspectRatio: cols / rows,
            child: Container(
              margin: EdgeInsets.all(padding),
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: currentPlayer == 1 ? Colors.amber : Colors.redAccent,
                  width: 4,
                ),
              ),
              child: Column(
                children: [
                  for (int row = 0; row < rows; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (int col = 0; col < cols; col++)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => makeMove(col),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade800,
                                    border: Border.all(
                                      color: Colors.white12,
                                      width: 1,
                                    ),
                                    boxShadow: board[row][col] != 0
                                        ? [
                                            // White glow for current player's coins
                                            if (board[row][col] ==
                                                currentPlayer)
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.85),
                                                blurRadius: 18,
                                                spreadRadius: 3,
                                              ),
                                            // Subtle color glow for all coins
                                            BoxShadow(
                                              color: (board[row][col] == 1
                                                      ? Colors.amber
                                                      : Colors.redAccent)
                                                  .withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: board[row][col] == 1
                                              ? Colors.amber
                                              : board[row][col] == 2
                                                  ? Colors.redAccent
                                                  : Colors.transparent,
                                          shape: BoxShape.circle,
                                          boxShadow: board[row][col] != 0
                                              ? [
                                                  BoxShadow(
                                                    color: (board[row][col] == 1
                                                            ? Colors.amber
                                                            : Colors.redAccent)
                                                        .withOpacity(0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: board[row][col] != 0
                                            ? FractionallySizedBox(
                                                widthFactor: 0.6,
                                                heightFactor: 0.6,
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: Icon(
                                                    Icons.star,
                                                    color: board[row][col] == 1
                                                        ? Colors.amber[800]
                                                        : Colors.red[900],
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: padding),
        // Turn info and timer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: padding * 0.5),
            padding: EdgeInsets.all(padding),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentPlayer == 1
                          ? Icons.emoji_emotions
                          : Icons.emoji_emotions,
                      color:
                          currentPlayer == 1 ? Colors.amber : Colors.redAccent,
                      size: fontSize * 1.2,
                    ),
                    SizedBox(width: padding * 0.5),
                    Text(
                      'Waiting for ${currentPlayer == 1 ? player1Name : player2Name}',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: padding * 0.5),
                // Timer pill (animated, color changes when <=3s)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _timerAnimation,
                      builder: (context, child) {
                        return Container(
                          width: baseSize * 0.3,
                          height: baseSize * 0.08,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: timeLeft <= 2
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _timerAnimation.value,
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                timeLeft <= 2
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: timeLeft <= 2 ? Colors.red : Colors.orange,
                          size: fontSize * 1.2,
                        ),
                        SizedBox(width: padding * 0.5),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: fontSize * (timeLeft <= 2 ? 1.2 : 1.0),
                            color: timeLeft <= 2 ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                          child: Text('$timeLeft s'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Game History
        _buildGameHistory(padding, fontSize),
      ],
    );
  }

  Widget _buildGameHistory(double padding, double fontSize) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game History',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding * 0.5),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gameHistory.length,
            itemBuilder: (context, index) {
              final move = gameHistory[index];
              return ListTile(
                leading: Icon(
                  Icons.circle,
                  color: move['player'] == player1Name
                      ? Colors.amber
                      : Colors.redAccent,
                ),
                title: Text(
                  '${move['player']} placed in column ${move['column']}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  move['timestamp'],
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ],
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

  void _handleGameEnd(String winner) {
    final isWinner = winner == widget.playerName;
    final opponentName =
        isPlayer1 ? (player2Name ?? '-') : (player1Name ?? '-');
    final score = isPlayer1 ? player1Score : player2Score;

    // Save game history - only once
    if (!_gameHistoryAdded) {
      GameHistoryService().addGame(GameHistory(
        opponentName: opponentName,
        isWinner: isWinner,
        score: score,
        date: DateTime.now(),
      ));

      // Bir daha eklemeyi önle
      _gameHistoryAdded = true;
      print('Game history added in handleGameEnd against $opponentName');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isWinner ? 'You Won!' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $player1Score - $player2Score'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _soundService.playButtonClick();
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to menu
              },
              child: const Text('Back to Menu'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _soundService.playButtonClick();
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
}

void testFirebaseWrite() async {
  try {
    await FirebaseDatabase.instance.ref('test').set({'test': 'ok'});
    print('Firebase write test: OK');
  } catch (e) {
    print('Firebase write test failed: $e');
  }
}

void createRoomTest() async {
  final ref = FirebaseDatabase.instance.ref('rooms/TEST123');
  await ref.set({
    'host': 'Ali',
    'players': {
      'Ali': {'isHost': true, 'joinedAt': ServerValue.timestamp}
    },
    'createdAt': ServerValue.timestamp,
  });
  print('Room created!');
}
