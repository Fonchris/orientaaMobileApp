import 'package:flutter/material.dart';

import '../../app_theme.dart';

/// A pulsing placeholder block. Used by the skeleton cards so loading states
/// read as content-in-progress rather than a spinner over blank space.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonPulse({super.key, required this.child, this.duration = const Duration(milliseconds: 900)});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// A grey rounded placeholder rectangle.
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.brandInk.withValues(alpha: 0.08),
      ),
    );
  }
}

/// A full placeholder card matching the shape of a recommendation card.
/// Used while the recommendations fetch on the dashboard.
class SkeletonRecommendationCard extends StatelessWidget {
  const SkeletonRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonPulse(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppTheme.brandSurface : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.brandLightOutline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                SkeletonBlock(width: 44, height: 44, radius: 14),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(height: 13, radius: 6),
                      SizedBox(height: 8),
                      SkeletonBlock(height: 11, radius: 6, width: 110),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBlock(height: 12, radius: 6),
            SizedBox(height: 8),
            SkeletonBlock(height: 12, radius: 6, width: 160),
            SizedBox(height: 14),
            SkeletonBlock(height: 26, radius: 13),
          ],
        ),
      ),
    );
  }
}

/// A full-width placeholder matching the search result card.
class SkeletonSearchCard extends StatelessWidget {
  const SkeletonSearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonPulse(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppTheme.brandLightOutline,
          ),
        ),
        child: const Row(
          children: [
            SkeletonBlock(width: 46, height: 46, radius: 13),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(height: 14, radius: 7),
                  SizedBox(height: 8),
                  SkeletonBlock(height: 11, radius: 6, width: 140),
                  SizedBox(height: 10),
                  SkeletonBlock(height: 20, radius: 10, width: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
