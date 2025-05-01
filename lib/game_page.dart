// ignore_for_file: deprecated_member_use, unused_local_variable, unused_import, depend_on_referenced_packages

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/sound_service.dart';
import 'widgets/audio_settings_button.dart';
import 'services/game_history_service.dart';
import 'widgets/game_history_box.dart';
import 'widgets/game_history_page.dart';
import 'widgets/header_icons_row.dart';

class GamePage extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final bool isBotEnabled;
  final String difficulty;
  final int maxRounds;

  const GamePage({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.isBotEnabled,
    required this.difficulty,
    required this.maxRounds,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  static const int rows = 6;
  static const int cols = 7;
  List<List<int>> board = List.generate(rows, (_) => List.filled(cols, 0));
  int currentPlayer = 1;
  int player1Wins = 0;
  int player2Wins = 0;
  int round = 1;
  final Random _random = Random();
  final SoundService _soundService = SoundService();

  Timer? _turnTimer;
  int timeLeft = 10;
  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;

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
    _soundService.playMainTheme();
    startTurnTimer();
  }

  @override
  void dispose() {
    _timerAnimationController.dispose();
    stopTurnTimer();
    super.dispose();
  }

  void startTurnTimer() {
    _turnTimer?.cancel();
    timeLeft = 10;
    _timerAnimationController.reset();
    _timerAnimationController.forward();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft == 0) {
        timer.cancel();
        if (widget.isBotEnabled && currentPlayer == 2) {
          botMove();
        } else {
          setState(() {
            currentPlayer = currentPlayer == 1 ? 2 : 1;
          });
          startTurnTimer();
        }
      } else {
        setState(() {
          timeLeft--;
          // Play tick sound for last 3 seconds
          if (timeLeft <= 3 && timeLeft > 0) {
            _soundService.playTimerTick();
          }
        });
      }
    });
  }

  void stopTurnTimer() {
    _turnTimer?.cancel();
  }

  void resetBoardAndTimer() {
    setState(() {
      board = List.generate(rows, (_) => List.filled(cols, 0));
      currentPlayer = 1;
    });
    stopTurnTimer();
    startTurnTimer();
  }

  void dropPiece(int col) {
    for (int row = rows - 1; row >= 0; row--) {
      if (board[row][col] == 0) {
        setState(() {
          board[row][col] = currentPlayer;
          _soundService.playPieceDrop();
        });

        // Check for win
        if (_checkWin(board, currentPlayer)) {
          setState(() {
            _soundService.playWinCelebration();
            stopTurnTimer();
            if (currentPlayer == 1) {
              player1Wins++;
            } else {
              player2Wins++;
            }
          });
          if (round >= widget.maxRounds) {
            _showFinalDialog();
          } else {
            setState(() {
              round++;
            });
            _showWinDialog(currentPlayer == 1
                ? widget.player1Name
                : widget.isBotEnabled
                    ? 'Bot'
                    : widget.player2Name);
          }
          return;
        }

        // Check for draw
        if (board[0].every((cell) => cell != 0)) {
          setState(() {
            _soundService.playDraw();
            stopTurnTimer();
          });
          if (round >= widget.maxRounds) {
            _showFinalDialog();
          } else {
            setState(() {
              round++;
            });
            _showDrawDialog();
          }
          return;
        }

        // Switch player
        setState(() {
          currentPlayer = currentPlayer == 1 ? 2 : 1;
        });

        // Only let the bot move if the game is not over
        if (widget.isBotEnabled &&
            currentPlayer == 2 &&
            !_checkWin(board, 1) &&
            !_checkWin(board, 2) &&
            !board[0].every((cell) => cell != 0) &&
            round <= widget.maxRounds) {
          Future.delayed(const Duration(milliseconds: 500), botMove);
        } else if (!widget.isBotEnabled || currentPlayer == 1) {
          startTurnTimer();
        }
        break;
      }
    }
  }

  void botMove() {
    int col;
    switch (widget.difficulty) {
      case 'Beginner':
        col = _getRandomMove();
        break;
      case 'Intermediate':
        col = _getSmartMove();
        break;
      case 'Professional':
        col = _getOptimalMove();
        break;
      default:
        col = _getRandomMove();
    }
    dropPiece(col);
  }

  int _getRandomMove() {
    int col;
    do {
      col = _random.nextInt(cols);
    } while (board[0][col] != 0);
    return col;
  }

  int _getSmartMove() {
    for (int col = 0; col < cols; col++) {
      if (board[0][col] != 0) continue;
      var temp = _cloneBoard();
      _dropPieceSim(temp, col, 2);
      if (_checkWin(temp, 2)) return col;
    }
    for (int col = 0; col < cols; col++) {
      if (board[0][col] != 0) continue;
      var temp = _cloneBoard();
      _dropPieceSim(temp, col, 1);
      if (_checkWin(temp, 1)) return col;
    }
    return _getRandomMove();
  }

  int _getOptimalMove() {
    int bestScore = -10000;
    int bestCol = 0;
    for (int col = 0; col < cols; col++) {
      if (board[0][col] != 0) continue;
      var temp = _cloneBoard();
      _dropPieceSim(temp, col, 2);
      int score = _minimax(temp, 4, false, -10000, 10000);
      if (score > bestScore) {
        bestScore = score;
        bestCol = col;
      }
    }
    return bestCol;
  }

  int _minimax(
      List<List<int>> tempBoard, int depth, bool isMax, int alpha, int beta) {
    if (depth == 0 || _isTerminal(tempBoard)) return _evaluateBoard(tempBoard);
    if (isMax) {
      int maxEval = -10000;
      for (int col = 0; col < cols; col++) {
        if (tempBoard[0][col] != 0) continue;
        var clone = _cloneBoardFrom(tempBoard);
        _dropPieceSim(clone, col, 2);
        int eval = _minimax(clone, depth - 1, false, alpha, beta);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 10000;
      for (int col = 0; col < cols; col++) {
        if (tempBoard[0][col] != 0) continue;
        var clone = _cloneBoardFrom(tempBoard);
        _dropPieceSim(clone, col, 1);
        int eval = _minimax(clone, depth - 1, true, alpha, beta);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  bool _isTerminal(List<List<int>> b) =>
      _checkWin(b, 1) || _checkWin(b, 2) || b[0].every((cell) => cell != 0);

  int _evaluateBoard(List<List<int>> b) {
    if (_checkWin(b, 2)) return 1000;
    if (_checkWin(b, 1)) return -1000;
    return 0;
  }

  List<List<int>> _cloneBoard() => board.map((row) => List.of(row)).toList();
  List<List<int>> _cloneBoardFrom(List<List<int>> b) =>
      b.map((row) => List.of(row)).toList();

  void _dropPieceSim(List<List<int>> temp, int col, int player) {
    for (int row = rows - 1; row >= 0; row--) {
      if (temp[row][col] == 0) {
        temp[row][col] = player;
        break;
      }
    }
  }

  bool _checkWin(List<List<int>> b, int player) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c + 3 < cols &&
            b[r][c] == player &&
            b[r][c + 1] == player &&
            b[r][c + 2] == player &&
            b[r][c + 3] == player) {
          return true;
        }
        if (r + 3 < rows &&
            b[r][c] == player &&
            b[r + 1][c] == player &&
            b[r + 2][c] == player &&
            b[r + 3][c] == player) {
          return true;
        }
        if (r + 3 < rows &&
            c + 3 < cols &&
            b[r][c] == player &&
            b[r + 1][c + 1] == player &&
            b[r + 2][c + 2] == player &&
            b[r + 3][c + 3] == player) {
          return true;
        }
        if (r - 3 >= 0 &&
            c + 3 < cols &&
            b[r][c] == player &&
            b[r - 1][c + 1] == player &&
            b[r - 2][c + 2] == player &&
            b[r - 3][c + 3] == player) {
          return true;
        }
      }
    }
    return false;
  }

  void _showWinDialog(String winnerName) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dialogWidth = width > 600 ? 400.0 : width * 0.85;
    final baseSize = min(width / 1.2, height / 1.5);
    final fontSize = baseSize * 0.04;
    final padding = baseSize * 0.04;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
                horizontal: width * 0.05, vertical: height * 0.05),
            child: Container(
              width: dialogWidth,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: fontSize * 2,
                    ),
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    '$winnerName wins this round!',
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
                        _buildScoreRow(
                          widget.player1Name,
                          player1Wins,
                          Colors.amber,
                          fontSize,
                          padding,
                        ),
                        SizedBox(height: padding * 0.5),
                        _buildScoreRow(
                          widget.isBotEnabled ? "Bot" : widget.player2Name,
                          player2Wins,
                          Colors.redAccent,
                          fontSize,
                          padding,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: padding * 0.75),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        resetBoardAndTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Next Round",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinalDialog() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dialogWidth = width > 600 ? 400.0 : width * 0.85;
    final baseSize = min(width / 1.2, height / 1.5);
    final fontSize = baseSize * 0.04;
    final padding = baseSize * 0.04;

    String result;
    Color resultColor;
    IconData resultIcon;

    if (player1Wins > player2Wins) {
      result = '${widget.player1Name} Wins';
      resultColor = Colors.amber;
      resultIcon = Icons.emoji_events;
      GameHistoryService.addGameResult(
          winner: widget.player1Name,
          loser: widget.isBotEnabled ? 'Bot' : widget.player2Name,
          date: DateTime.now().toString().substring(0, 16));
    } else if (player2Wins > player1Wins) {
      result = widget.isBotEnabled ? 'Bot Wins' : '${widget.player2Name} Wins';
      resultColor = Colors.redAccent;
      resultIcon = widget.isBotEnabled ? Icons.smart_toy : Icons.emoji_events;
      GameHistoryService.addGameResult(
          winner: widget.isBotEnabled ? 'Bot' : widget.player2Name,
          loser: widget.player1Name,
          date: DateTime.now().toString().substring(0, 16));
    } else {
      result = "It's a Tie!";
      resultColor = Colors.blue;
      resultIcon = Icons.handshake;
      GameHistoryService.addGameResult(
          winner: 'Tie',
          loser: 'Tie',
          date: DateTime.now().toString().substring(0, 16));
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
                horizontal: width * 0.05, vertical: height * 0.05),
            child: Container(
              width: dialogWidth,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: resultColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      resultIcon,
                      color: resultColor,
                      size: fontSize * 2,
                    ),
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    'Match Over',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: fontSize,
                    ),
                  ),
                  SizedBox(height: padding * 0.25),
                  Text(
                    result,
                    style: TextStyle(
                      color: resultColor,
                      fontSize: fontSize * 1.4,
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
                        _buildScoreRow(
                          widget.player1Name,
                          player1Wins,
                          Colors.amber,
                          fontSize,
                          padding,
                        ),
                        SizedBox(height: padding * 0.5),
                        _buildScoreRow(
                          widget.isBotEnabled ? "Bot" : widget.player2Name,
                          player2Wins,
                          Colors.redAccent,
                          fontSize,
                          padding,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: padding * 0.75),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          player1Wins = 0;
                          player2Wins = 0;
                          round = 1;
                          resetBoardAndTimer();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Play Again",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDrawDialog() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dialogWidth = width > 600 ? 400.0 : width * 0.85;
    final baseSize = min(width / 1.2, height / 1.5);
    final fontSize = baseSize * 0.04;
    final padding = baseSize * 0.04;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
                horizontal: width * 0.05, vertical: height * 0.05),
            child: Container(
              width: dialogWidth,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handshake,
                      color: Colors.blue,
                      size: fontSize * 2,
                    ),
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    "It's a Draw!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: padding * 0.75),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        resetBoardAndTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Next Round",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(
      String name, int score, Color color, double fontSize, double padding) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                name == "Bot" ? Icons.smart_toy : Icons.emoji_emotions,
                color: color,
                size: fontSize * 1.2,
              ),
              SizedBox(width: padding * 0.5),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: padding * 0.5),
          padding: EdgeInsets.symmetric(
            horizontal: padding * 0.75,
            vertical: padding * 0.25,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SoundService.setSnackBarContext(context);
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate sizes based on the optimal dimension for the game
                      final optimalWidth = constraints.maxWidth;
                      final optimalHeight = constraints.maxHeight;
                      final baseSize =
                          min(optimalWidth / 1.2, optimalHeight / 1.5);

                      final padding = baseSize * 0.04;
                      final fontSize = baseSize * 0.04;
                      final iconSize = baseSize * 0.05;

                      return Column(
                        children: [
                          // Header with only the settings icon
                          Container(
                            padding: EdgeInsets.all(padding),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: iconSize * 1.4,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),

                          // Player Info and Round
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: padding * 0.5),
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      PlayerInfo(
                                        name: widget.player1Name,
                                        color: Colors.amber,
                                        score: player1Wins,
                                        fontSize: fontSize,
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: padding * 0.75,
                                          vertical: padding * 0.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                        name: widget.isBotEnabled
                                            ? 'Bot'
                                            : widget.player2Name,
                                        color: Colors.redAccent,
                                        score: player2Wins,
                                        fontSize: fontSize,
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
                                      'Round $round of ${widget.maxRounds}',
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

                          // Game Board
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: cols / rows,
                              child: Container(
                                margin: EdgeInsets.all(padding),
                                padding: EdgeInsets.all(padding),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white12),
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
                                                  onTap: () => dropPiece(col),
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          Colors.grey.shade800,
                                                      border: Border.all(
                                                        color: Colors.white12,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: AspectRatio(
                                                      aspectRatio: 1,
                                                      child: Center(
                                                        child:
                                                            AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      200),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: board[row]
                                                                        [col] ==
                                                                    1
                                                                ? Colors.amber
                                                                : board[row][
                                                                            col] ==
                                                                        2
                                                                    ? Colors
                                                                        .redAccent
                                                                    : Colors
                                                                        .transparent,
                                                            shape:
                                                                BoxShape.circle,
                                                            border: board[row]
                                                                        [col] !=
                                                                    0
                                                                ? Border.all(
                                                                    color: Colors
                                                                        .white24,
                                                                    width: 2,
                                                                  )
                                                                : null,
                                                            boxShadow: board[
                                                                            row]
                                                                        [col] !=
                                                                    0
                                                                ? [
                                                                    BoxShadow(
                                                                      color: (board[row][col] == 1
                                                                              ? Colors.amber
                                                                              : Colors.redAccent)
                                                                          .withOpacity(0.5),
                                                                      blurRadius:
                                                                          8,
                                                                      spreadRadius:
                                                                          2,
                                                                    ),
                                                                  ]
                                                                : null,
                                                          ),
                                                          child: board[row]
                                                                      [col] !=
                                                                  0
                                                              ? FractionallySizedBox(
                                                                  widthFactor:
                                                                      0.6,
                                                                  heightFactor:
                                                                      0.6,
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .contain,
                                                                    child: Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: board[row][col] ==
                                                                              1
                                                                          ? Colors.amber[
                                                                              800]
                                                                          : Colors
                                                                              .red[900],
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

                          // Turn Info
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: padding * 0.5),
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        currentPlayer == 1
                                            ? Icons.emoji_emotions
                                            : widget.isBotEnabled
                                                ? Icons.smart_toy
                                                : Icons.emoji_emotions,
                                        color: currentPlayer == 1
                                            ? Colors.amber
                                            : Colors.redAccent,
                                        size: fontSize * 1.2,
                                      ),
                                      SizedBox(width: padding * 0.5),
                                      Text(
                                        'Waiting for ${currentPlayer == 1 ? widget.player1Name : widget.isBotEnabled ? 'Bot' : widget.player2Name}',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: padding * 0.75),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: _timerAnimation.value,
                                                backgroundColor: Colors.orange
                                                    .withOpacity(0.1),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  timeLeft <= 2
                                                      ? Colors.red
                                                          .withOpacity(0.3)
                                                      : Colors.orange
                                                          .withOpacity(0.3),
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
                                            color: timeLeft <= 2
                                                ? Colors.red
                                                : Colors.orange,
                                            size: fontSize * 1.2,
                                          ),
                                          SizedBox(width: padding * 0.5),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            style: TextStyle(
                                              fontSize: fontSize *
                                                  (timeLeft <= 2 ? 1.2 : 1.0),
                                              color: timeLeft <= 2
                                                  ? Colors.red
                                                  : Colors.orange,
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
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerInfo extends StatelessWidget {
  final String name;
  final Color color;
  final int score;
  final double fontSize;

  const PlayerInfo({
    super.key,
    required this.name,
    required this.color,
    required this.score,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              name == "Bot" ? Icons.smart_toy : Icons.emoji_emotions,
              color: color,
              size: fontSize * 1.5,
            ),
            SizedBox(width: fontSize * 0.5),
            Text(
              name,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: fontSize * 0.25),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.75,
            vertical: fontSize * 0.25,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
