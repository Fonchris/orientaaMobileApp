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
    final paint = Paint()..style = PaintingStyle.fill;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Brand colors
    final brandBlue = const Color(0xFF011F7B);
    final brandGold = const Color(0xFFFFBA09);
    final brandYellow = const Color(0xFFFFDB00);

    // Large soft blob top-right (brand blue)
    final blob1Path = Path()
      ..moveTo(size.width * 0.65, 0)
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.04 * animationValue,
        size.width, size.height * 0.12 * animationValue,
      )
      ..quadraticBezierTo(
        size.width, size.height * 0.28 * animationValue,
        size.width * 0.82, size.height * 0.32 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.68, size.height * 0.28 * animationValue,
        size.width * 0.6, size.height * 0.18 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.55, size.height * 0.04 * animationValue,
        size.width * 0.65, 0,
      )
      ..close();

    paint.color = isDark
        ? brandBlue.withValues(alpha: 0.15)
        : brandBlue.withValues(alpha: 0.04);
    canvas.drawPath(blob1Path, paint);

    // Golden accent blob bottom-left
    final blob2Path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.08 * animationValue, size.height * 0.45,
        size.width * 0.18 * animationValue, size.height * 0.6 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.12 * animationValue, size.height * 0.78,
        0, size.height * 0.82 * animationValue,
      )
      ..close();

    paint.color = isDark
        ? brandGold.withValues(alpha: 0.06)
        : brandGold.withValues(alpha: 0.03);
    canvas.drawPath(blob2Path, paint);

    // Small golden blob top-left
    final blob3Path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width * 0.05 * animationValue, size.height * 0.02,
        size.width * 0.1 * animationValue, size.height * 0.08 * animationValue,
      )
      ..quadraticBezierTo(
        size.width * 0.03 * animationValue, size.height * 0.12,
        0, size.height * 0.06 * animationValue,
      )
      ..close();

    paint.color = isDark
        ? brandYellow.withValues(alpha: 0.04)
        : brandYellow.withValues(alpha: 0.02);
    canvas.drawPath(blob3Path, paint);

    // Floating decorative circles
    final circles = [
      Offset(size.width * 0.88, size.height * 0.06),
      Offset(size.width * 0.94, size.height * 0.22),
      Offset(size.width * 0.03, size.height * 0.65),
      Offset(size.width * 0.12, size.height * 0.88),
      Offset(size.width * 0.5, size.height * 0.92),
      Offset(size.width * 0.78, size.height * 0.9),
    ];

    final circleColors = [
      brandBlue,
      brandGold,
      brandBlue,
      brandGold,
      brandYellow,
      brandBlue,
    ];

    final circleRadii = [10.0, 6.0, 14.0, 8.0, 5.0, 7.0];

    for (int i = 0; i < circles.length; i++) {
      paint.color = isDark
          ? circleColors[i].withValues(alpha: 0.05 + (i * 0.005))
          : circleColors[i].withValues(alpha: 0.03 + (i * 0.005));
      canvas.drawCircle(circles[i], circleRadii[i] * animationValue, paint);
    }

    // Glow effects for dark mode
    if (isDark) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

      glowPaint.color = brandBlue.withValues(alpha: 0.05);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.15),
        120 * animationValue,
        glowPaint,
      );

      glowPaint.color = brandGold.withValues(alpha: 0.03);
      canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.7),
        90 * animationValue,
        glowPaint,
      );

      // Subtle blue glow at bottom
      glowPaint
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100)
        ..color = brandBlue.withValues(alpha: 0.04);
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.9),
        140 * animationValue,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OnboardingBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.colorScheme != colorScheme;
}