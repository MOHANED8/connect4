// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'dart:math';
import 'services/sound_service.dart';
import 'game_mode_page.dart';

double lerpDouble(num a, num b, double t) => a * (1.0 - t) + b * t;

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
  late AnimationController _buttonController;
  late Animation<double> _logoBounce;
  late Animation<double> _logoFade;
  late Animation<double> _logoPulse;
  late Animation<double> _logoGlow;
  late Animation<double> _logoRotation;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonGlow;
  final SoundService _soundService = SoundService();
  late List<_Particle> _particles;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _particles = List.generate(24, (i) => _Particle(vsync: this));
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoBounce = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticInOut),
    );
    _logoGlow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );
    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Button animations
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _buttonGlow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _logoController.forward();
    _buttonController.repeat(reverse: true);
    _soundService.playButtonClick();
    for (final p in _particles) {
      p.controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _buttonController.dispose();
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _goToMain() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    _soundService.playButtonClick();

    // Add transition animation
    await _buttonController.animateTo(1.0,
        duration: const Duration(milliseconds: 300));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameModePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.shade900,
                      Colors.black,
                    ],
                    stops: [
                      0.0,
                      0.8 + (0.2 * _waveController.value),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: WavePainter(
                    animation: _waveController,
                    color: Colors.indigo.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
          // Particles
          ..._particles.map((p) => AnimatedBuilder(
                animation: p.controller,
                builder: (context, child) {
                  final progress = p.controller.value;
                  final x = lerpDouble(p.startX, p.endX, progress);
                  final y = lerpDouble(p.startY, p.endY, progress);
                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: p.opacity,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color.withOpacity(0.18),
                          boxShadow: [
                            BoxShadow(
                              color: p.color.withOpacity(0.12),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _logoBounce.value),
                        child: Transform.scale(
                          scale: _logoPulse.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                'assets/conecta4_logo.png',
                                height: 120,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent
                                  .withOpacity(_buttonGlow.value * 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black54,
                          ),
                          onPressed: _isTransitioning ? null : _goToMain,
                          child: _isTransitioning
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Start Game',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * 0.5;
    final amplitude = size.height * 0.1;
    const frequency = 2.0;

    path.moveTo(0, y);
    for (double x = 0; x < size.width; x++) {
      path.lineTo(
        x,
        y +
            sin((x / size.width * frequency * pi) +
                    (animation.value * 2 * pi)) *
                amplitude,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

class _Particle {
  final AnimationController controller;
  final double startX, endX, startY, endY, size, opacity;
  final Color color;
  _Particle({required TickerProvider vsync})
      : startX = Random().nextDouble() * 900 + 50,
        endX = Random().nextDouble() * 900 + 50,
        startY = Random().nextDouble() * 600 + 50,
        endY = Random().nextDouble() * 600 + 50,
        size = Random().nextDouble() * 18 + 10,
        opacity = Random().nextDouble() * 0.5 + 0.5,
        color = Random().nextBool() ? Colors.blueAccent : Colors.white,
        controller = AnimationController(
          vsync: vsync,
          duration: Duration(milliseconds: 1800 + Random().nextInt(1200)),
        );
}
