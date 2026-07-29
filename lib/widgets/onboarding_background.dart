import 'package:flutter/material.dart';

class OnboardingBackgroundPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final double animationValue;

  OnboardingBackgroundPainter({
    required this.colorScheme,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final isDark = colorScheme.brightness == Brightness.dark;

    // Large soft blob top-right
    final blob1Path = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(
        size.width * 0.9, size.height * 0.05 * animationValue,
        size.width, size.height * 0.15 * animationValue,
      )
      ..quadraticBezierTo(
        size.width, size.height * 0.3 * animationValue,
        size.width * 0.85, size.height * 0.35 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.7, size.height * 0.3 * animationValue,
        size.width * 0.65, size.height * 0.2 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.6, size.height * 0.05 * animationValue,
        size.width * 0.7, 0,
      )
      ..close();

    paint.color = isDark
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.primary.withValues(alpha: 0.05);
    canvas.drawPath(blob1Path, paint);

    // Secondary blob bottom-left
    final blob2Path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.1 * animationValue, size.height * 0.5,
        size.width * 0.2 * animationValue, size.height * 0.65 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.15 * animationValue, size.height * 0.8,
        0, size.height * 0.85 * animationValue,
      )
      ..close();

    paint.color = isDark
        ? colorScheme.tertiary.withValues(alpha: 0.06)
        : colorScheme.tertiary.withValues(alpha: 0.04);
    canvas.drawPath(blob2Path, paint);

    // Floating circles for decoration
    final circles = [
      Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.92, size.height * 0.25),
      Offset(size.width * 0.05, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.95),
    ];

    final circleRadii = [12.0, 8.0, 16.0, 10.0, 6.0];

    for (int i = 0; i < circles.length; i++) {
      paint.color = isDark
          ? colorScheme.primary.withValues(alpha: 0.04 + (i * 0.01))
          : colorScheme.primary.withValues(alpha: 0.03 + (i * 0.01));
      canvas.drawCircle(circles[i], circleRadii[i] * animationValue, paint);
    }

    // Subtle glow effect for dark mode
    if (isDark) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

      glowPaint.color = colorScheme.primary.withValues(alpha: 0.03);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        100 * animationValue,
        glowPaint,
      );

      glowPaint.color = colorScheme.tertiary.withValues(alpha: 0.03);
      canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.75),
        80 * animationValue,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OnboardingBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.colorScheme != colorScheme;
}