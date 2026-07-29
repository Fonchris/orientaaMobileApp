import 'package:flutter/material.dart';

class OnboardingHero extends StatelessWidget {
  final Animation<double> animation;
  final int animationDelay;

  const OnboardingHero({
    super.key,
    required this.animation,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(
            0.1 + (animationDelay * 0.1),
            0.4 + (animationDelay * 0.1),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Decorative background circle
              Positioned(
                top: 20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                        scheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main illustration composed of Flutter widgets
              SizedBox(
                width: 200,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back book stack
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                scheme.tertiary.withValues(alpha: 0.6),
                                scheme.tertiary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Graduation cap (central element)
                    Positioned(
                      top: 10,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 44,
                          color: scheme.primary,
                        ),
                      ),
                    ),

                    // Books stack left
                    Positioned(
                      left: 15,
                      bottom: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: scheme.secondary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 55,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: scheme.secondary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 48,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: scheme.secondary.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Laptop/device right
                    Positioned(
                      right: 10,
                      bottom: 15,
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: scheme.surfaceContainerHighest,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.laptop_mac_rounded,
                            size: 24,
                            color: scheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),

                    // Floating sparkle dots
                    ...List.generate(5, (i) {
                      final positions = [
                        const Offset(-50, -30),
                        const Offset(60, -40),
                        const Offset(-40, 40),
                        const Offset(55, 30),
                        const Offset(0, -55),
                      ];
                      return Positioned(
                        left: 100 + positions[i].dx,
                        top: 110 + positions[i].dy,
                        child: Container(
                          width: 6 + (i * 2).toDouble(),
                          height: 6 + (i * 2).toDouble(),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(
                              alpha: 0.3 + (i * 0.1),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}