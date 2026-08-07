import 'package:flutter/material.dart';

/// Soft radial glow blob used to decorate screen backgrounds.
class GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const GlowBlob({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
