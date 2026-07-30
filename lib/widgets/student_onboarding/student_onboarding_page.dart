import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_onboarding_model.dart';
import 'step_progress_bar.dart';
import 'step1_identity_page.dart';
import 'step2_location_page.dart';
import 'step3_financial_page.dart';
import 'step4_self_assessment_page.dart';
import 'step5_optional_page.dart';

class StudentOnboardingPage extends StatefulWidget {
  const StudentOnboardingPage({super.key});

  @override
  State<StudentOnboardingPage> createState() => _StudentOnboardingPageState();
}

class _StudentOnboardingPageState extends State<StudentOnboardingPage> {
  final _model = StudentOnboardingModel();
  late final PageController _pageController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  static const _totalSteps = 5;
  static const _brandBlue = Color(0xFF011F7B);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back arrow and step title
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : _brandBlue.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _previousStep();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      _stepTitle(_currentStep),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Step progress bar
            StepProgressBar(
              totalSteps: _totalSteps,
              currentStep: _currentStep,
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  Step1IdentityPage(
                    model: _model,
                    onNext: _nextStep,
                  ),
                  Step2LocationPage(
                    model: _model,
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  Step3FinancialPage(
                    model: _model,
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  Step4SelfAssessmentPage(
                    model: _model,
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  Step5OptionalPage(
                    model: _model,
                    onNext: _submit,
                    onBack: _previousStep,
                    onSkip: _submit,
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isSubmitting)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Saving your information...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Identity & Academic';
      case 1:
        return 'Location & Logistics';
      case 2:
        return 'Financial';
      case 3:
        return 'Self-Assessment';
      case 4:
        return 'Optional Extras';
      default:
        return '';
    }
  }
}