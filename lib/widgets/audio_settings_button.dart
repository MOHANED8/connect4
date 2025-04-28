// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'sound_settings_dialog.dart';

class AudioSettingsButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;

  const AudioSettingsButton({
    super.key,
    this.iconColor,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(
          Icons.settings,
          color: iconColor ?? Colors.white70,
          size: iconSize ?? 28,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        tooltip: 'Audio Settings',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const SoundSettingsDialog(),
          );
        },
      ),
    );
  }
}
