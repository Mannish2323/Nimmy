// 🟣 NIMMY — Animated Orb Widget
// ===============================
// The signature Nimmy orb with particle effects and state animations.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum NimmyOrbState { idle, listening, thinking, speaking, recording, taskComplete }

class NimmyOrbWidget extends StatefulWidget {
  final double size;
  final NimmyOrbState state;
  final VoidCallback? onTap;

  const NimmyOrbWidget({
    super.key,
    this.size = 120,
    this.state = NimmyOrbState.idle,
    this.onTap,
  });

  @override
  State<NimmyOrbWidget> createState() => _NimmyOrbWidgetState();
}

class _NimmyOrbWidgetState extends State<NimmyOrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color _getGlowColor() {
    switch (widget.state) {
      case NimmyOrbState.idle:
        return NimmyColors.purple;
      case NimmyOrbState.listening:
        return NimmyColors.cyan;
      case NimmyOrbState.thinking:
        return NimmyColors.amber;
      case NimmyOrbState.speaking:
        return NimmyColors.green;
      case NimmyOrbState.recording:
        return NimmyColors.red;
      case NimmyOrbState.taskComplete:
        return NimmyColors.green;
    }
  }

  double _getRotationSpeed() {
    switch (widget.state) {
      case NimmyOrbState.idle:
        return 1.0;
      case NimmyOrbState.listening:
        return 1.5;
      case NimmyOrbState.thinking:
        return 3.0;
      case NimmyOrbState.speaking:
        return 2.0;
      case NimmyOrbState.recording:
        return 1.2;
      case NimmyOrbState.taskComplete:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getGlowColor();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _rotateController,
          _particleController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _NimmyOrbPainter(
                  glowColor: glowColor,
                  rotationAngle: _rotateController.value * 2 * pi * _getRotationSpeed(),
                  particlePhase: _particleController.value,
                  state: widget.state,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NimmyOrbPainter extends CustomPainter {
  final Color glowColor;
  final double rotationAngle;
  final double particlePhase;
  final NimmyOrbState state;

  _NimmyOrbPainter({
    required this.glowColor,
    required this.rotationAngle,
    required this.particlePhase,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.6;

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Middle glow
    final midGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 1.1, midGlow);

    // Core orb gradient
    final coreGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.0,
      colors: [
        glowColor.withValues(alpha: 0.9),
        glowColor.withValues(alpha: 0.6),
        glowColor.withValues(alpha: 0.3),
      ],
    );
    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, corePaint);

    // Inner bright core
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(-5, -5), radius * 0.3, innerPaint);

    // Orbiting particles
    _drawParticles(canvas, center, radius, 12);

    // Orbit ring
    final ringPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 1.3, ringPaint);
  }

  void _drawParticles(Canvas canvas, Offset center, double radius, int count) {
    final random = Random(42);
    for (int i = 0; i < count; i++) {
      final angle = rotationAngle + (i * 2 * pi / count);
      final orbitRadius = radius * (1.2 + 0.3 * sin(particlePhase * 2 * pi + i));
      final x = center.dx + cos(angle) * orbitRadius;
      final y = center.dy + sin(angle) * orbitRadius;
      
      final particlePaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4 + 0.3 * random.nextDouble())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NimmyOrbPainter oldDelegate) => true;
}
