import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingDustBackground extends StatefulWidget {
  // Static touch notifier to stream coordinates from the global navigation listener
  static final ValueNotifier<Offset?> touchPosition = ValueNotifier<Offset?>(null);

  const FloatingDustBackground({super.key});

  @override
  State<FloatingDustBackground> createState() => _FloatingDustBackgroundState();
}

class _FloatingDustBackgroundState extends State<FloatingDustBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_DustParticle> _particles = [];
  final math.Random _random = math.Random();
  double _lastElapsed = 0.0;
  static const int _fixedParticleCount = 15; // Exactly 15 fixed particles

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onTick)
     ..repeat();

    // Populate exactly _fixedParticleCount particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < _fixedParticleCount; i++) {
        _particles.add(
          _DustParticle(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            size: 1.5 + _random.nextDouble() * 3.5,
            speedY: 0.15 + _random.nextDouble() * 0.35,
            swaySpeed: 0.5 + _random.nextDouble() * 1.5,
            swayIntensity: 0.5 + _random.nextDouble() * 1.5,
            swayOffset: _random.nextDouble() * math.pi * 2,
            vx: 0.0,
            vy: -0.15 - _random.nextDouble() * 0.35,
          ),
        );
      }
    });
  }

  void _onTick() {
    if (!mounted) return;

    final double currentElapsed = _controller.value;
    double dt = currentElapsed - _lastElapsed;
    if (dt < 0) dt += 1.0;
    _lastElapsed = currentElapsed;

    final size = MediaQuery.of(context).size;
    if (size.width == 0 || size.height == 0) return;

    final touchPos = FloatingDustBackground.touchPosition.value;

    // Update the fixed particles
    for (final p in _particles) {
      // Update positions based on velocities
      p.x += p.vx * dt * 320;
      p.y += p.vy * dt * 320;

      // Friction / decay to return to normal upward drift velocity
      p.vx *= 0.94;
      p.vy = (p.vy * 0.94) - (p.speedY * 0.06);

      // React to pointer drag / proximity (Repulsion)
      if (touchPos != null) {
        final dx = p.x - touchPos.dx;
        final dy = p.y - touchPos.dy;
        final distSq = dx * dx + dy * dy;
        final radius = 130.0;
        if (distSq < radius * radius && distSq > 1.0) {
          final dist = math.sqrt(distSq);
          // Push vector pointing away from touch position (stronger force when closer)
          final force = (radius - dist) / radius;
          final forceX = (dx / dist) * force * 6.5;
          final forceY = (dy / dist) * force * 6.5;
          p.vx += forceX;
          p.vy += forceY;
        }
      }

      // Sway motion
      p.swayOffset += p.swaySpeed * dt * 2.5;
      p.x += math.sin(p.swayOffset) * p.swayIntensity * 0.25;

      // Wrap around horizontal boundaries
      if (p.x < 0) p.x = size.width;
      if (p.x > size.width) p.x = 0;

      // Infinity loop wrapping: if a particle floats off top, wrap to bottom
      if (p.y < -10) {
        p.y = size.height + 10;
        p.x = _random.nextDouble() * size.width;
        p.vx = 0;
        p.vy = -p.speedY;
      }
      // If pushed off bottom, wrap to top
      else if (p.y > size.height + 20) {
        p.y = -10;
        p.x = _random.nextDouble() * size.width;
        p.vx = 0;
        p.vy = -p.speedY;
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
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _DustPainter(
                particles: _particles,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DustParticle {
  double x;
  double y;
  double size;
  double speedY;
  double swaySpeed;
  double swayIntensity;
  double swayOffset;
  double vx; // X Velocity
  double vy; // Y Velocity

  _DustParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.swaySpeed,
    required this.swayIntensity,
    required this.swayOffset,
    required this.vx,
    required this.vy,
  });
}

class _DustPainter extends CustomPainter {
  final List<_DustParticle> particles;

  _DustPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final greenColor = const Color(0xFF00E676);

    for (final p in particles) {
      double opacity = 1.0;
      
      // Smooth fade-in at bottom and fade-out at top boundaries
      if (p.y < 120) {
        opacity *= (p.y / 120.0).clamp(0.0, 1.0);
      } else if (p.y > size.height - 80) {
        opacity *= ((size.height - p.y) / 80.0).clamp(0.0, 1.0);
      }
      
      // Elegant, clearly visible premium opacity limit
      final double finalOpacity = (opacity * 0.38).clamp(0.0, 0.38);

      // Draw subtle glow shadow around each glowing ember
      paint.color = greenColor.withValues(alpha: finalOpacity * 0.45);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.5, paint);

      // Draw particle core
      paint.color = greenColor.withValues(alpha: finalOpacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) {
    return true; // Repaint continuously on every frame tick
  }
}
