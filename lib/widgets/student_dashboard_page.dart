import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'google_fonts.dart';

/// Landing page shown after onboarding completes.
///
/// Reads the student's profile from Firestore (`users/{uid}`) and renders a
/// summary. This is the "payoff" of the Firebase setup: data saved during the
/// 6-step onboarding is now displayed straight from Firestore.
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profileFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = FirebaseAuth.instance.currentUser;
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid ?? 'missing')
        .get();
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

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
          child: Column(
            children: [
              _buildHeader(context, user),
              Expanded(
                child: user == null
                    ? _buildSignedOut(context)
                    : _buildProfile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.brandGold, AppTheme.brandBlue],
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.graduationCap,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'My Student Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
          IconButton(
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.brandBlue,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.userLock,
              size: 48,
              color: isDark ? AppTheme.brandGold : AppTheme.brandBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'You are signed out',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to view your saved profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                ),
                child: Text(
                  'Sign in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.brandBlue),
          );
        }

        if (snapshot.hasError) {
          return _buildError(context, snapshot.error.toString());
        }

        final data = snapshot.data?.data();
        final onboarding =
            (data?['onboardingData'] as Map<String, dynamic>?) ?? const {};

        if (data == null ||
            data['onboardingComplete'] != true ||
            onboarding.isEmpty) {
          return _buildIncompleteProfile(context);
        }

        return _buildProfileContent(context, onboarding);
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    // Friendly hint for the most common cause: Firestore security rules.
    final isPermission = error.contains('permission-denied');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48,
              color: AppTheme.brandGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load your profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermission
                  ? 'Firestore is denying access. Update your Firestore security rules to allow signed-in users to read their own profile.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(_loadProfile),
              icon: const FaIcon(FontAwesomeIcons.rotate, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompleteProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.listCheck,
              size: 48,
              color: isDark ? AppTheme.brandGold : AppTheme.brandBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Your profile is not set up yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the onboarding to unlock personalized university matches, scholarships and more.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed('/student-onboarding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                ),
                child: Text(
                  'Complete my profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> o) {
    final user = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      onRefresh: () async => setState(_loadProfile),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildIdentityCard(context, user, o),
          const SizedBox(height: 14),
          _buildSection(
            context,
            title: 'Academic',
            icon: FontAwesomeIcons.bookOpen,
            children: [
              _row(context, 'Education level', o['educationLevel']),
              _row(context, 'Desired degree', o['desiredDegreeLevel']),
              _row(
                context,
                'Fields of interest',
                _listToText(o['fieldsOfInterest']),
              ),
              _row(context, 'Planned start', o['startLabel']),
            ],
          ),
          const SizedBox(height: 14),
          _buildSection(
            context,
            title: 'Location & Logistics',
            icon: FontAwesomeIcons.planeDeparture,
            children: [
              _row(context, 'Home', _homeText(o)),
              _row(
                context,
                'Study destinations',
                _listToText(o['preferredDestinations']),
              ),
              _row(context, 'Language of instruction', o['preferredLanguage']),
            ],
          ),
          const SizedBox(height: 14),
          _buildSection(
            context,
            title: 'Financial',
            icon: FontAwesomeIcons.wallet,
            children: [
              _row(context, 'Annual budget', _budgetText(o)),
              _row(context, 'Household income', o['annualIncomeLabel']),
              _row(
                context,
                'Scholarships',
                o['seekingScholarship'] == true
                    ? 'Seeking scholarship info'
                    : 'Not currently seeking',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSection(
            context,
            title: 'Assessment',
            icon: FontAwesomeIcons.userCheck,
            children: [
              _row(context, 'Career goal', o['careerGoals']),
              _row(context, 'Strengths', _listToText(o['strengths'], max: 4)),
              _row(context, 'Interests', _listToText(o['interests'], max: 4)),
              _row(
                context,
                'Personality questions',
                (o['personalityResponses'] as Map?)?.isNotEmpty == true
                    ? '${(o['personalityResponses'] as Map).length} answered'
                    : null,
              ),
              _row(context, 'GPA', o['gpa']),
              _row(context, 'Test scores', _testScoresText(o['testScores'])),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed('/student-onboarding'),
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                  label: Text(
                    'Edit profile',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Building blocks ──────────────────────────────────────────────────────

  Widget _buildIdentityCard(
    BuildContext context,
    User? user,
    Map<String, dynamic> o,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _initials(user?.email ?? 'Orientaa Student');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF243B7A),
                  const Color(0xFF10131D),
                ]
              : [
                  Colors.white,
                  const Color(0xFFEAF1FF),
                  const Color(0xFFFDF8E8),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.brandBlue.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brandGold, AppTheme.brandBlue],
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, explorer!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.brandInk.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.solidCircleCheck,
                size: 13,
                color: AppTheme.brandGold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Profile saved to Firestore — ${_homeText(o) ?? 'ready to match'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.brandBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required FaIconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.brandBlue.withValues(alpha: 0.08),
                ),
                child: FaIcon(icon, size: 13, color: AppTheme.brandBlue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.brandBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, Object? value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.brandInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String email) {
    final parts = email
        .trim()
        .split('@')
        .first
        .trim()
        .split(RegExp(r'[._\- ]'));
    if (parts.isEmpty) return 'O';
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? 'O' : letters;
  }

  String? _homeText(Map<String, dynamic> o) {
    final country = o['homeCountry'];
    final city = o['homeCity'];
    if (country == null && city == null) return null;
    return [
      city,
      country,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
  }

  String? _budgetText(Map<String, dynamic> o) {
    final budget = o['budgetPerYear'];
    final currency = o['currency'];
    if (budget == null) return null;
    final amount = budget is num ? budget : 0;
    final formatted = amount >= 1000
        ? '\$${(amount / 1000).toStringAsFixed(0)}k'
        : '\$${amount.toStringAsFixed(0)}';
    return currency != null ? '$currency $formatted' : formatted;
  }

  String? _listToText(Object? value, {int max = 99}) {
    if (value is! List || value.isEmpty) return null;
    final items = value.take(max).map((e) => e.toString()).toList();
    final text = items.join(', ');
    return value.length > max ? '$text +${value.length - max} more' : text;
  }

  String? _testScoresText(Object? value) {
    if (value is! List || value.isEmpty) return null;
    return value
        .map((e) {
          if (e is Map) return '${e['testName']}: ${e['score']}';
          return e.toString();
        })
        .join(' · ');
  }
}
