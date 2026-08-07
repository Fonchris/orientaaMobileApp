import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'step_progress_bar.dart';
import 'step1_identity_page.dart';
import 'step2_location_page.dart';
import 'step3_financial_page.dart';
import 'step4_self_assessment_page.dart';
import 'step5_big_five_page.dart';
import 'step5_optional_page.dart';

class StudentOnboardingPage extends StatefulWidget {
  const StudentOnboardingPage({super.key});

  @override
  State<StudentOnboardingPage> createState() => _StudentOnboardingPageState();
}

class _StudentOnboardingPageState extends State<StudentOnboardingPage> {
  final _model = StudentOnboardingModel();
  int _currentStep = 0;
  bool _isSubmitting = false;
  late final VoidCallback _modelListener;

  static const _totalSteps = 6;

  @override
  void initState() {
    super.initState();
    _modelListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _model.addListener(_modelListener);
  }

  @override
  void dispose() {
    _model.removeListener(_modelListener);
    _model.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to complete onboarding.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(_model.toFirestoreMap(), SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/student-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save onboarding data: $e')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
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
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -40,
                child: _GlowBlob(color: AppTheme.brandGold.withValues(alpha: isDark ? 0.12 : 0.1), size: 180),
              ),
              Positioned(
                bottom: 120,
                left: -60,
                child: _GlowBlob(color: AppTheme.brandBlue.withValues(alpha: isDark ? 0.14 : 0.08), size: 220),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white.withValues(alpha: 0.75) : AppTheme.brandBlue.withValues(alpha: 0.75),
                          ),
                          onPressed: () {
                            if (_currentStep > 0) {
                              _previousStep();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            _stepTitle(_currentStep),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.brandGold.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            '${_currentStep + 1}/$_totalSteps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StepProgressBar(totalSteps: _totalSteps, currentStep: _currentStep),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Saving your information...', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1IdentityPage(model: _model, onNext: _nextStep);
      case 1:
        return Step2LocationPage(model: _model, onNext: _nextStep, onBack: _previousStep);
      case 2:
        return Step3FinancialPage(model: _model, onNext: _nextStep, onBack: _previousStep);
      case 3:
        return Step4SelfAssessmentPage(model: _model, onNext: _nextStep, onBack: _previousStep);
      case 4:
        return Step5BigFivePage(model: _model, onNext: _nextStep, onBack: _previousStep);
      case 5:
        return Step5OptionalPage(model: _model, onNext: _submit, onBack: _previousStep, onSkip: _submit);
      default:
        return const SizedBox.shrink();
    }
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0: return 'Identity & Academic';
      case 1: return 'Location & Logistics';
      case 2: return 'Financial';
      case 3: return 'Self-Assessment';
      case 4: return 'Personality';
      case 5: return 'Optional Extras';
      default: return '';
    }
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}