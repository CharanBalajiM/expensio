import 'dart:math' as math;
import 'package:flutter/material.dart';

class NoDataAnimation extends StatefulWidget {
  const NoDataAnimation({super.key});

  @override
  State<NoDataAnimation> createState() => _NoDataAnimationState();
}

class _NoDataAnimationState extends State<NoDataAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_TrailParticle> _trailParticles = [];
  final math.Random _random = math.Random();
  double _lastElapsed = 0.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 4800),
          )
          ..addListener(_onTick)
          ..repeat();
  }

  void _onTick() {
    if (!mounted) return;

    final double currentElapsed = _controller.value;
    double dt = currentElapsed - _lastElapsed;
    if (dt < 0) dt += 1.0; // Handle wrap-around
    _lastElapsed = currentElapsed;

    // Retrieve container size (we'll assume standard layout size for spawning trail particles, approx 300x180)
    // Using a fallback design width/height so trail positions remain perfectly relative
    const double designWidth = 320.0;
    const double designHeight = 180.0;

    final bubble1Spec = _BubbleSpec(
      startProgress: 0.0,
      endProgress: 0.50,
      startX: designWidth * 0.15,
      endX: designWidth * 0.45,
      startY: designHeight * 0.9,
      endY: designHeight * 0.15,
      swayFrequency: 3.5,
      swayIntensity: 10.0,
      minRadius: 12.0,
      maxRadius: 22.0,
    );

    final bubble2Spec = _BubbleSpec(
      startProgress: 0.30,
      endProgress: 0.80,
      startX: designWidth * 0.55,
      endX: designWidth * 0.85,
      startY: designHeight * 0.9,
      endY: designHeight * 0.2,
      swayFrequency: 3.5,
      swayIntensity: 12.0,
      minRadius: 14.0,
      maxRadius: 26.0,
    );

    // Update existing trail particles
    for (int i = _trailParticles.length - 1; i >= 0; i--) {
      final p = _trailParticles[i];
      p.y -= p.speedY * dt * 50; // Float upwards
      p.x += math.sin(p.y * 0.05 + p.swayOffset) * 0.3; // Gentle wobble/sway
      p.life -= dt * 2.2; // Fade out

      if (p.life <= 0) {
        _trailParticles.removeAt(i);
      }
    }

    // Check and spawn trail particles for Bubble 1 ("No")
    _spawnTrailIfActive(currentElapsed, bubble1Spec);
    // Check and spawn trail particles for Bubble 2 ("Data")
    _spawnTrailIfActive(currentElapsed, bubble2Spec);
  }

  void _spawnTrailIfActive(double globalProgress, _BubbleSpec spec) {
    if (globalProgress >= spec.startProgress &&
        globalProgress <= spec.endProgress) {
      final double p =
          (globalProgress - spec.startProgress) /
          (spec.endProgress - spec.startProgress);

      // Calculate current bubble center
      final double baseLeft = spec.startX + (spec.endX - spec.startX) * p;
      final double baseTop = spec.startY + (spec.endY - spec.startY) * p;
      final double swayX =
          math.sin(p * math.pi * spec.swayFrequency) * spec.swayIntensity;
      final double swayY = math.cos(p * math.pi * 2.0) * 8.0;

      final double bubbleX = baseLeft + swayX;
      final double bubbleY = baseTop + swayY;

      // Calculate current radius at this progress to spawn at bottom outer boundary
      final double radius =
          spec.minRadius + (spec.maxRadius - spec.minRadius) * p;

      // Spawn a small bubble particle from the bottom outer circle boundary of the main bubble
      if (_random.nextDouble() < 0.35) {
        _trailParticles.add(
          _TrailParticle(
            x:
                bubbleX +
                (_random.nextDouble() - 0.5) *
                    (radius * 0.6), // Random offset within the bubble width
            y:
                bubbleY +
                radius +
                1.0, // Spawn at the bottom outer boundary of the circle
            size: 1.5 + _random.nextDouble() * 3.0,
            speedY: 0.3 + _random.nextDouble() * 0.5,
            life: 1.0,
            swayOffset: _random.nextDouble() * math.pi * 2,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _NoDataPainter(
                progress: _controller.value,
                trailParticles: List.from(_trailParticles),
              ),
            );
          },
        );
      },
    );
  }
}

class _BubbleSpec {
  final double startProgress;
  final double endProgress;
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final double swayFrequency;
  final double swayIntensity;
  final double minRadius;
  final double maxRadius;

  _BubbleSpec({
    required this.startProgress,
    required this.endProgress,
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.swayFrequency,
    required this.swayIntensity,
    required this.minRadius,
    required this.maxRadius,
  });
}

class _TrailParticle {
  double x;
  double y;
  double size;
  double speedY;
  double life;
  double swayOffset;

  _TrailParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.life,
    required this.swayOffset,
  });
}

class _BubbleState {
  final String text;
  final double startProgress;
  final double endProgress;
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final double minRadius;
  final double maxRadius;
  final double swayFrequency;
  final double swayIntensity;

  _BubbleState({
    required this.text,
    required this.startProgress,
    required this.endProgress,
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.minRadius,
    required this.maxRadius,
    required this.swayFrequency,
    required this.swayIntensity,
  });
}

