// ignore_for_file: empty_catches, avoid_print, unused_import, cancel_subscriptions

import 'dart:math';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineGameService {
  static final OnlineGameService _instance = OnlineGameService._internal();
  factory OnlineGameService() => _instance;
  OnlineGameService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Map<String, dynamic>> _roomCache = {};
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  // Constants
  static const int _maxRoomAge = 24; // hours
  static const int _maxRoomsPerUser = 5;
  static const int _maxPlayersPerRoom = 2;
  static const int _minPlayerNameLength = 3;
  static const int _maxPlayerNameLength = 20;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start cleanup timer
      _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
        _cleanupOldRooms();
      });

      // Load cached rooms
      final prefs = await SharedPreferences.getInstance();
      final cachedRooms = prefs.getStringList('cached_rooms') ?? [];
      for (final roomCode in cachedRooms) {
        try {
          final snapshot = await _database.child('rooms/$roomCode').get();
          if (snapshot.exists) {
            _roomCache[roomCode] =
                Map<String, dynamic>.from(snapshot.value as Map);
          }
        } catch (e) {
          debugPrint('Error loading cached room $roomCode: $e');
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing OnlineGameService: $e');
    }
  }

  Future<void> _cleanupOldRooms() async {
    try {
      final now = DateTime.now();
      final roomsSnapshot = await _database.child('rooms').get();

      if (!roomsSnapshot.exists) return;

      final rooms = Map<String, dynamic>.from(roomsSnapshot.value as Map);
      for (final entry in rooms.entries) {
        final roomCode = entry.key;
        final roomData = Map<String, dynamic>.from(entry.value as Map);
        final createdAt =
            DateTime.fromMillisecondsSinceEpoch(roomData['createdAt'] as int);

        if (now.difference(createdAt).inHours > _maxRoomAge) {
          await _database.child('rooms/$roomCode').remove();
          _roomCache.remove(roomCode);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old rooms: $e');
    }
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<DatabaseReference> createRoom(
      String playerName, String roomCode) async {
    if (!_isInitialized) await initialize();

    // Validate player name
    if (playerName.length < _minPlayerNameLength ||
        playerName.length > _maxPlayerNameLength) {
      throw Exception(
          'Player name must be between $_minPlayerNameLength and $_maxPlayerNameLength characters');
    }

    // Check if user has too many active rooms
    final userRooms = await _database
        .child('rooms')
        .orderByChild('host')
        .equalTo(playerName)
        .get();

    if (userRooms.exists &&
        (userRooms.value as Map).length >= _maxRoomsPerUser) {
      throw Exception('You have reached the maximum number of active rooms');
    }

    final roomRef = _database.child('rooms/$roomCode');
    final roomData = {
      'host': playerName,
      'players': {
        playerName: {
          'isHost': true,
          'joinedAt': ServerValue.timestamp,
        }
      },
      'gameState': {
        'board': List.generate(42, (_) => 0),
        'currentPlayer': 1,
        'status': 'waiting',
        'round': 1,
        'maxRounds': 3,
        'player1Score': 0,
        'player2Score': 0,
      },
      'createdAt': ServerValue.timestamp,
      'lastActivity': ServerValue.timestamp,
    };

    await roomRef.set(roomData);
    _roomCache[roomCode] = roomData;

    // Cache room code
    final prefs = await SharedPreferences.getInstance();
    final cachedRooms = prefs.getStringList('cached_rooms') ?? [];
    if (!cachedRooms.contains(roomCode)) {
      cachedRooms.add(roomCode);
      await prefs.setStringList('cached_rooms', cachedRooms);
    }

    return roomRef;
  }

  Future<DatabaseReference> joinRoom(String playerName, String roomCode) async {
    if (!_isInitialized) await initialize();

    // Validate player name
    if (playerName.length < _minPlayerNameLength ||
        playerName.length > _maxPlayerNameLength) {
      throw Exception(
          'Player name must be between $_minPlayerNameLength and $_maxPlayerNameLength characters');
    }

    final roomRef = _database.child('rooms/$roomCode');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    final roomData = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(roomData['players'] as Map);

    if (players.length >= _maxPlayersPerRoom) {
      throw Exception('Room is full');
    }

    if (players.containsKey(playerName)) {
      throw Exception('Player name already taken');
    }

    await roomRef.update({
      'players/$playerName': {
        'isHost': false,
        'joinedAt': ServerValue.timestamp,
      },
      'lastActivity': ServerValue.timestamp,
    });

    _roomCache[roomCode] = roomData;
    return roomRef;
  }

  Stream<DatabaseEvent> watchRoom(String roomCode) {
    if (!_isInitialized) initialize();

    final roomRef = _database.child('rooms/$roomCode');
    final subscription = roomRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        _roomCache[roomCode] =
            Map<String, dynamic>.from(event.snapshot.value as Map);
      }
    });

    _subscriptions[roomCode] = subscription;
    return roomRef.onValue;
  }

  Future<void> leaveRoom(String roomCode, String playerName) async {
    if (!_isInitialized) await initialize();

    final roomRef = _database.child('rooms/$roomCode');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final roomData = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(roomData['players'] as Map);

    if (!players.containsKey(playerName)) return;

    if (players.length == 1) {
      // Last player leaving, delete the room
      await roomRef.remove();
      _roomCache.remove(roomCode);

      // Remove from cached rooms
      final prefs = await SharedPreferences.getInstance();
      final cachedRooms = prefs.getStringList('cached_rooms') ?? [];
      cachedRooms.remove(roomCode);
      await prefs.setStringList('cached_rooms', cachedRooms);
    } else {
      // Update room data
      await roomRef.update({
        'players/$playerName': null,
        'lastActivity': ServerValue.timestamp,
      });
    }

    // Cancel subscription
    _subscriptions[roomCode]?.cancel();
    _subscriptions.remove(roomCode);
  }

  Future<void> makeMove(String roomCode, int column, int player) async {
    if (!_isInitialized) await initialize();

    final roomRef = _database.child('rooms/$roomCode');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    final roomData = Map<String, dynamic>.from(snapshot.value as Map);
    final gameState = Map<String, dynamic>.from(roomData['gameState'] as Map);
    final board = List<int>.from(gameState['board'] as List);
    final currentPlayer = gameState['currentPlayer'] as int;

    if (currentPlayer != player) {
      throw Exception('Not your turn');
    }

    // Validate move
    if (column < 0 || column >= 7) {
      throw Exception('Invalid column');
    }

    // Find the lowest empty row in the column
    int row = 5;
    while (row >= 0 && board[row * 7 + column] != 0) {
      row--;
    }

    if (row < 0) {
      throw Exception('Column is full');
    }

    // Make the move
    board[row * 7 + column] = player;

    // Check for win
    bool hasWon = _checkWin(board, row, column, player);

    // Check for draw
    bool isDraw = board.every((cell) => cell != 0);

    // Update game state
    final updates = {
      'gameState/board': board,
      'lastActivity': ServerValue.timestamp,
    };

    if (hasWon) {
      updates['gameState/status'] = 'completed';
      updates['gameState/winner'] = player;
      updates['gameState/${player == 1 ? "player1Score" : "player2Score"}'] =
          ServerValue.increment(1);
    } else if (isDraw) {
      updates['gameState/status'] = 'completed';
      updates['gameState/winner'] = 0; // Draw
      // Do NOT increment any score
    } else {
      updates['gameState/currentPlayer'] = player == 1 ? 2 : 1;
    }

    await roomRef.update(updates);
  }

  bool _checkWin(List<int> board, int row, int col, int player) {
    // Check horizontal
    for (int c = 0; c <= 3; c++) {
      if (board[row * 7 + c] == player &&
          board[row * 7 + c + 1] == player &&
          board[row * 7 + c + 2] == player &&
          board[row * 7 + c + 3] == player) {
        return true;
      }
    }

    // Check vertical
    for (int r = 0; r <= 2; r++) {
      if (board[r * 7 + col] == player &&
          board[(r + 1) * 7 + col] == player &&
          board[(r + 2) * 7 + col] == player &&
          board[(r + 3) * 7 + col] == player) {
        return true;
      }
    }

    // Check diagonal (down-right)
    for (int r = 0; r <= 2; r++) {
      for (int c = 0; c <= 3; c++) {
        if (board[r * 7 + c] == player &&
            board[(r + 1) * 7 + c + 1] == player &&
            board[(r + 2) * 7 + c + 2] == player &&
            board[(r + 3) * 7 + c + 3] == player) {
          return true;
        }
      }
    }

    // Check diagonal (down-left)
    for (int r = 0; r <= 2; r++) {
      for (int c = 3; c < 7; c++) {
        if (board[r * 7 + c] == player &&
            board[(r + 1) * 7 + c - 1] == player &&
            board[(r + 2) * 7 + c - 2] == player &&
            board[(r + 3) * 7 + c - 3] == player) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _roomCache.clear();
    _isInitialized = false;
  }
}
