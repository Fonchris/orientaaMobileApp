import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/counselor_models.dart';
import '../services/counselor_service.dart';
import 'counselor_onboarding_page.dart';

/// Pure status view for a counselor application: renders the approved,
/// rejected or pending card given a `verificationStatus` string.
///
/// Extracted from [CounselorReviewScreen] so the three states can be widget-
/// tested without a Firestore connection. The screen keeps the live profile
/// stream and auto-route; this widget only decides what to show.
class CounselorReviewStatusView extends StatelessWidget {
  final String verificationStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onGoToDashboard;

  const CounselorReviewStatusView({
    super.key,
    required this.verificationStatus,
    this.onEdit,
    this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (verificationStatus) {
      case 'approved':
        return _card(
          context,
          icon: FontAwesomeIcons.solidCircleCheck,
          iconColor: AppTheme.success,
          title: l10n.applicationApprovedTitle,
          body: l10n.applicationApprovedBody,
          buttonLabel: l10n.goToDashboard,
          onPressed: onGoToDashboard,
        );
      case 'rejected':
        return _card(
          context,
          icon: FontAwesomeIcons.triangleExclamation,
          iconColor: AppTheme.danger,
          title: l10n.applicationRejectedTitle,
          body: l10n.applicationRejectedBody,
          buttonLabel: l10n.editApplication,
          onPressed: onEdit,
        );
      default:
        return _card(
          context,
          icon: FontAwesomeIcons.hourglassHalf,
          iconColor: AppTheme.brandAmber,
          title: l10n.underReviewTitle,
          body: l10n.underReviewBody,
          slaNote: l10n.reviewSlaMessage,
        );
    }
  }

  Widget _card(
    BuildContext context, {
    required FaIconData icon,
    required Color iconColor,
    required String title,
    required String body,
    String? buttonLabel,
    VoidCallback? onPressed,
    String? slaNote,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: FaIcon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            if (slaNote != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.brandYellow.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.brandYellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.clock,
                        size: 12, color: AppTheme.brandAmber),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        slaNote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Post-submission status screen for a counselor whose application is
/// `pending` (or was `rejected`).
///
/// Listens live to `counselorProfiles/{uid}`: the moment an admin flips the
/// profile to `approved`, the counselor is routed into the normal counselor
/// experience automatically — no re-login, no manual refresh. A `rejected`
/// status offers an "Edit application" path back into the wizard so the
/// counselor can fix their details and resubmit.
class CounselorReviewScreen extends StatefulWidget {
  final String counselorUid;

  const CounselorReviewScreen({super.key, required this.counselorUid});

  @override
  State<CounselorReviewScreen> createState() => _CounselorReviewScreenState();
}

class _CounselorReviewScreenState extends State<CounselorReviewScreen> {
  final CounselorService _service = CounselorService();
  StreamSubscription<CounselorProfile?>? _subscription;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    // Auto-route the instant the profile is approved.
    _subscription = _service.watchProfile(widget.counselorUid).listen((profile) {
      if (!mounted || _routed) return;
      if (profile != null && profile.verificationStatus == 'approved') {
        _routed = true;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/counsellor-dashboard',
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _editApplication() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CounselorOnboardingPage(counselorUid: widget.counselorUid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.applicationStatus,
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<CounselorProfile?>(
        stream: _service.watchProfile(widget.counselorUid),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }
          return CounselorReviewStatusView(
            verificationStatus: profile.verificationStatus,
            onEdit: _editApplication,
            onGoToDashboard: () =>
                Navigator.of(context).pushNamedAndRemoveUntil(
              '/counsellor-dashboard',
              (route) => false,
            ),
          );
        },
      ),
    );
  }
}
