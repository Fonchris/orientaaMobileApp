import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'hero_illustration.dart';
import 'slideshow_scaffold.dart';
import 'student_onboarding/step_ui.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static Future<void> _markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  Future<void> _goToSignup(BuildContext context) async {
    await _markWelcomeSeen();
    if (!context.mounted) return;
    // Push (not replace) so the back button on signup returns here.
    Navigator.of(context).pushNamed('/signup');
  }

  Future<void> _goToLogin(BuildContext context) async {
    await _markWelcomeSeen();
    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TutorialSlideshow(
      pageCount: 3,
      onFinish: () => _goToSignup(context),
      pageBuilder: (page) {
        switch (page) {
          case 0:
            return TutorialSlide(
              illustration: const HeroIllustration(
                icon: FontAwesomeIcons.graduationCap,
                orbitTopRight: FontAwesomeIcons.planeUp,
                orbitBottomLeft: FontAwesomeIcons.mapPin,
              ),
              title: l10n.welcomeTitle,
              subtitle: l10n.welcomeSubtitle,
              chips: [
                l10n.welcomeChipExplore,
                l10n.welcomeChipCompare,
                l10n.welcomeChipGetMatched,
              ],
            );
          case 1:
            return TutorialSlide(
              illustration: const HeroIllustration(
                icon: FontAwesomeIcons.compass,
                orbitTopRight: FontAwesomeIcons.heart,
                orbitBottomLeft: FontAwesomeIcons.magnifyingGlass,
              ),
              title: l10n.welcomeFindPathTitle,
              subtitle: l10n.welcomeFindPathSubtitle,
            );
          default:
            return TutorialSlide(
              illustration: const HeroIllustration(
                icon: FontAwesomeIcons.rocket,
                orbitTopRight: FontAwesomeIcons.chartSimple,
                orbitBottomLeft: FontAwesomeIcons.lightbulb,
              ),
              title: l10n.welcomeReadyTitle,
              subtitle: l10n.welcomeReadySubtitle,
            );
        }
      },
      actionBuilder: (page, defaultNext) {
        if (page < 2) return null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.getStarted,
                onPressed: () => _goToSignup(context),
                icon: FontAwesomeIcons.paperPlane,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: l10n.alreadyHaveAccountLogin,
                onPressed: () => _goToLogin(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
