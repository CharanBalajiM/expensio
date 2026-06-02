import 'dart:math' as math;
import 'package:flutter/material.dart';

class MinimalIoAnimator extends StatefulWidget {
  const MinimalIoAnimator({super.key});

  @override
  State<MinimalIoAnimator> createState() => _MinimalIoAnimatorState();
}

class _MinimalIoAnimatorState extends State<MinimalIoAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // The full word to be animated as a single cohesive unit
  final List<String> _letters = ['x', 'p', 'e', 'n', 's', '.', 'i', 'o'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _letters.length,
            (index) => _buildLetter(_letters[index], index),
          ),
        );
      },
    );
  }

  Widget _buildLetter(String letter, int index) {
    final double value = _controller.value;
    // Calculate phase shift for beautiful staggered wave movement
    final double phase = -index * 0.45; // slightly tighter wave stagger
    final double angle = (value * 2 * math.pi) + phase;

    // Wave offset for vertical movement
    final double offsetY = math.sin(angle) * 1.5;

    // Glow pulsation level based on position in wave
    final double glowIntensity = 0.35 + (math.sin(angle) * 0.25).abs();

    // Dark-green-to-light-green color gradient interpolation
    final double t = index / (_letters.length - 1);
    final Color startColor = const Color.fromARGB(
      255,
      0,
      158,
      79,
    ); // Dark green
    final Color endColor = const Color(0xFF00E676); // Light green
    final Color letterColor = Color.lerp(startColor, endColor, t)!;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.5),
        child: Text(
          letter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: letterColor,
            fontSize: 20,
            shadows: [
              Shadow(
                color: letterColor.withValues(alpha: glowIntensity),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
