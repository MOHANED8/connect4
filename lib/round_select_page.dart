// round_select_page.dart
// ignore_for_file: deprecated_member_use, unused_import, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_page.dart';
import 'widgets/audio_settings_button.dart';
import 'services/sound_service.dart';
import 'widgets/header_icons_row.dart';
import 'widgets/page_template.dart';
import 'widgets/sound_settings_dialog.dart';
import 'pages/game_history_page.dart';

class RoundSelectPage extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final bool isBotEnabled;
  final String difficulty;

  const RoundSelectPage({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.isBotEnabled,
    required this.difficulty,
  });

  @override
  State<RoundSelectPage> createState() => _RoundSelectPageState();
}

class _RoundSelectPageState extends State<RoundSelectPage>
    with SingleTickerProviderStateMixin {
  int maxRounds = 3;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    SoundService().playButtonClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GamePage(
          player1Name: widget.player1Name,
          player2Name: widget.player2Name,
          isBotEnabled: widget.isBotEnabled,
          difficulty: widget.difficulty,
          maxRounds: maxRounds,
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
    SoundService().playButtonClick();
    SoundService.setSnackBarContext(context);
    return PageTemplate(
      title: 'Select Rounds',
      onBack: () {
        SoundService().playButtonClick();
        Navigator.pop(context);
      },
      onSettings: () {
        SoundService().playButtonClick();
        showDialog(
          context: context,
          builder: (context) => const SoundSettingsDialog(),
        );
      },
      onTrophy: () {
        SoundService().playButtonClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GameHistoryPage()),
        );
      },
      child: _buildRoundSelectContent(context),
    );
  }

  Widget _buildRoundSelectContent(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final contentWidth = maxWidth > 500 ? 400.0 : maxWidth * 0.95;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Number of Rounds',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: maxRounds,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                          dropdownColor: Colors.grey[850],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                          items: [1, 3, 5].map((rounds) {
                            return DropdownMenuItem(
                              value: rounds,
                              child: Text('$rounds Rounds'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => maxRounds = value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28.0),
                    SizedBox(
                      width: double.infinity,
                      height: 52.0,
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 18.0,
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
      ),
    );
  }
}
