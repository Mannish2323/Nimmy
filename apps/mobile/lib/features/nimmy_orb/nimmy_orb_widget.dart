import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/nimmy_state.dart';

export '../../models/nimmy_state.dart';

class NimmyOrbWidget extends StatefulWidget {
  const NimmyOrbWidget({
    super.key,
    this.size = 150,
    this.state = NimmyOrbState.idle,
    this.onTap,
    this.audioLevel = 0.35,
  });

  final double size;
  final NimmyOrbState state;
  final VoidCallback? onTap;
  final double audioLevel;

  @override
  State<NimmyOrbWidget> createState() => _NimmyOrbWidgetState();
}

class _NimmyOrbWidgetState extends State<NimmyOrbWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final stateLabel = widget.state.name;
    return Semantics(
      button: widget.onTap != null,
      label: 'Nimmy is $stateLabel',
      child: GestureDetector(
        onTap: widget.onTap,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _orbit]),
            builder: (context, _) {
              final breath = reducedMotion ? 0.5 : _breath.value;
              final orbit = reducedMotion ? 0.15 : _orbit.value;
              return SizedBox.square(
                dimension: widget.size,
                child: CustomPaint(
                  painter: _NimmyOrbPainter(
                    state: widget.state,
                    breath: breath,
                    phase: orbit,
                    audioLevel: widget.audioLevel.clamp(0, 1),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NimmyOrbPainter extends CustomPainter {
  const _NimmyOrbPainter({
    required this.state,
    required this.breath,
    required this.phase,
    required this.audioLevel,
  });

  final NimmyOrbState state;
  final double breath;
  final double phase;
  final double audioLevel;

  Color get color => switch (state) {
    NimmyOrbState.listening => NimmyColors.cyan,
    NimmyOrbState.understanding || NimmyOrbState.thinking => NimmyColors.indigo,
    NimmyOrbState.confirming => NimmyColors.amber,
    NimmyOrbState.executing => NimmyColors.purpleLight,
    NimmyOrbState.success => NimmyColors.green,
    NimmyOrbState.speaking => NimmyColors.purpleLight,
    NimmyOrbState.error => NimmyColors.pink,
    NimmyOrbState.recording => NimmyColors.red,
    NimmyOrbState.idle => NimmyColors.purple,
  };

  double get speed => switch (state) {
    NimmyOrbState.thinking || NimmyOrbState.executing => 3.1,
    NimmyOrbState.understanding => 2.1,
    NimmyOrbState.listening || NimmyOrbState.speaking => 1.65,
    NimmyOrbState.error => 2.4,
    _ => 1,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.shortestSide;
    final coreRadius = unit * (0.235 + breath * 0.012);
    final activeLevel = switch (state) {
      NimmyOrbState.listening || NimmyOrbState.speaking => audioLevel,
      NimmyOrbState.thinking || NimmyOrbState.executing => 0.65,
      _ => 0.25,
    };

    _drawAmbientGlow(canvas, center, coreRadius);
    _drawEnergyRings(canvas, center, coreRadius, activeLevel);
    _drawParticleSphere(canvas, center, coreRadius, activeLevel);
    _drawCore(canvas, center, coreRadius);
    _drawStateSignal(canvas, center, coreRadius, activeLevel);
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, double radius) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.12 + breath * 0.06)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7);
    canvas.drawCircle(center, radius * (1.45 + breath * 0.1), glow);
  }

  void _drawEnergyRings(
    Canvas canvas,
    Offset center,
    double radius,
    double level,
  ) {
    for (var i = 0; i < 3; i++) {
      final ringRadius = radius * (1.3 + i * 0.22 + level * 0.08);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.4 : 0.8
        ..color = color.withValues(alpha: 0.25 - i * 0.055);
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((phase * math.pi * 2 * speed) + i * 0.8);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawArc(rect, i * 1.7, math.pi * (0.9 + i * 0.18), false, paint);
      canvas.restore();
    }
  }

  void _drawParticleSphere(
    Canvas canvas,
    Offset center,
    double radius,
    double level,
  ) {
    final random = math.Random(4127);
    const count = 56;
    for (var i = 0; i < count; i++) {
      final baseAngle = random.nextDouble() * math.pi * 2;
      final depth = random.nextDouble();
      final orbit = radius * (0.72 + depth * 0.95 + level * 0.08);
      final direction = i.isEven ? 1.0 : -0.62;
      final angle = baseAngle + phase * math.pi * 2 * speed * direction;
      final squash = 0.52 + depth * 0.34;
      final point = Offset(
        center.dx + math.cos(angle) * orbit,
        center.dy + math.sin(angle) * orbit * squash,
      );
      final front = (math.sin(angle) + 1) / 2;
      final dotRadius = 0.7 + depth * 1.45 + front * 0.6;
      final dotPaint = Paint()
        ..color = Color.lerp(
          color.withValues(alpha: 0.22),
          NimmyColors.textPrimary.withValues(alpha: 0.84),
          front * 0.35,
        )!;
      canvas.drawCircle(point, dotRadius, dotPaint);
    }
  }

  void _drawCore(Canvas canvas, Offset center, double radius) {
    final coreRect = Rect.fromCircle(center: center, radius: radius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.35),
        radius: 1.1,
        colors: [
          Colors.white.withValues(alpha: 0.9),
          color.withValues(alpha: 0.92),
          NimmyColors.purpleDark.withValues(alpha: 0.72),
          NimmyColors.voidBlack.withValues(alpha: 0.92),
        ],
        stops: const [0, 0.14, 0.58, 1],
      ).createShader(coreRect);
    canvas.drawCircle(center, radius, corePaint);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.8),
          NimmyColors.cyan.withValues(alpha: 0.55),
          color.withValues(alpha: 0.08),
        ],
        transform: GradientRotation(phase * math.pi * 2),
      ).createShader(coreRect);
    canvas.drawCircle(center, radius * 1.02, rim);
  }

  void _drawStateSignal(
    Canvas canvas,
    Offset center,
    double radius,
    double level,
  ) {
    if (state == NimmyOrbState.listening ||
        state == NimmyOrbState.speaking ||
        state == NimmyOrbState.recording) {
      final waveformPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6;
      for (var i = 0; i < 28; i++) {
        final angle = (i / 28) * math.pi * 2;
        final wave =
            0.5 + 0.5 * math.sin(angle * 4 + phase * math.pi * 8 * speed);
        final start = radius * 1.63;
        final end = start + radius * (0.08 + level * wave * 0.2);
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * start,
          center + Offset(math.cos(angle), math.sin(angle)) * end,
          waveformPaint,
        );
      }
    }

    if (state == NimmyOrbState.success) {
      final burst = Paint()
        ..color = color.withValues(alpha: 0.68)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 14; i++) {
        final angle = i / 14 * math.pi * 2;
        final start = radius * (1.5 + breath * 0.2);
        final end = start + radius * 0.18;
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * start,
          center + Offset(math.cos(angle), math.sin(angle)) * end,
          burst,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NimmyOrbPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.breath != breath ||
        oldDelegate.phase != phase ||
        oldDelegate.audioLevel != audioLevel;
  }
}
