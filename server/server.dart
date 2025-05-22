// ignore_for_file: empty_catches, unused_local_variable

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';

class GameRoom {
  final String code;
  final List<WebSocket> players;
  final List<String> names;
  List<List<int>> board;
  int currentPlayer;
  bool isGameOver;
  int? winner;
  DateTime createdAt;
  DateTime? lastActivity;
  Timer? cleanupTimer;

  GameRoom(this.code)
      : players = [],
        names = [],
        board = createEmptyBoard(),
        currentPlayer = 1,
        isGameOver = false,
        createdAt = DateTime.now(),
        lastActivity = DateTime.now();

  void updateActivity() {
    lastActivity = DateTime.now();
  }

  void startCleanupTimer() {
    cleanupTimer?.cancel();
    cleanupTimer = Timer(const Duration(minutes: 30), () {
      if (DateTime.now().difference(lastActivity!) >
          const Duration(minutes: 30)) {
        cleanup();
      }
    });
  }

  void cleanup() {
    cleanupTimer?.cancel();
    for (var player in players) {
      try {
        player.add(
            jsonEncode({'type': 'room_closed', 'message': 'Room timed out'}));
        player.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    rooms.remove(code);
  }
}

final rooms = <String, GameRoom>{};
final rateLimiter = <String, List<DateTime>>{};
const maxRequestsPerMinute = 60;

bool isRateLimited(String ip) {
  final now = DateTime.now();
  final requests = rateLimiter[ip] ?? [];
  requests
      .removeWhere((time) => now.difference(time) > const Duration(minutes: 1));

  if (requests.length >= maxRequestsPerMinute) {
    return true;
  }

  requests.add(now);
  rateLimiter[ip] = requests;
  return false;
}

String generateRoomCode() {
  final random = Random.secure();
  final bytes = List<int>.generate(4, (_) => random.nextInt(256));
  return sha256.convert(bytes).toString().substring(0, 6).toUpperCase();
}

List<List<int>> createEmptyBoard() =>
    List.generate(6, (_) => List.filled(7, 0));

bool checkWin(List<List<int>> board, int player) {
  for (int r = 0; r < 6; r++) {
    for (int c = 0; c < 7; c++) {
      if ((c <= 3 &&
              board[r][c] == player &&
              board[r][c + 1] == player &&
              board[r][c + 2] == player &&
              board[r][c + 3] == player) ||
          (r <= 2 &&
              board[r][c] == player &&
              board[r + 1][c] == player &&
              board[r + 2][c] == player &&
              board[r + 3][c] == player) ||
          (r <= 2 &&
              c <= 3 &&
              board[r][c] == player &&
              board[r + 1][c + 1] == player &&
              board[r + 2][c + 2] == player &&
              board[r + 3][c + 3] == player) ||
          (r >= 3 &&
              c <= 3 &&
              board[r][c] == player &&
              board[r - 1][c + 1] == player &&
              board[r - 2][c + 2] == player &&
              board[r - 3][c + 3] == player)) {
        return true;
      }
    }
  }
  return false;
}

bool isDraw(List<List<int>> board) =>
    board.every((row) => row.every((cell) => cell != 0));

void handleConnection(WebSocket ws, Uri uri, String ip) {
  try {
    if (isRateLimited(ip)) {
      ws.add(jsonEncode({
        'type': 'error',
        'message': 'Too many requests. Please try again later.'
      }));
      ws.close();
      return;
    }

    final params = uri.queryParameters;
    final roomCode = params['matchId'];
    final playerName = params['playerName'];
    final playerToken = params['token'];

    if (roomCode == null || playerName == null) {
      ws.add(jsonEncode(
          {'type': 'error', 'message': 'Missing room code or player name.'}));
      ws.close();
      return;
    }

    // Validate player name
    if (playerName.length < 3 || playerName.length > 20) {
      ws.add(jsonEncode({
        'type': 'error',
        'message': 'Player name must be between 3 and 20 characters.'
      }));
      ws.close();
      return;
    }

    // Validate room code format
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(roomCode)) {
      ws.add(jsonEncode(
          {'type': 'error', 'message': 'Invalid room code format.'}));
      ws.close();
      return;
    }

    rooms.putIfAbsent(roomCode, () => GameRoom(roomCode));
    final room = rooms[roomCode]!;
    room.updateActivity();

    if (room.players.length >= 2) {
      ws.add(jsonEncode({'type': 'error', 'message': 'Room is full.'}));
      ws.close();
      return;
    }

    room.players.add(ws);
    room.names.add(playerName);

    if (room.players.length == 2) {
      room.board = createEmptyBoard();
      room.currentPlayer = 1;
      room.isGameOver = false;
      room.winner = null;

      for (int idx = 0; idx < 2; idx++) {
        room.players[idx].add(jsonEncode({
          'type': 'state',
          'status': 'active',
          'player': idx + 1,
          'player1': room.names[0],
          'player2': room.names[1],
          'board': room.board,
          'currentPlayer': room.currentPlayer,
          'isGameOver': room.isGameOver,
          'winner': room.winner,
        }));
      }
    } else {
      ws.add(jsonEncode({
        'type': 'state',
        'status': 'waiting',
        'player': 1,
        'player1': playerName,
        'board': createEmptyBoard(),
        'currentPlayer': 1,
        'isGameOver': false,
        'winner': null,
      }));
    }

    ws.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'move' &&
              room.players.length == 2 &&
              !room.isGameOver) {
            final col = data['col'];
            final player = data['player'];

            // Validate move
            if (col < 0 || col >= 7 || player != room.currentPlayer) {
              return;
            }

            // Find the lowest empty row in the column
            bool placed = false;
            for (int row = 5; row >= 0; row--) {
              if (room.board[row][col] == 0) {
                room.board[row][col] = player;
                placed = true;
                break;
              }
            }

            if (!placed) return;

            // Check for win/draw
            if (checkWin(room.board, player)) {
              room.isGameOver = true;
              room.winner = player;
            } else if (isDraw(room.board)) {
              room.isGameOver = true;
              room.winner = 0;
            } else {
              room.currentPlayer = room.currentPlayer == 1 ? 2 : 1;
            }

            room.updateActivity();

            // Broadcast updated state
            for (int idx = 0; idx < 2; idx++) {
              room.players[idx].add(jsonEncode({
                'type': 'state',
                'status': room.isGameOver ? 'completed' : 'active',
                'player': idx + 1,
                'player1': room.names[0],
                'player2': room.names[1],
                'board': room.board,
                'currentPlayer': room.currentPlayer,
                'isGameOver': room.isGameOver,
                'winner': room.isGameOver ? room.winner : null,
              }));
            }
          }
        } catch (e) {}
      },
      onDone: () {
        if (room.players.length == 2) {
          for (var client in room.players) {
            if (client != ws) {
              client.add(jsonEncode({'type': 'opponent_left'}));
            }
          }
        }
        room.players.remove(ws);
        room.names.remove(playerName);
        if (room.players.isEmpty) {
          room.cleanup();
        }
      },
      onError: (error) {},
    );
  } catch (e) {
    ws.close();
  }
}

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  await for (HttpRequest req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final ip = req.connectionInfo?.remoteAddress.address ?? 'unknown';
      WebSocketTransformer.upgrade(req).then((ws) {
        handleConnection(ws, req.uri, ip);
      });
    } else {
      req.response
        ..statusCode = HttpStatus.forbidden
        ..close();
    }
  }
}
