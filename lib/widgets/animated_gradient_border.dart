// ملف: widgets/animated_gradient_border.dart

import 'package:flutter/material.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 3,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            animationValue: _animation.value,
            borderWidth: widget.borderWidth,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double animationValue;
  final double borderWidth;

  _GradientBorderPainter({
    required this.animationValue,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      startAngle: animationValue,
      endAngle: animationValue + 2 * 3.14159,
      colors: const [
        Color(0xFF1E3A8A),
        Color(0xFF3B82F6),
        Color(0xFF60A5FA),
        Color(0xFFF59E0B),
        Color(0xFF1E3A8A),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - borderWidth / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
