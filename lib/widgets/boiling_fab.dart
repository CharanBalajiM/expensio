import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BoilingFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const BoilingFAB({super.key, required this.onPressed});

  @override
  State<BoilingFAB> createState() => _BoilingFABState();
}

class _BoilingFABState extends State<BoilingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  final List<_BubbleParticle> _particles = [];
  final math.Random _random = math.Random();

  double _lastElapsed = 0.0;
  double _gravityAngle = 0.0; // Current smooth gravity angle in radians

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_onTick)
          ..repeat();

    // Subscribe to accelerometer tilt events for physical sloshing direction
    _sensorSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;

      // Calculate target angle based on gravity vector:
      // Phone upright: x = 0, y = 9.8 => angle = 0 (gravity pointing down)
      // Phone landscape left: x = 9.8, y = 0 => angle = -pi/2
      // Phone landscape right: x = -9.8, y = 0 => angle = pi/2
      final double targetAngle = math.atan2(-event.x, event.y);

      // Ultra-smooth lerping with wrap-around correction to prevent 360 spin jumps
      double diff = targetAngle - _gravityAngle;
      while (diff < -math.pi) {
        diff += math.pi * 2;
      }
      while (diff > math.pi) {
        diff -= math.pi * 2;
      }

      setState(() {
        _gravityAngle += diff * 0.15; // Low-pass filter for natural inertia
      });
    });
  }

  void _onTick() {
    if (!mounted) return;

    // Calculate delta time
    final double currentElapsed = _controller.value;
    double dt = currentElapsed - _lastElapsed;
    if (dt < 0) dt += 1.0; // Handle wrap-around
    _lastElapsed = currentElapsed;

    // Update existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      particle.y -=
          particle.speed * dt * 60; // Rise up (relative to simulated bottom)
      particle.x +=
          math.sin(particle.y * 0.1 + particle.swayOffset) *
          0.5; // Sway side to side
      particle.life -= dt * 2.5; // Reduce lifetime

      if (particle.life <= 0) {
        _particles.removeAt(i);
      }
    }

    // Spawn new particles (boiling bubbles / smoke puffs)
    if (_particles.length < 25 && _random.nextDouble() < 0.25) {
      _particles.add(
        _BubbleParticle(
          x:
              10.0 +
              _random.nextDouble() * 36.0, // Start within the circular region
          y: 56.0, // Start at the bottom of gravity coordinate
          size: 2.0 + _random.nextDouble() * 6.0,
          speed: 0.8 + _random.nextDouble() * 1.2,
          life: 1.0,
          swayOffset: _random.nextDouble() * math.pi * 2,
          color: const Color(
            0xFF00E676,
          ).withValues(alpha: 0.3 + _random.nextDouble() * 0.5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // The animated liquid physics & boiling particles painter
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BoilingPainter(
                        animationValue: _controller.value,
                        particles: List.from(_particles),
                        gravityAngle: _gravityAngle,
                      ),
                    );
                  },
                ),
              ),
              // The centered dynamic green '+' icon (remains perfectly stable and readable)
              const Center(
                child: Icon(
                  Icons.add,
                  color: Color(0xFF00E676),
                  size: 30,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleParticle {
  double x;
  double y;
  double size;
  double speed;
  double life;
  double swayOffset;
  Color color;

  _BubbleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.life,
    required this.swayOffset,
    required this.color,
  });
}

class _BoilingPainter extends CustomPainter {
  final double animationValue;
  final List<_BubbleParticle> particles;
  final double gravityAngle;

  _BoilingPainter({
    required this.animationValue,
    required this.particles,
    required this.gravityAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Save canvas, rotate it dynamically matching phone posture, and restore afterwards
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-gravityAngle);
    canvas.translate(-size.width / 2, -size.height / 2);

    // 1. Draw "boiling water waves" at the bottom
    final double waveHeight = 12.0;
    final double baseHeight = size.height - 14.0;

    // First layer: darker, slower wave
    final path1 = Path();
    path1.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y =
          baseHeight +
          math.sin(
                (x / size.width) * math.pi * 2 + (animationValue * math.pi * 2),
              ) *
              waveHeight *
              0.4;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    paint.color = const Color(0xFF00E676).withValues(alpha: 0.2);
    canvas.drawPath(path1, paint);

    // Second layer: lighter, faster fluid wave
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y =
          baseHeight +
          3 +
          math.cos(
                (x / size.width) * math.pi * 2 - (animationValue * math.pi * 4),
              ) *
              waveHeight *
              0.5;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    paint.color = const Color(0xFF00E676).withValues(alpha: 0.45);
    canvas.drawPath(path2, paint);

    // 2. Draw rising boiling particles / smoke puffs
    for (final p in particles) {
      // ignore: deprecated_member_use
      paint.color = p.color.withValues(alpha: p.color.opacity * p.life);

      final double currentRadius = p.size * (0.4 + 0.6 * p.life);
      canvas.drawCircle(Offset(p.x, p.y), currentRadius, paint);

      if (p.size > 4.5 && p.life > 0.4) {
        paint.color = Colors.white.withValues(alpha: 0.3 * p.life);
        canvas.drawCircle(
          Offset(p.x - currentRadius * 0.3, p.y - currentRadius * 0.3),
          currentRadius * 0.25,
          paint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoilingPainter oldDelegate) {
    return true; // Re-paint on every animation and tilt update
  }
}
