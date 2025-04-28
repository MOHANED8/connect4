// player_name_page.dart
// ignore_for_file: deprecated_member_use, unused_import, unused_element, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'round_select_page.dart';
import 'widgets/audio_settings_button.dart';
import 'services/sound_service.dart';
import 'widgets/game_history_box.dart';
import 'services/game_history_service.dart';
import 'widgets/game_history_page.dart';
import 'widgets/header_icons_row.dart';
import 'widgets/page_template.dart';
import 'widgets/sound_settings_dialog.dart';

class PlayerNamePage extends StatefulWidget {
  final bool isBotEnabled;
  final String difficulty;

  const PlayerNamePage({
    super.key,
    required this.isBotEnabled,
    required this.difficulty,
  });

  @override
  State<PlayerNamePage> createState() => _PlayerNamePageState();
}

class _PlayerNamePageState extends State<PlayerNamePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController player1Controller = TextEditingController();
  final TextEditingController player2Controller = TextEditingController();
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
    player1Controller.dispose();
    player2Controller.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToNext() {
    final player1Name = player1Controller.text.trim().isEmpty
        ? 'Player 1'
        : player1Controller.text.trim();
    final player2Name = widget.isBotEnabled
        ? 'Bot'
        : player2Controller.text.trim().isEmpty
            ? 'Player 2'
            : player2Controller.text.trim();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RoundSelectPage(
          player1Name: player1Name,
          player2Name: player2Name,
          isBotEnabled: widget.isBotEnabled,
          difficulty: widget.difficulty,
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
      title: 'Enter Player Names',
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
      child: _buildPlayerNameContent(context),
    );
  }

  Widget _buildPlayerNameContent(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final maxHeight = MediaQuery.of(context).size.height;
    final contentWidth = maxWidth > 600 ? 500.0 : maxWidth * 0.95;
    final verticalPadding = maxHeight.clamp(32.0, 120.0) * 0.08;
    final fieldSpacing = maxHeight.clamp(16.0, 60.0) * 0.03;
    final buttonSpacing = maxHeight.clamp(24.0, 80.0) * 0.04;
    final cardPadding = maxWidth.clamp(16.0, 40.0) * 0.05;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentWidth,
            minHeight: maxHeight * 0.5,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      player1Controller,
                      'Player 1',
                      'Enter name for Player 1',
                      maxWidth,
                      maxHeight,
                    ),
                    if (!widget.isBotEnabled) ...[
                      SizedBox(height: fieldSpacing),
                      _buildTextField(
                        player2Controller,
                        'Player 2',
                        'Enter name for Player 2',
                        maxWidth,
                        maxHeight,
                      ),
                    ],
                    SizedBox(height: buttonSpacing),
                    SizedBox(
                      width: double.infinity,
                      height: maxHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: _goToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontSize: maxWidth * 0.04,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    double maxWidth,
    double maxHeight,
  ) {
    final fontSize = maxWidth * 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: maxHeight * 0.01),
        Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white12,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize * 1.1,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: fontSize * 1.1,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: maxWidth * 0.05,
                vertical: maxHeight * 0.02,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
