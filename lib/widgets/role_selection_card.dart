import 'package:flutter/material.dart';

import 'google_fonts.dart';

enum UserRole { student, counsellor }

class RoleSelectionCard extends StatefulWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> animation;
  final int animationDelay;

  const RoleSelectionCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.animation,
    required this.animationDelay,
  });

  @override
  State<RoleSelectionCard> createState() => _RoleSelectionCardState();
}

class _RoleSelectionCardState extends State<RoleSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final isStudent = widget.role == UserRole.student;
    final iconData = isStudent ? Icons.school_rounded : Icons.support_agent_rounded;
    final title = isStudent ? 'Student' : 'Counsellor';
    final description = isStudent
        ? 'Explore universities, courses, scholarships, and manage your academic journey.'
        : 'Guide students, manage counselling sessions, and support their educational success.';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: FadeTransition(
        opacity: widget.animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: widget.animation,
            curve: Interval(
              0.2 + (widget.animationDelay * 0.15),
              0.6 + (widget.animationDelay * 0.15),
              curve: Curves.easeOutCubic,
            ),
          )),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: GestureDetector(
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) {
                _scaleController.reverse();
                widget.onTap();
              },
              onTapCancel: () => _scaleController.reverse(),
              child: Semantics(
                label: 'Select $title role',
                button: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: widget.isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    _brandBlue.withValues(alpha: 0.25),
                                    _brandBlue.withValues(alpha: 0.08),
                                    const Color(0xFF323232).withValues(alpha: 0.5),
                                  ]
                                : [
                                    _brandBlue.withValues(alpha: 0.06),
                                    _brandBlue.withValues(alpha: 0.02),
                                    Colors.white,
                                  ],
                          )
                        : null,
                    color: widget.isSelected
                        ? null
                        : isDark
                            ? const Color(0xFF323232).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.85),
                    border: Border.all(
                      color: widget.isSelected
                          ? _brandBlue
                          : isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : _brandBlue.withValues(alpha: 0.08),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: _brandBlue.withValues(alpha: isDark ? 0.3 : 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: _brandGold.withValues(alpha: isDark ? 0.08 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Icon container with brand colors
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: widget.isSelected
                              ? LinearGradient(
                                  colors: [
                                    _brandBlue,
                                    _brandBlue.withValues(alpha: 0.8),
                                  ],
                                )
                              : LinearGradient(
                                  colors: isDark
                                      ? [
                                          _brandBlue.withValues(alpha: 0.3),
                                          _brandBlue.withValues(alpha: 0.1),
                                        ]
                                      : [
                                          _brandBlue.withValues(alpha: 0.08),
                                          _brandBlue.withValues(alpha: 0.03),
                                        ],
                                ),
                          boxShadow: widget.isSelected
                              ? [
                                  BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedScale(
                          scale: widget.isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            iconData,
                            color: widget.isSelected
                                ? Colors.white
                                : isDark
                                    ? _brandBlue.withValues(alpha: 0.7)
                                    : _brandBlue,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A2E),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                // Trailing chevron
                                Icon(
                                  widget.isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.chevron_right_rounded,
                                  color: widget.isSelected
                                      ? _brandGold
                                      : isDark
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : _brandBlue.withValues(alpha: 0.2),
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : const Color(0xFF1A1A2E).withValues(alpha: 0.55),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}