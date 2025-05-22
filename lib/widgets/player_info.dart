// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class PlayerInfo extends StatelessWidget {
  final String name;
  final Color color;
  final int score;
  final double fontSize;
  final bool isActive;

  const PlayerInfo({
    super.key,
    required this.name,
    required this.color,
    required this.score,
    required this.fontSize,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.7),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                name == "Bot" ? Icons.smart_toy : Icons.emoji_emotions,
                color: color,
                size: fontSize * 1.5,
              ),
            ),
            SizedBox(width: fontSize * 0.5),
            Text(
              name,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: fontSize * 0.25),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.75,
            vertical: fontSize * 0.25,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
