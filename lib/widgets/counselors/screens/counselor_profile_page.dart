import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../discovery/models/university_models.dart' show formatMoney;
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../../profile/profile_models.dart' show relativeTime;
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';
import 'booking_flow_page.dart';
import 'counselor_setup_page.dart';

/// Screen 2 — Counselor profile.
///
/// Full bio, chips, verified-credentials section (the raw Storage URL is never
/// shown to students), newest-first reviews (first name only), a preview of
/// the next available 60-minute slots computed server-side, and the booking
/// CTA. Counselors viewing their own profile see an "Edit Profile" button.
class CounselorProfilePage extends StatefulWidget {
  final String counselorUid;

  const CounselorProfilePage({super.key, required this.counselorUid});

  @override
  State<CounselorProfilePage> createState() => _CounselorProfilePageState();
}

class _CounselorProfilePageState extends State<CounselorProfilePage> {
  static const int _reviewPageSize = 10;

  final CounselorService _service = CounselorService();
  final CounselorFunctions _functions = CounselorFunctions();

  List<AvailableSlot>? _slots;
  bool _slotsLoading = true;

  final List<CounselorRating> _reviews = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastRatingDoc;
  bool _reviewsLoading = true;
  bool _reviewsDone = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadReviews();
  }

  Future<void> _loadSlots() async {
    setState(() => _slotsLoading = true);
    final now = DateTime.now();
    try {
      final slots = await _functions.getAvailableSlots(
        counselorUid: widget.counselorUid,
        rangeStart: now,
        rangeEnd: now.add(const Duration(days: availabilityWindowDays)),
      );
      if (mounted) setState(() => _slots = slots);
    } catch (_) {
      // Keep the section in its empty state; the booking flow re-fetches.
    } finally {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  Future<void> _loadReviews({DocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    setState(() => _reviewsLoading = true);
    try {
      final page = await _service.loadRatingsPage(
        widget.counselorUid,
        limit: _reviewPageSize,
        startAfter: startAfter,
      );
      if (!mounted) return;
      setState(() {
        _reviews.addAll(page.ratings);
        _lastRatingDoc = page.lastDoc;
        _reviewsDone = !page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _reviewsDone = true);
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: StreamBuilder<CounselorProfile?>(
        stream: _service.watchProfile(widget.counselorUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return _notFound(context);
          }
          final own = profile.uid == uid;
          return _profileView(context, profile, own);
        },
      ),
    );
  }

  Widget _notFound(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 16,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.userSlash,
                size: 36,
                color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noAvailability,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileView(BuildContext context, CounselorProfile c, bool own) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: isDark ? AppTheme.brandDark : AppTheme.brandLight,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: FaIcon(
              FontAwesomeIcons.arrowLeft,
              size: 16,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppTheme.brandYellow,
              child: Stack(
                children: [
                  Center(
                    child: ProfileAvatar(
                      photoUrl: c.photoUrl,
                      initials: counselorInitials(c.displayName, fallback: '?'),
                      size: 108,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(
              height: 2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.brandLightOutline,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleBlock(context, c),
                const SizedBox(height: 16),
                if (own) _ownBanner(context, c) else _bookCta(context, c),
                const SizedBox(height: 22),
                if (c.bio.trim().isNotEmpty) ...[
                  _sectionLabel(context, l10n.bioLabel),
                  const SizedBox(height: 8),
                  Text(
                    c.bio,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.brandInk.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (c.specialties.isNotEmpty) ...[
                  _sectionLabel(context, l10n.specialtiesTitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: c.specialties
                        .map((s) => _chip(context, s, FontAwesomeIcons.tags))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                ],
                if (c.languages.isNotEmpty) ...[
                  _sectionLabel(context, l10n.languagesTitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: c.languages
                        .map((l) => _chip(context, l, FontAwesomeIcons.language))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                ],
                if (c.isApproved) ...[
                  _credentialsCard(context, c),
                  const SizedBox(height: 22),
                ],
                _availabilitySection(context, c),
                const SizedBox(height: 22),
                _reviewsSection(context, c),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleBlock(BuildContext context, CounselorProfile c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                c.displayName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            if (c.isApproved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppTheme.success.withValues(alpha: 0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.solidCircleCheck,
                      size: 11,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.counselorVerifiedBadge,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.isOnline ? AppTheme.success : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              c.isOnline ? l10n.online : l10n.offline,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 14),
            const FaIcon(FontAwesomeIcons.solidStar, size: 12, color: AppTheme.brandAmber),
            const SizedBox(width: 5),
            Text(
              c.ratingCount > 0 ? c.ratingAverage.toStringAsFixed(1) : '—',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              c.ratingCount > 0
                  ? l10n.reviewsCount(c.ratingCount)
                  : l10n.noReviewsYet,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Text(
              '${c.currency} ${formatAmount(c.hourlyRate)} ${l10n.perSession}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.brandGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bookCta(BuildContext context, CounselorProfile c) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingFlowPage(
              counselorUid: c.uid,
              counselorName: c.displayName,
              rate: c.hourlyRate,
              currency: c.currency,
            ),
          ),
        ),
        icon: const FaIcon(FontAwesomeIcons.calendarCheck, size: 14),
        label: Text(l10n.bookSessionCta(formatMoney(c.hourlyRate, c.currency))),
      ),
    );
  }

  Widget _ownBanner(BuildContext context, CounselorProfile c) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.brandYellow.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.brandYellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _verificationNote(l10n, c),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CounselorSetupPage(counselorUid: c.uid),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              l10n.editProfile,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _verificationNote(AppLocalizations l10n, CounselorProfile c) {
    switch (c.verificationStatus) {
      case 'pending':
        return l10n.verificationPendingNote;
      case 'rejected':
        return l10n.verificationRejectedNote;
      default:
        return l10n.counselorVerifiedBadge;
    }
  }

  Widget _credentialsCard(BuildContext context, CounselorProfile c) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.success.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withValues(alpha: 0.15),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.solidCircleCheck,
                size: 17,
                color: AppTheme.success,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.credentialsVerified,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.credentialsNote,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
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
    );
  }

  Widget _availabilitySection(BuildContext context, CounselorProfile c) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, l10n.nextAvailability),
        const SizedBox(height: 10),
        if (_slotsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (_slots == null || _slots!.isEmpty)
          _inlineEmpty(context, FontAwesomeIcons.calendarXmark, l10n.noAvailability)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots!.take(5).map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.brandLightOutline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d').format(s.start),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label12h,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppTheme.brandAmber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _reviewsSection(BuildContext context, CounselorProfile c) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, l10n.reviewsTitle),
        const SizedBox(height: 10),
        if (_reviewsLoading && _reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          _inlineEmpty(context, FontAwesomeIcons.solidStar, l10n.noReviewsYet)
        else ...[
          ..._reviews.map((r) => _reviewTile(context, r)),
          if (!_reviewsDone)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: TextButton(
                  onPressed: () => _loadReviews(startAfter: _lastRatingDoc),
                  child: Text(
                    l10n.seeAll,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandGold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _reviewTile(BuildContext context, CounselorRating r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => FaIcon(
                    i < r.stars
                        ? FontAwesomeIcons.solidStar
                        : FontAwesomeIcons.star,
                    size: 11,
                    color: i < r.stars
                        ? AppTheme.brandAmber
                        : isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.brandInk.withValues(alpha: 0.2),
                  )),
              const Spacer(),
              if (r.createdAt != null)
                Text(
                  relativeTime(r.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppTheme.brandInk.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          if (r.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.reviewText,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.brandInk.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (r.studentFirstName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.studentFirstName,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandAmber,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, FaIconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.brandYellow.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.brandYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: AppTheme.brandAmber),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
    );
  }

  Widget _inlineEmpty(BuildContext context, FaIconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 15,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