class _NoDataPainter extends CustomPainter {
  final double progress;
  final List<_TrailParticle> trailParticles;

  _NoDataPainter({required this.progress, required this.trailParticles});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw bubble trails first (so they render behind the main bubbles)
    final trailPaint = Paint()..style = PaintingStyle.fill;
    final neonColor = const Color(0xFF00E676);

    for (final p in trailParticles) {
      // Scale coordinates to fit actual canvas size if it deviates from design size
      const double designWidth = 320.0;
      const double designHeight = 180.0;
      final double scaleX = size.width / designWidth;
      final double scaleY = size.height / designHeight;

      final double px = p.x * scaleX;
      final double py = p.y * scaleY;
      final double pRadius = p.size * math.min(scaleX, scaleY);

      trailPaint.color = neonColor.withValues(alpha: 0.15 * p.life);
      canvas.drawCircle(Offset(px, py), pRadius + 1.0, trailPaint); // Glow

      trailPaint.color = neonColor.withValues(alpha: 0.35 * p.life);
      canvas.drawCircle(Offset(px, py), pRadius, trailPaint); // Tiny bubble
    }

    // 2. Define and draw primary bubbles
    final bubble1 = _BubbleState(
      text: "No",
      startProgress: 0.0,
      endProgress: 0.50,
      startX: size.width * 0.15,
      endX: size.width * 0.45,
      startY: size.height * 0.9,
      endY: size.height * 0.15,
      minRadius: 12.0,
      maxRadius: 22.0,
      swayFrequency: 3.5,
      swayIntensity: 10.0,
    );

    final bubble2 = _BubbleState(
      text: "Data",
      startProgress: 0.30,
      endProgress: 0.80,
      startX: size.width * 0.55,
      endX: size.width * 0.85,
      startY: size.height * 0.9,
      endY: size.height * 0.2,
      minRadius: 14.0,
      maxRadius: 26.0,
      swayFrequency: 3.5,
      swayIntensity: 12.0,
    );

    _drawBubble(canvas, size, bubble1, progress);
    _drawBubble(canvas, size, bubble2, progress);
  }

  void _drawBubble(
    Canvas canvas,
    Size size,
    _BubbleState bubble,
    double globalProgress,
  ) {
    double p = 0.0;
    if (globalProgress >= bubble.startProgress &&
        globalProgress <= bubble.endProgress) {
      p =
          (globalProgress - bubble.startProgress) /
          (bubble.endProgress - bubble.startProgress);
    } else if (globalProgress > bubble.endProgress &&
        globalProgress < bubble.endProgress + 0.08) {
      p = 1.0;
    } else {
      return;
    }

    final double popProgress = (globalProgress > bubble.endProgress)
        ? (globalProgress - bubble.endProgress) / 0.08
        : 0.0;

    final paint = Paint()..style = PaintingStyle.fill;

    final double baseLeft = bubble.startX + (bubble.endX - bubble.startX) * p;
    final double baseTop = bubble.startY + (bubble.endY - bubble.startY) * p;

    final double swayX =
        math.sin(p * math.pi * bubble.swayFrequency) * bubble.swayIntensity;
    final double swayY = math.cos(p * math.pi * 2.0) * 8.0;

    final double x = baseLeft + swayX;
    final double y = baseTop + swayY;
    final double radius =
        bubble.minRadius + (bubble.maxRadius - bubble.minRadius) * p;

    if (popProgress > 0.0) {
      final popRadius = radius * (1.0 + popProgress * 0.4);
      final opacity = (1.0 - popProgress).clamp(0.0, 1.0);

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0 * (1.0 - popProgress);
      paint.color = const Color(0xFF00E676).withValues(alpha: opacity * 0.8);
      canvas.drawCircle(Offset(x, y), popRadius, paint);

      final particlePaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 6; i++) {
        final double angle = (i * math.pi / 3.0) + (popProgress * 0.5);
        final double distance = radius + (popProgress * 25.0);
        final double px = x + math.cos(angle) * distance;
        final double py = y + math.sin(angle) * distance;
        particlePaint.color = const Color(
          0xFF00E676,
        ).withValues(alpha: opacity * 0.9);
        canvas.drawCircle(
          Offset(px, py),
          2.5 * (1.0 - popProgress),
          particlePaint,
        );
      }
      return;
    }

    final neonColor = const Color(0xFF00E676);

    paint.style = PaintingStyle.fill;
    paint.color = neonColor.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(x, y), radius + 4, paint);

    paint.color = const Color(0xFF141416).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(x, y), radius, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.8;
    paint.color = neonColor.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(x, y), radius, paint);

    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(x - radius * 0.35, y - radius * 0.35),
      radius * 0.22,
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: bubble.text,
        style: TextStyle(
          color: neonColor,
          fontWeight: FontWeight.bold,
          fontSize: (bubble.text == "No") ? 10 : 12,
          letterSpacing: 0.2,
          shadows: [
            Shadow(color: neonColor.withValues(alpha: 0.4), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _NoDataPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trailParticles != trailParticles;
  }
}
