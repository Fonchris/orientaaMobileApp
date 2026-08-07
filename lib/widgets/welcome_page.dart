import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return TutorialSlideshow(
      pageCount: 3,
      onFinish: () => _goToSignup(context),
      pageBuilder: (page) {
        switch (page) {
          case 0:
            return const TutorialSlide(
              illustration: HeroIllustration(
                icon: FontAwesomeIcons.graduationCap,
                orbitTopRight: FontAwesomeIcons.planeUp,
                orbitBottomLeft: FontAwesomeIcons.mapPin,
              ),
              title: 'Welcome to Orientaa',
              subtitle: 'Your career. Your future.',
              chips: ['Explore', 'Compare', 'Get matched'],
            );
          case 1:
            return const TutorialSlide(
              illustration: HeroIllustration(
                icon: FontAwesomeIcons.compass,
                orbitTopRight: FontAwesomeIcons.heart,
                orbitBottomLeft: FontAwesomeIcons.magnifyingGlass,
              ),
              title: 'Find your path',
              subtitle:
                  'Discover universities, courses and scholarships across Africa and the world — tailored to you.',
            );
          default:
            return const TutorialSlide(
              illustration: HeroIllustration(
                icon: FontAwesomeIcons.rocket,
                orbitTopRight: FontAwesomeIcons.chartSimple,
                orbitBottomLeft: FontAwesomeIcons.lightbulb,
              ),
              title: 'Ready to begin?',
              subtitle:
                  'Create your account in minutes and start exploring opportunities built around your goals.',
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
                label: 'Get Started',
                onPressed: () => _goToSignup(context),
                icon: FontAwesomeIcons.paperPlane,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'I already have an account — Log in',
                onPressed: () => _goToLogin(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
