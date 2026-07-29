import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GestureDetector(
              onTapDown: (_) {
                _scaleController.forward();
              },
              onTapUp: (_) {
                _scaleController.reverse();
                widget.onTap();
              },
              onTapCancel: () {
                _scaleController.reverse();
              },
              child: Semantics(
                label: 'Select $title role',
                button: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: widget.isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    scheme.primary.withValues(alpha: 0.2),
                                    scheme.primary.withValues(alpha: 0.08),
                                    scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  ]
                                : [
                                    scheme.primary.withValues(alpha: 0.12),
                                    scheme.primary.withValues(alpha: 0.04),
                                    scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                  ],
                          )
                        : null,
                    color: widget.isSelected
                        ? null
                        : isDark
                            ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
                            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border.all(
                      color: widget.isSelected
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: 0.3),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon / Illustration container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: widget.isSelected
                              ? LinearGradient(
                                  colors: [
                                    scheme.primary,
                                    scheme.primary.withValues(alpha: 0.7),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    scheme.primaryContainer,
                                    scheme.primaryContainer.withValues(alpha: 0.6),
                                  ],
                                ),
                          boxShadow: widget.isSelected
                              ? [
                                  BoxShadow(
                                    color: scheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedScale(
                          scale: widget.isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            iconData,
                            color: widget.isSelected
                                ? scheme.onPrimary
                                : scheme.onPrimaryContainer,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                      color: scheme.onSurface,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (widget.isSelected)
                                  AnimatedScale(
                                    scale: widget.isSelected ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: scheme.primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: scheme.primary.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: scheme.onPrimary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: scheme.onSurfaceVariant,
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