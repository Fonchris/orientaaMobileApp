import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show themeProvider;
import 'onboarding_background.dart';
import 'onboarding_hero.dart';
import 'role_selection_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _backgroundFade;
  late Animation<double> _heroAnimation;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _cardOneAnimation;
  late Animation<double> _cardTwoAnimation;
  late Animation<double> _buttonAnimation;

  UserRole? _selectedRole;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    _heroAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _cardOneAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _cardTwoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = _selectedRole == role ? null : role;
    });
  }

  Future<void> _onContinue() async {
    if (_selectedRole == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_role',
      _selectedRole == UserRole.student ? 'student' : 'counsellor',
    );

    if (!mounted) return;

    // Animate out before navigating
    await _controller.reverse();

    if (!mounted) return;

    // Navigate to appropriate dashboard
    final route = _selectedRole == UserRole.student
        ? '/student-dashboard'
        : '/counsellor-dashboard';

    Navigator.of(context).pushReplacementNamed(
      route,
      arguments: {'role': _selectedRole == UserRole.student ? 'student' : 'counsellor'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          scheme.surface,
                          scheme.surfaceContainerLow,
                          scheme.surface,
                        ]
                      : [
                          scheme.surface,
                          scheme.surfaceContainerLowest,
                          scheme.surface,
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative background
                  Opacity(
                    opacity: _backgroundFade.value,
                    child: CustomPaint(
                      painter: OnboardingBackgroundPainter(
                        colorScheme: scheme,
                        animationValue: _backgroundFade.value,
                      ),
                      size: screenSize,
                    ),
                  ),

                  // Main content
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        children: [
                          // Theme toggle
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Semantics(
                                label: 'Toggle theme',
                                child: IconButton(
                                  icon: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    themeProvider.toggleTheme();
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Hero illustration
                          OnboardingHero(
                            animation: _heroAnimation,
                            animationDelay: 0,
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          // Title
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.25, 0.5, curve: Curves.easeOutCubic),
                              )),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 48 : 24,
                                ),
                                child: Text(
                                  'How will you use\nOrientaa?',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isTablet ? 40 : 34,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.35, 0.55, curve: Curves.easeOutCubic),
                              )),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 48 : 24,
                                ),
                                child: Text(
                                  'Choose your role to get started',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w400,
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Role selection cards
                          RoleSelectionCard(
                            role: UserRole.student,
                            isSelected: _selectedRole == UserRole.student,
                            onTap: () => _selectRole(UserRole.student),
                            animation: _cardOneAnimation,
                            animationDelay: 0,
                          ),
                          RoleSelectionCard(
                            role: UserRole.counsellor,
                            isSelected: _selectedRole == UserRole.counsellor,
                            onTap: () => _selectRole(UserRole.counsellor),
                            animation: _cardTwoAnimation,
                            animationDelay: 1,
                          ),

                          const SizedBox(height: 32),

                          // Continue button
                          FadeTransition(
                            opacity: _buttonAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
                              )),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 48 : 20,
                                ),
                                child: Semantics(
                                  label: _selectedRole == null
                                      ? 'Select a role to continue'
                                      : 'Continue as ${_selectedRole == UserRole.student ? 'Student' : 'Counsellor'}',
                                  button: true,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: _selectedRole != null
                                            ? LinearGradient(
                                                colors: [
                                                  scheme.primary,
                                                  scheme.primary.withValues(alpha: 0.8),
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                                  scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                                ],
                                              ),
                                        boxShadow: _selectedRole != null
                                            ? [
                                                BoxShadow(
                                                  color: scheme.primary.withValues(alpha: isDark ? 0.3 : 0.25),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          onTap: _selectedRole != null && !_isNavigating
                                              ? _onContinue
                                              : null,
                                          borderRadius: BorderRadius.circular(18),
                                          splashColor: scheme.onPrimary.withValues(alpha: 0.1),
                                          highlightColor: Colors.transparent,
                                          child: Center(
                                            child: _isNavigating
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: scheme.onPrimary,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Continue',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: _selectedRole != null
                                                              ? scheme.onPrimary
                                                              : scheme.onSurface.withValues(alpha: 0.4),
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                      if (_selectedRole != null) ...[
                                                        const SizedBox(width: 8),
                                                        Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: scheme.onPrimary,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}