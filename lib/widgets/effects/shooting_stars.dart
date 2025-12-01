import 'dart:math';
import 'package:flutter/material.dart';

class ShootingStars extends StatefulWidget {
  final Widget child;

  const ShootingStars({required this.child, super.key});

  @override
  State<ShootingStars> createState() => _ShootingStarsState();
}

class _ShootingStarsState extends State<ShootingStars>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(color: const Color(0xFF1E293B)),

        // Stars layer 1
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return CustomPaint(
              painter: StarsPainter(
                progress: _controller1.value,
                seed: 1,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Stars layer 2
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return CustomPaint(
              painter: StarsPainter(
                progress: _controller2.value,
                seed: 2,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Child content (wrapped in Material for TextField support)
        Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ],
    );
  }
}

class StarsPainter extends CustomPainter {
  final double progress;
  final int seed;

  StarsPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width * 1.5 - size.width * 0.25;
      final startY = random.nextDouble() * size.height * 0.5;
      final length = 50 + random.nextDouble() * 100;
      final delay = random.nextDouble();

      final adjustedProgress = (progress + delay) % 1.0;
      final x = startX + adjustedProgress * (size.width + length);
      final y = startY + adjustedProgress * (size.height + length);

      if (x > -length && x < size.width + length && y > -length && y < size.height + length) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + length * 0.3, y + length * 0.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
