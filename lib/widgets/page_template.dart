import 'package:flutter/material.dart';

class PageTemplate extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final VoidCallback? onTrophy;

  const PageTemplate({
    super.key,
    this.title,
    required this.child,
    this.onBack,
    this.onSettings,
    this.onTrophy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D1333),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    minWidth: 280,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (title != null) ...[
                          const SizedBox(height: 32),
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(1, 2),
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                        ],
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Top left back button
            if (onBack != null)
              Positioned(
                top: 24,
                left: 24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
              ),
            // Top right settings and trophy icons
            if (onSettings != null || onTrophy != null)
              Positioned(
                top: 24,
                right: 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onSettings != null)
                      IconButton(
                        icon: const Icon(Icons.settings,
                            color: Colors.white, size: 26),
                        onPressed: onSettings,
                        tooltip: 'Settings',
                      ),
                    if (onTrophy != null)
                      IconButton(
                        icon: const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 26),
                        onPressed: onTrophy,
                        tooltip: 'Trophy',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
