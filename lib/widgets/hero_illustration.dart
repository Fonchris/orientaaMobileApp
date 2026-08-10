import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_theme.dart';

/// A configurable, fully on-brand illustration used in the tutorial-slideshow
/// hero sections. Built from flat solid circles + FontAwesome icons so it is
/// theme-aware (light & dark) and needs no image assets.
class HeroIllustration extends StatelessWidget {
  final FaIconData icon;
  final FaIconData? orbitTopRight;
  final FaIconData? orbitBottomLeft;
  final double size;

  const HeroIllustration({
    super.key,
    required this.icon,
    this.orbitTopRight,
    this.orbitBottomLeft,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.brandInk.withValues(alpha: 0.12);

    return SizedBox(
      width: size,
      height: size * 0.92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed orbit ring (flat stroke, no fill).
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitRingPainter(color: ringColor),
            ),
          ),
          // Main flat yellow circle with dark icon.
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandYellow,
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: AppTheme.brandInk,
                size: size * 0.22,
              ),
            ),
          ),
          // Satellite: top-right (flat color chip)
          if (orbitTopRight != null)
            Positioned(
              right: size * 0.02,
              top: size * 0.06,
              child: _SatelliteBadge(
                icon: orbitTopRight!,
                size: size * 0.2,
                isDark: isDark,
                color: AppTheme.brandYellow,
                iconColor: AppTheme.brandInk,
              ),
            ),
          // Satellite: bottom-left (flat color chip)
          if (orbitBottomLeft != null)
            Positioned(
              left: size * 0.0,
              bottom: size * 0.06,
              child: _SatelliteBadge(
                icon: orbitBottomLeft!,
                size: size * 0.2,
                isDark: isDark,
                color: AppTheme.brandAmber,
                iconColor: Colors.white,
              ),
            ),
          // Floating dots (flat).
          ..._buildDots(size, isDark),
        ],
      ),
    );
  }

  List<Widget> _buildDots(double size, bool isDark) {
    final positions = [
      Offset(-size * 0.38, -size * 0.3),
      Offset(size * 0.4, -size * 0.34),
      Offset(-size * 0.42, size * 0.12),
      Offset(size * 0.38, size * 0.28),
      Offset(-size * 0.12, -size * 0.42),
      Offset(size * 0.12, size * 0.44),
    ];
    final colors = [
      AppTheme.brandYellow,
      AppTheme.brandAmber,
      AppTheme.brandYellow,
      AppTheme.brandAmber,
      AppTheme.brandYellow,
      AppTheme.brandAmber,
    ];
    return List.generate(positions.length, (i) {
      final diameter = 5.0 + (i % 3) * 2.5;
      return Positioned(
        left: size / 2 + positions[i].dx,
        top: size * 0.46 + positions[i].dy,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[i].withValues(
              alpha: isDark ? 0.5 : 0.4,
            ),
          ),
        ),
      );
    });
  }
}

class _SatelliteBadge extends StatelessWidget {
  final FaIconData icon;
  final double size;
  final bool isDark;
  final Color color;
  final Color iconColor;

  const _SatelliteBadge({
    required this.icon,
    required this.size,
    required this.isDark,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: FaIcon(icon, size: size * 0.42, color: iconColor),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final Color color;

  _OrbitRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    final path = Path()
      ..addOval(Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide * 0.36,
      ));

    const dash = 7.0;
    const gap = 9.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final p1 = metric.getTangentForOffset(d)!.position;
        final p2 = metric.getTangentForOffset(d + dash)!.position;
        canvas.drawLine(p1, p2, paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
