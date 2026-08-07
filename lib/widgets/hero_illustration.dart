import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_theme.dart';

/// A configurable, fully on-brand illustration used in the tutorial-slideshow
/// hero sections. Built from gradient circles + FontAwesome icons so it is
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

    return SizedBox(
      width: size,
      height: size * 0.92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main blue glow
          Container(
            width: size * 1.1,
            height: size * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.brandBlue.withValues(alpha: isDark ? 0.32 : 0.12),
                  AppTheme.brandBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Gold accent glow
          Positioned(
            right: 0,
            top: size * 0.1,
            child: Container(
              width: size * 0.55,
              height: size * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brandGold.withValues(alpha: isDark ? 0.2 : 0.12),
                    AppTheme.brandGold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Dashed orbit ring
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitRingPainter(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppTheme.brandBlue.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Main gradient circle
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppTheme.brandGold.withValues(alpha: 0.95),
                        AppTheme.brandBlue,
                      ]
                    : [
                        AppTheme.brandBlue,
                        const Color(0xFF1F4ED8),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandBlue.withValues(alpha: isDark ? 0.45 : 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppTheme.brandGold.withValues(alpha: isDark ? 0.12 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: Colors.white,
                size: size * 0.22,
              ),
            ),
          ),
          // Satellite: top-right
          if (orbitTopRight != null)
            Positioned(
              right: size * 0.02,
              top: size * 0.06,
              child: _SatelliteBadge(
                icon: orbitTopRight!,
                size: size * 0.2,
                isDark: isDark,
                gold: false,
              ),
            ),
          // Satellite: bottom-left
          if (orbitBottomLeft != null)
            Positioned(
              left: size * 0.0,
              bottom: size * 0.06,
              child: _SatelliteBadge(
                icon: orbitBottomLeft!,
                size: size * 0.2,
                isDark: isDark,
                gold: true,
              ),
            ),
          // Floating dots
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
    return List.generate(positions.length, (i) {
      final colors = [
        AppTheme.brandBlue,
        AppTheme.brandGold,
        AppTheme.brandBlue,
        AppTheme.brandGold,
        AppTheme.brandBlue,
        AppTheme.brandGold,
      ];
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
              alpha: isDark ? 0.35 + i * 0.04 : 0.18 + i * 0.04,
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
  final bool gold;

  const _SatelliteBadge({
    required this.icon,
    required this.size,
    required this.isDark,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? AppTheme.brandGold : AppTheme.brandBlue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accent.withValues(alpha: 0.35),
                  accent.withValues(alpha: 0.12),
                ]
              : [
                  Colors.white,
                  accent.withValues(alpha: 0.12),
                ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: FaIcon(
          icon,
          size: size * 0.42,
          color: gold
              ? AppTheme.brandGold
              : isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppTheme.brandBlue,
        ),
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
