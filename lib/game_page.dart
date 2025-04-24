import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

class _GamePageState extends State<GamePage> {
  static const int rows = 6;
  static const int cols = 7;
  List<List<int>> board = List.generate(rows, (_) => List.filled(cols, 0));
  int currentPlayer = 1;
  int player1Wins = 0;
  int player2Wins = 0;
  int round = 1;
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool isBgmPlaying = true;

  Timer? _turnTimer;
  int timeLeft = 5;

  @override
  void initState() {
    super.initState();
    startTurnTimer();
    playBackgroundMusic();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    stopTurnTimer();
    super.dispose();
  }

  void playBackgroundMusic() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('sounds/music-game-back-sound.mp3'));
  }

  void toggleMusic() {
    setState(() {
      isBgmPlaying = !isBgmPlaying;
    });
    if (isBgmPlaying) {
      _bgmPlayer.resume();
    } else {
      _bgmPlayer.pause();
    }
  }

  void startTurnTimer() {
    _turnTimer?.cancel();
    timeLeft = 5;

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
        });
      }
    });
  }

  void stopTurnTimer() {
    _turnTimer?.cancel();
  }

  void playDropSound() {
    _audioPlayer.play(AssetSource('sounds/drop.mp3'));
  }

  void playWinSound() {
    _audioPlayer.play(AssetSource('sounds/win.mp3'));
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
          playDropSound();

          if (_checkWin(board, currentPlayer)) {
            playWinSound();
            stopTurnTimer();
            if (currentPlayer == 1) {
              player1Wins++;
            } else {
              player2Wins++;
            }
            if (round >= widget.maxRounds) {
              _showFinalDialog();
            } else {
              round++;
              _showWinDialog(currentPlayer == 1
                  ? widget.player1Name
                  : widget.isBotEnabled
                      ? 'Bot'
                      : widget.player2Name);
            }
            return;
          }

          currentPlayer = currentPlayer == 1 ? 2 : 1;
        });

        if (widget.isBotEnabled && currentPlayer == 2) {
          Future.delayed(const Duration(milliseconds: 500), botMove);
        } else {
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$winnerName wins this round!'),
        content: Text(
            'Score:\n${widget.player1Name}: $player1Wins\n${widget.isBotEnabled ? "Bot" : widget.player2Name}: $player2Wins'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetBoardAndTimer();
            },
            child: const Text("Next Round"),
          )
        ],
      ),
    );
  }

  void _showFinalDialog() {
    String result;
    if (player1Wins > player2Wins) {
      result = '${widget.player1Name} Wins 🎉';
    } else if (player2Wins > player1Wins) {
      result =
          widget.isBotEnabled ? 'Bot Wins 🤖' : '${widget.player2Name} Wins 🎉';
    } else {
      result = "It's a Tie!";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Match Over'),
        content: Text(
            '$result\nFinal Score:\n${widget.player1Name}: $player1Wins\n${widget.isBotEnabled ? "Bot" : widget.player2Name}: $player2Wins'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                player1Wins = 0;
                player2Wins = 0;
                round = 1;
                resetBoardAndTimer();
              });
            },
            child: const Text("Play Again"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Four"),
        actions: [
          IconButton(
            icon: Icon(isBgmPlaying ? Icons.music_note : Icons.music_off),
            onPressed: toggleMusic,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PlayerInfo(name: widget.player1Name, color: Colors.amber),
              const Text('VS', style: TextStyle(fontSize: 22)),
              PlayerInfo(
                name: widget.isBotEnabled ? 'Bot' : widget.player2Name,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Round $round of ${widget.maxRounds}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int row = 0; row < rows; row++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int col = 0; col < cols; col++)
                          GestureDetector(
                            onTap: () => dropPiece(col),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade800,
                              ),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: board[row][col] == 1
                                        ? Colors.redAccent
                                        : board[row][col] == 2
                                            ? Colors.amber
                                            : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: board[row][col] != 0
                                        ? Border.all(
                                            color: Colors.white, width: 2)
                                        : null,
                                  ),
                                  child: board[row][col] != 0
                                      ? Icon(
                                          Icons.star,
                                          color: board[row][col] == 1
                                              ? Colors.red[900]
                                              : Colors.yellow[800],
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for ${currentPlayer == 1 ? widget.player1Name : widget.isBotEnabled ? 'Bot' : widget.player2Name}',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          Text(
            'Time left: $timeLeft s',
            style: const TextStyle(fontSize: 18, color: Colors.orangeAccent),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class PlayerInfo extends StatelessWidget {
  final String name;
  final Color color;

  const PlayerInfo({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.emoji_emotions, color: color, size: 28),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
