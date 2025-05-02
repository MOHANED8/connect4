// ignore_for_file: empty_catches, avoid_print

import 'dart:math';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
<<<<<<< HEAD
import 'package:flutter/foundation.dart';

// Set this to your public server address after deployment
const String kWebSocketHost = String.fromEnvironment('WEBSOCKET_HOST', defaultValue: 'localhost:8080');
=======
>>>>>>> 91d1c83a1b40e4b28bbac7107a0cce42384e10d0

class OnlineGameService {
  // Generate a simple 6-letter room code
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _getWebSocketUrl(String roomCode, String playerName,
      {bool isHost = false}) {
<<<<<<< HEAD
    final host = kWebSocketHost;
    final isLocalhost = host.contains('localhost') || host.contains('127.0.0.1');
    final protocol = (kIsWeb && !isLocalhost) ? 'wss' : 'ws';
    return '$protocol://$host/?matchId=$roomCode&playerName=$playerName${isHost ? '&host=1' : ''}';
=======
    // Use localhost for local development
    const host = 'localhost:8080';
    return 'ws://$host/?matchId=$roomCode&playerName=$playerName${isHost ? '&host=1' : ''}';
>>>>>>> 91d1c83a1b40e4b28bbac7107a0cce42384e10d0
  }

  // Create a room and return the WebSocket channel
  WebSocketChannel createRoom(String playerName, String roomCode) {
    final uri = Uri.parse(_getWebSocketUrl(roomCode, playerName, isHost: true));
    return WebSocketChannel.connect(uri);
  }

  // Join a room and return the WebSocket channel
  WebSocketChannel joinRoom(String playerName, String roomCode) {
    final uri = Uri.parse(_getWebSocketUrl(roomCode, playerName));
    return WebSocketChannel.connect(uri);
  }

  // Listen to room state changes (returns a stream of decoded JSON messages)
  Stream<Map<String, dynamic>> listenToRoom(WebSocketChannel channel) {
    return channel.stream
        .map((event) => jsonDecode(event) as Map<String, dynamic>);
  }

  // Send a move to the server
  void sendMove(WebSocketChannel channel, int col, int player) {
    final move = {
      'type': 'move',
      'col': col,
      'player': player,
    };
    channel.sink.add(jsonEncode(move));
  }

  // Leave the room (close the connection)
  void leaveRoom(WebSocketChannel channel) {
    final leaveMsg = {
      'type': 'leave',
    };
    channel.sink.add(jsonEncode(leaveMsg));
    channel.sink.close(status.goingAway);
  }
}
