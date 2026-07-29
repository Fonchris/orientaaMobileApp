import 'package:flutter/material.dart';

class OnboardingHero extends StatelessWidget {
  final Animation<double> animation;

  const OnboardingHero({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final brandBlue = const Color(0xFF011F7B);
    final brandGold = const Color(0xFFFFBA09);
    final brandYellow = const Color(0xFFFFDB00);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        )),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.27,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Large decorative blue radial glow
              Positioned(
                top: 5,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brandBlue.withValues(alpha: isDark ? 0.15 : 0.06),
                        brandBlue.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Golden accent glow offset right
              Positioned(
                right: 10,
                top: 30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brandGold.withValues(alpha: isDark ? 0.08 : 0.04),
                        brandGold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main illustration
              SizedBox(
                width: 230,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back tilted book (golden accent)
                    Positioned(
                      right: 35,
                      top: 2,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      brandGold.withValues(alpha: 0.3),
                                      brandGold.withValues(alpha: 0.1),
                                    ]
                                  : [
                                      brandGold.withValues(alpha: 0.2),
                                      brandGold.withValues(alpha: 0.05),
                                    ],
                            ),
                            border: Border.all(
                              color: brandGold.withValues(alpha: isDark ? 0.2 : 0.1),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.book_rounded,
                              size: 28,
                              color: brandGold.withValues(alpha: isDark ? 0.5 : 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Central graduation cap container (brand blue)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    brandBlue.withValues(alpha: 0.25),
                                    brandBlue.withValues(alpha: 0.08),
                                  ]
                                : [
                                    brandBlue.withValues(alpha: 0.08),
                                    brandBlue.withValues(alpha: 0.02),
                                  ],
                          ),
                          border: Border.all(
                            color: brandBlue.withValues(alpha: isDark ? 0.2 : 0.08),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 52,
                          color: isDark
                              ? brandBlue.withValues(alpha: 0.8)
                              : brandBlue,
                        ),
                      ),
                    ),

                    // Books stack left (blue tones)
                    Positioned(
                      left: 0,
                      bottom: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        brandBlue.withValues(alpha: 0.5),
                                        brandBlue.withValues(alpha: 0.2),
                                      ]
                                    : [
                                        brandBlue.withValues(alpha: 0.15),
                                        brandBlue.withValues(alpha: 0.05),
                                      ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        brandGold.withValues(alpha: 0.4),
                                        brandGold.withValues(alpha: 0.2),
                                      ]
                                    : [
                                        brandGold.withValues(alpha: 0.15),
                                        brandGold.withValues(alpha: 0.05),
                                      ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 46,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        brandBlue.withValues(alpha: 0.4),
                                        brandBlue.withValues(alpha: 0.15),
                                      ]
                                    : [
                                        brandBlue.withValues(alpha: 0.12),
                                        brandBlue.withValues(alpha: 0.04),
                                      ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Laptop device right
                    Positioned(
                      right: 0,
                      bottom: 8,
                      child: Container(
                        width: 70,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF323232).withValues(alpha: 0.8),
                                    const Color(0xFF323232).withValues(alpha: 0.4),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.5),
                                  ],
                          ),
                          border: Border.all(
                            color: brandBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brandBlue.withValues(alpha: isDark ? 0.1 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.laptop_mac_rounded,
                            size: 24,
                            color: brandBlue.withValues(alpha: isDark ? 0.6 : 0.5),
                          ),
                        ),
                      ),
                    ),

                    // Floating decorative dots with brand colors
                    ...List.generate(7, (i) {
                      final positions = [
                        const Offset(-60, -30),
                        const Offset(70, -35),
                        const Offset(-50, 55),
                        const Offset(65, 45),
                        const Offset(0, -65),
                        const Offset(-25, 70),
                        const Offset(30, -40),
                      ];
                      final colors = [
                        brandBlue,
                        brandGold,
                        brandBlue,
                        brandGold,
                        brandYellow,
                        brandBlue,
                        brandGold,
                      ];
                      return Positioned(
                        left: 115 + positions[i].dx,
                        top: 100 + positions[i].dy,
                        child: Container(
                          width: 4 + (i * 1.8),
                          height: 4 + (i * 1.8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[i].withValues(
                              alpha: isDark ? 0.25 + (i * 0.04) : 0.15 + (i * 0.04),
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