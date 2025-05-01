import 'package:flutter/material.dart';
import 'audio_settings_button.dart';
import 'game_history_page.dart';

class HeaderIconsRow extends StatelessWidget {
  const HeaderIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AudioSettingsButton(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.emoji_events, color: Colors.amber),
          tooltip: 'View Game History',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameHistoryPage()),
            );
          },
        ),
      ],
    );
  }
}
