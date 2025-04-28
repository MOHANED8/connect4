// round_select_page.dart
// ignore_for_file: deprecated_member_use, unused_import, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'game_page.dart';
import 'widgets/audio_settings_button.dart';
import 'services/sound_service.dart';
import 'widgets/game_history_box.dart';
import 'services/game_history_service.dart';
import 'widgets/game_history_page.dart';
import 'widgets/header_icons_row.dart';
import 'widgets/page_template.dart';
import 'widgets/sound_settings_dialog.dart';

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
    SoundService.setSnackBarContext(context);
    return PageTemplate(
      title: 'Select Rounds',
      onBack: () => Navigator.pop(context),
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
      child: _buildRoundSelectContent(context),
    );
  }

  Widget _buildRoundSelectContent(BuildContext context) {
    final constraints = MediaQuery.of(context).size;
    final smallestDimension = constraints.width < constraints.height
        ? constraints.width
        : constraints.height;
    final fontSize = smallestDimension * 0.04;
    final iconSize = smallestDimension * 0.05;
    final padding = smallestDimension * 0.04;
    final contentWidth =
        constraints.width > 600 ? 500.0 : constraints.width * 0.95;
    final verticalPadding = constraints.height.clamp(32.0, 120.0) * 0.08;
    final fieldSpacing = constraints.height.clamp(16.0, 60.0) * 0.03;
    final buttonSpacing = constraints.height.clamp(24.0, 80.0) * 0.04;
    final cardPadding = constraints.width.clamp(16.0, 40.0) * 0.05;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentWidth,
            minHeight: constraints.height * 0.5,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: padding * 0.5),
                      child: Text(
                        'Number of Rounds',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),
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
                            child: DropdownButton<int>(
                              value: maxRounds,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: iconSize,
                              ),
                              dropdownColor: Colors.grey[850],
                              items: [1, 3, 5].map((rounds) {
                                return DropdownMenuItem(
                                  value: rounds,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(padding * 0.75),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$rounds',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: padding),
                                      Text(
                                        rounds == 1 ? 'Round' : 'Rounds',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                      ),
                    ),
                    SizedBox(height: buttonSpacing),
                    ElevatedButton(
                      onPressed: _startGame,
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
                        'Start Game',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
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
