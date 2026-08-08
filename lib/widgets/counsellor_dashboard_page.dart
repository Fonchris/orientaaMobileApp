import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'google_fonts.dart';

/// Placeholder landing page for counsellors.
///
/// The counsellor workspace is not built yet, but the route must exist so
/// role selection doesn't crash after onboarding.
class CounsellorDashboardPage extends StatefulWidget {
  const CounsellorDashboardPage({super.key});

  @override
  State<CounsellorDashboardPage> createState() =>
      _CounsellorDashboardPageState();
}

class _CounsellorDashboardPageState extends State<CounsellorDashboardPage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.brandInk;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1115),
                    AppTheme.brandNavySurface,
                    const Color(0xFF151A26),
                  ]
                : [
                    const Color(0xFFF7F9FC),
                    Colors.white,
                    const Color(0xFFF3F6FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Sign out',
                    onPressed: _isSigningOut ? null : _signOut,
                    icon: _isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            size: 16,
                            color: subtitleColor,
                          ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.brandGold, AppTheme.brandBlue],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.userTie,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Counsellor workspace',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This area is coming soon. We are building tools to help you guide students through their study-abroad journey.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppTheme.brandGold.withValues(alpha: 0.15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.clock,
                                size: 12,
                                color: AppTheme.brandGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Coming soon',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.brandGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
