// ignore_for_file: empty_catches

import 'dart:io';
import 'dart:convert';

final rooms = <String, Map<String, dynamic>>{};

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

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  // Load SSL certificate and key (skip for Railway, use plain HTTP)
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  await for (HttpRequest req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then((ws) {
        handleConnection(ws, req.uri);
      });
    } else {
      req.response
        ..statusCode = HttpStatus.forbidden
        ..close();
    }
  }
}

void handleConnection(WebSocket ws, Uri uri) {
  try {
    final params = uri.queryParameters;
    final roomCode = params['matchId'];
    final playerName = params['playerName'];

    if (roomCode == null || playerName == null) {
      ws.add(jsonEncode(
          {'type': 'error', 'message': 'Missing room code or player name.'}));
      ws.close();
      return;
    }

    rooms.putIfAbsent(
        roomCode,
        () => {
              'players': <WebSocket>[],
              'names': <String>[],
            });

    final room = rooms[roomCode]!;
    if ((room['players'] as List).length >= 2) {
      ws.add(jsonEncode({'type': 'error', 'message': 'Room is full.'}));
      ws.close();
      return;
    }

    (room['players'] as List).add(ws);
    (room['names'] as List).add(playerName);

    if ((room['players'] as List).length == 2) {
      room['board'] = createEmptyBoard();
      room['currentPlayer'] = 1;
      room['isGameOver'] = false;
      room['winner'] = null;
      for (int idx = 0; idx < 2; idx++) {
        (room['players'] as List)[idx].add(jsonEncode({
          'type': 'state',
          'status': 'active',
          'player': idx + 1,
          'player1': (room['names'] as List)[0],
          'player2': (room['names'] as List)[1],
          'board': room['board'],
          'currentPlayer': room['currentPlayer'],
          'isGameOver': room['isGameOver'],
          'winner': room['winner'],
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

    ws.listen((message) {
      try {
        final data = jsonDecode(message);
        if (data['type'] == 'move' &&
            (room['players'] as List).length == 2 &&
            room['isGameOver'] == false) {
          final col = data['col'];
          final player = data['player'];
          if (player != room['currentPlayer']) {
            return;
          }

          // Find the lowest empty row in the column
          bool placed = false;
          for (int row = 5; row >= 0; row--) {
            if ((room['board'] as List<List<int>>)[row][col] == 0) {
              (room['board'] as List<List<int>>)[row][col] = player;
              placed = true;
              break;
            }
          }
          if (!placed) {
            return;
          }

          // Check for win/draw
          if (checkWin(room['board'], player)) {
            room['isGameOver'] = true;
            room['winner'] = player;
          } else if (isDraw(room['board'])) {
            room['isGameOver'] = true;
            room['winner'] = 0;
          } else {
            room['currentPlayer'] = room['currentPlayer'] == 1 ? 2 : 1;
          }

          // Broadcast updated state
          for (int idx = 0; idx < 2; idx++) {
            (room['players'] as List)[idx].add(jsonEncode({
              'type': 'state',
              'status': room['isGameOver'] ? 'completed' : 'active',
              'player': idx + 1,
              'player1': (room['names'] as List)[0],
              'player2': (room['names'] as List)[1],
              'board': room['board'],
              'currentPlayer': room['currentPlayer'],
              'isGameOver': room['isGameOver'],
              'winner': room['isGameOver'] ? room['winner'] : null,
            }));
          }
        }
      } catch (e) {}
    }, onDone: () {
      if ((room['players'] as List).length == 2) {
        for (var client in (room['players'] as List)) {
          if (client != ws) {
            client.add(jsonEncode({'type': 'opponent_left'}));
          }
        }
      }
      (room['players'] as List).remove(ws);
      (room['names'] as List).remove(playerName);
      if ((room['players'] as List).isEmpty) {
        rooms.remove(roomCode);
      }
    }, onError: (error) {});
  } catch (e) {
    ws.close();
  }
}
