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

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

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
        curve: const Interval(0.05, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _cardOneAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _cardTwoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
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

    await _controller.reverse();

    if (!mounted) return;

    final route = _selectedRole == UserRole.student
        ? '/student-onboarding'
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                          const Color(0xFF1A1A2E),
                          const Color(0xFF323232),
                          const Color(0xFF1A1A2E),
                        ]
                      : [
                          const Color(0xFFF8F9FF),
                          Colors.white,
                          const Color(0xFFF8F9FF),
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
                        minHeight: screenSize.height - MediaQuery.of(context).padding.top - bottomPadding,
                      ),
                      child: Column(
                        children: [
                          // Theme toggle
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 4),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Semantics(
                                label: 'Toggle theme',
                                child: IconButton(
                                  icon: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : _brandBlue.withValues(alpha: 0.4),
                                  ),
                                  onPressed: () => themeProvider.toggleTheme(),
                                ),
                              ),
                            ),
                          ),

                          // Hero illustration
                          OnboardingHero(
                            animation: _heroAnimation,
                          ),

                          // Title
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.2, 0.45, curve: Curves.easeOutCubic),
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
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.3, 0.5, curve: Curves.easeOutCubic),
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
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 28 : 20),

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

                          SizedBox(height: isTablet ? 28 : 24),

                          // Continue button
                          FadeTransition(
                            opacity: _buttonAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
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
                                      duration: const Duration(milliseconds: 350),
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: _selectedRole != null
                                            ? LinearGradient(
                                                colors: [
                                                  _brandBlue,
                                                  _brandBlue.withValues(alpha: 0.85),
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: isDark
                                                    ? [
                                                        Colors.white.withValues(alpha: 0.06),
                                                        Colors.white.withValues(alpha: 0.03),
                                                      ]
                                                    : [
                                                        _brandBlue.withValues(alpha: 0.04),
                                                        _brandBlue.withValues(alpha: 0.02),
                                                      ],
                                              ),
                                        boxShadow: _selectedRole != null
                                            ? [
                                                BoxShadow(
                                                  color: _brandBlue.withValues(alpha: isDark ? 0.4 : 0.25),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 8),
                                                ),
                                                BoxShadow(
                                                  color: _brandGold.withValues(alpha: isDark ? 0.1 : 0.05),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(28),
                                        child: InkWell(
                                          onTap: _selectedRole != null && !_isNavigating
                                              ? _onContinue
                                              : null,
                                          borderRadius: BorderRadius.circular(28),
                                          splashColor: Colors.white.withValues(alpha: 0.1),
                                          highlightColor: Colors.transparent,
                                          child: Center(
                                            child: _isNavigating
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
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
                                                              ? Colors.white
                                                              : isDark
                                                                  ? Colors.white.withValues(alpha: 0.2)
                                                                  : _brandBlue.withValues(alpha: 0.2),
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      if (_selectedRole != null) ...[
                                                        const SizedBox(width: 8),
                                                        Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: Colors.white,
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

                          SizedBox(height: bottomPadding + 16),
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