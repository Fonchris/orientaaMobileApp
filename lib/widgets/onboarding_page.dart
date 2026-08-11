import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'google_fonts.dart';
import 'hero_illustration.dart';
import 'role_selection_card.dart';
import 'slideshow_scaffold.dart';
import 'student_onboarding/step_ui.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  UserRole? _selectedRole;
  bool _isNavigating = false;

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = _selectedRole == role ? null : role;
    });
  }

  Future<void> _continue() async {
    if (_selectedRole == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final role = _selectedRole == UserRole.student ? 'student' : 'counsellor';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    // Persist the role to Firestore so returning users are recognised on any
    // device and can skip this onboarding flow on their next login.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'role': role}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to persist role to Firestore: $e');
    }

    if (!mounted) return;

    final route = _selectedRole == UserRole.student
        ? '/student-onboarding'
        : '/counsellor-dashboard';

    Navigator.of(context).pushReplacementNamed(
      route,
      arguments: {'role': role},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TutorialSlideshow(
      pageCount: 2,
      onFinish: _continue,
      onBack: Navigator.canPop(context)
          ? () => Navigator.pop(context)
          : null,
      pageBuilder: (page) {
        if (page == 0) {
          return TutorialSlide(
            illustration: const HeroIllustration(
              icon: FontAwesomeIcons.graduationCap,
              orbitTopRight: FontAwesomeIcons.planeUp,
              orbitBottomLeft: FontAwesomeIcons.bookOpen,
            ),
            title: l10n.onboardingWelcomeTitle,
            subtitle: l10n.onboardingWelcomeSubtitle,
            chips: [
              l10n.onboardingChipTailored,
              l10n.onboardingChipScholarships,
              l10n.onboardingChipExpert,
            ],
          );
        }
        return _RoleSlide(
          selectedRole: _selectedRole,
          onSelect: _selectRole,
        );
      },
      actionBuilder: (page, defaultNext) {
        if (page == 0) return null;
        return SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: _selectedRole != null ? l10n.continueAction : l10n.selectRoleToContinue,
            onPressed: _selectedRole != null && !_isNavigating ? _continue : null,
            loading: _isNavigating,
            icon: FontAwesomeIcons.arrowRight,
          ),
        );
      },
    );
  }
}

class _RoleSlide extends StatelessWidget {
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onSelect;

  const _RoleSlide({
    required this.selectedRole,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.brandInk;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize =
            (constraints.maxHeight * 0.2).clamp(90.0, 130.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            children: [
              SizedBox(
                height: illustrationSize * 1.1,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: HeroIllustration(
                    icon: FontAwesomeIcons.users,
                    orbitTopRight: FontAwesomeIcons.userGraduate,
                    orbitBottomLeft: FontAwesomeIcons.comments,
                    size: illustrationSize,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context).howWillYouUse,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).pickRoleSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RoleSelectionCard(
                      role: UserRole.student,
                      isSelected: selectedRole == UserRole.student,
                      onTap: () => onSelect(UserRole.student),
                      animation: const AlwaysStoppedAnimation(1.0),
                      animationDelay: 0,
                    ),
                    RoleSelectionCard(
                      role: UserRole.counsellor,
                      isSelected: selectedRole == UserRole.counsellor,
                      onTap: () => onSelect(UserRole.counsellor),
                      animation: const AlwaysStoppedAnimation(1.0),
                      animationDelay: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
