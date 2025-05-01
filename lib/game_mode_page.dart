// ignore_for_file: deprecated_member_use, unused_local_variable, unused_import, unused_element, use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'player_name_page.dart';
import 'widgets/audio_settings_button.dart';
import 'services/sound_service.dart';
import 'widgets/game_history_box.dart';
import 'services/game_history_service.dart';
import 'widgets/game_history_page.dart';
import 'widgets/header_icons_row.dart';
import 'services/online_game_service.dart';
import 'online_game_page.dart';
import 'widgets/page_template.dart';
import 'widgets/sound_settings_dialog.dart';

class GameModePage extends StatefulWidget {
  const GameModePage({super.key});

  @override
  State<GameModePage> createState() => _GameModePageState();
}

class _GameModePageState extends State<GameModePage>
    with SingleTickerProviderStateMixin {
  bool isBotEnabled = false;
  String difficulty = 'Beginner';
  bool isOnlineMode = false;
  final TextEditingController onlineNameController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool isWaitingForMatch = false;
  String? matchId;
  bool isCreatingRoom = false;
  bool isJoiningRoom = false;
  String? createdRoomCode;
  final TextEditingController joinCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    joinCodeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    onlineNameController.dispose();
    joinCodeController.dispose();
    super.dispose();
  }

  void _goToNext() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlayerNamePage(
          isBotEnabled: isBotEnabled,
          difficulty: difficulty,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SoundService.setSnackBarContext(context);
    return PageTemplate(
      title: isOnlineMode ? 'Play Online' : 'Select Game Mode',
      onBack: isOnlineMode ? () => setState(() => isOnlineMode = false) : null,
      onSettings: () {
        showDialog(
          context: context,
          builder: (context) => const SoundSettingsDialog(),
        );
      },
      onTrophy: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GameHistoryPage()),
        );
      },
      child: isOnlineMode ? _buildOnlineMode(18, 16) : _buildMainMenuContent(),
    );
  }

  Widget _buildMainMenuContent() {
    final constraints = MediaQuery.of(context).size;
    final smallestDimension = constraints.width < constraints.height
        ? constraints.width
        : constraints.height;
    final fontSize = smallestDimension * 0.04;
    final iconSize = smallestDimension * 0.05;
    final padding = smallestDimension * 0.04;
    final contentWidth =
        constraints.width > 600 ? 500.0 : constraints.width * 0.95;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentWidth,
            minHeight: constraints.height * 0.5,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: constraints.height * 0.08),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOnlineModeSelector(fontSize, iconSize, padding),
                    _buildModeSelector(fontSize, iconSize, padding),
                    if (isBotEnabled) ...[
                      SizedBox(height: padding * 1.5),
                      _buildDifficultySelector(fontSize, iconSize, padding),
                    ],
                    SizedBox(height: padding * 2),
                    _buildNextButton(fontSize, padding),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(double fontSize, double iconSize, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: padding * 0.5),
          child: Text(
            'Game Mode',
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: padding),
        Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<bool>(
                  value: isBotEnabled,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: iconSize,
                  ),
                  dropdownColor: Colors.grey[850],
                  items: [
                    _buildModeItem(false, 'Two Player', Icons.people,
                        Colors.blue, fontSize, iconSize, padding),
                    _buildModeItem(true, 'Vs Bot', Icons.smart_toy,
                        Colors.purple, fontSize, iconSize, padding),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => isBotEnabled = value);
                      if (value) {
                        _controller.forward();
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<bool> _buildModeItem(
    bool value,
    String text,
    IconData icon,
    Color color,
    double fontSize,
    double iconSize,
    double padding,
  ) {
    return DropdownMenuItem<bool>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.75),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          SizedBox(width: padding),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(
      double fontSize, double iconSize, double padding) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isBotEnabled ? 1.0 : 0.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: padding * 0.5),
            child: Text(
              'Difficulty Level',
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: padding),
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: difficulty,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: iconSize,
                    ),
                    dropdownColor: Colors.grey[850],
                    items: [
                      _buildDifficultyItem('Beginner', Colors.green,
                          Icons.star_border, fontSize, iconSize, padding),
                      _buildDifficultyItem('Intermediate', Colors.orange,
                          Icons.star_half, fontSize, iconSize, padding),
                      _buildDifficultyItem('Professional', Colors.red,
                          Icons.star, fontSize, iconSize, padding),
                    ],
                    onChanged: (value) => setState(() => difficulty = value!),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDifficultyItem(
    String text,
    Color color,
    IconData icon,
    double fontSize,
    double iconSize,
    double padding,
  ) {
    return DropdownMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding * 0.75),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          SizedBox(width: padding),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(double fontSize, double padding) {
    return ElevatedButton(
      onPressed: _goToNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: padding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        'Next',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOnlineModeSelector(
      double fontSize, double iconSize, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: padding * 0.5, bottom: padding * 0.5),
          child: Text(
            'Or Play Online',
            style: TextStyle(
              color: Colors.amber,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.public, color: Colors.amber),
          label: Text(
            'Play Online',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.withOpacity(0.1),
            foregroundColor: Colors.amber,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: padding * 0.75),
          ),
          onPressed: () => setState(() => isOnlineMode = true),
        ),
        SizedBox(height: padding * 1.5),
      ],
    );
  }

  Widget _buildOnlineMode(double fontSize, double padding) {
    final onlineService = OnlineGameService();
    if (isCreatingRoom) {
      // Host: create a room and wait for opponent
      if (createdRoomCode == null) {
        final code = onlineService.generateRoomCode();
        setState(() {
          createdRoomCode = code;
        });
        final channel = onlineService.createRoom(
          onlineNameController.text.trim().isEmpty
              ? 'Player'
              : onlineNameController.text.trim(),
          code,
        );
        onlineService.listenToRoom(channel).listen((data) {
          if (data['type'] == 'state' &&
              data['status'] == 'active' &&
              data['player2'] != null) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineGamePage(
                  matchId: code,
                  playerName: onlineNameController.text.trim().isEmpty
                      ? 'Player'
                      : onlineNameController.text.trim(),
                ),
              ),
            );
          } else if (data['type'] == 'error') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(data['message'] ?? 'Error occurred.'),
                  backgroundColor: Colors.red),
            );
            setState(() {
              isCreatingRoom = false;
              createdRoomCode = null;
              isWaitingForMatch = false;
            });
          }
        });
        isWaitingForMatch = true;
      }
      return Card(
        color: Colors.white.withOpacity(0.08),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Room Code:',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SelectableText(
                createdRoomCode ?? '...waiting...',
                style: TextStyle(
                    fontSize: fontSize * 1.5,
                    color: Colors.white,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isWaitingForMatch)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 16),
                    Text('Waiting for opponent...',
                        style: TextStyle(color: Colors.amber)),
                  ],
                ),
              TextButton(
                onPressed: () => setState(() {
                  isCreatingRoom = false;
                  createdRoomCode = null;
                  isWaitingForMatch = false;
                }),
                child:
                    const Text('Back', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }
    if (isJoiningRoom) {
      return Card(
        color: Colors.white.withOpacity(0.08),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: joinCodeController,
                style: TextStyle(color: Colors.white, fontSize: fontSize * 1.1),
                decoration: InputDecoration(
                  labelText: 'Enter Room Code',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (joinCodeController.text.trim().isNotEmpty &&
                        !isWaitingForMatch)
                    ? () async {
                        setState(() {
                          isWaitingForMatch = true;
                        });
                        final code =
                            joinCodeController.text.trim().toUpperCase();
                        final playerName =
                            onlineNameController.text.trim().isEmpty
                                ? 'Player'
                                : onlineNameController.text.trim();
                        final channel =
                            onlineService.joinRoom(playerName, code);
                        onlineService.listenToRoom(channel).listen((data) {
                          if (data['type'] == 'state' &&
                              data['status'] == 'active' &&
                              data['player2'] != null) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OnlineGamePage(
                                  matchId: code,
                                  playerName: playerName,
                                ),
                              ),
                            );
                          } else if (data['type'] == 'error') {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      data['message'] ?? 'Error occurred.'),
                                  backgroundColor: Colors.red),
                            );
                            setState(() {
                              isJoiningRoom = false;
                              isWaitingForMatch = false;
                            });
                          }
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                ),
                child: Text('Join Game',
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  isJoiningRoom = false;
                  joinCodeController.clear();
                  isWaitingForMatch = false;
                }),
                child:
                    const Text('Back', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }
    // Default: show create/join options
    return Card(
      color: Colors.white.withOpacity(0.08),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: onlineNameController,
              style: TextStyle(color: Colors.white, fontSize: fontSize * 1.1),
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_box, color: Colors.amber),
              label: Text('Create Online Game',
                  style: TextStyle(
                      fontSize: fontSize, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: padding * 0.75),
              ),
              onPressed: isWaitingForMatch
                  ? null
                  : () async {
                      setState(() {
                        isCreatingRoom = true;
                        isWaitingForMatch = true;
                      });
                    },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.input, color: Colors.amber),
              label: Text('Join Online Game',
                  style: TextStyle(
                      fontSize: fontSize, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: padding * 0.75),
              ),
              onPressed: isWaitingForMatch
                  ? null
                  : () {
                      setState(() {
                        isJoiningRoom = true;
                      });
                    },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => setState(() => isOnlineMode = false),
              child:
                  const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
