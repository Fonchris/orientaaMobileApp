import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/tier_policy.dart';
import '../models/university_models.dart';
import '../providers/user_tier_provider.dart';
import '../services/recommendation_service.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/tier_upgrade_banner.dart';

/// "Recommended for you" section on the home dashboard.
///
/// Fetches the top matches from `getRecommendedUniversities(uid)` on load and
/// renders them as a horizontally scrollable rail of [RecommendationCard]s.
///
/// - Loading: skeleton cards (never a spinner over blank space).
/// - Tier gating: free = first 5, pro = 15, premium = full list + refresh.
/// - Empty + incomplete profile: CTA card linking to the profile editor.
/// - Offline: falls back to the last cached payload with an offline notice.
/// - Pull-to-refresh: expose [RecommendationsSectionState.refresh].
class RecommendationsSection extends StatefulWidget {
  final VoidCallback onOpenDiscover;
  final VoidCallback onCompleteProfile;

  const RecommendationsSection({
    super.key,
    required this.onOpenDiscover,
    required this.onCompleteProfile,
  });

  @override
  State<RecommendationsSection> createState() => RecommendationsSectionState();
}

class RecommendationsSectionState extends State<RecommendationsSection> {
  final RecommendationService _service = RecommendationService();

  RecommendationResult? _result;
  bool _loading = false;
  bool _failed = false;
  bool? _profileComplete;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid.isNotEmpty) {
      userTierProvider.watch(uid);
      _checkProfileStatus(uid);
      refresh();
    }
  }

  Future<void> _checkProfileStatus(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;
      setState(() => _profileComplete = snap.data()?['onboardingComplete'] == true);
    } catch (_) {
      if (mounted) setState(() => _profileComplete = null);
    }
  }

  /// Fetches recommendations (used by pull-to-refresh and the premium
  /// refresh affordance). Never throws — errors surface as state.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _service.fetchRecommendations(uid: uid);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint('RecommendationsSection: $e');
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: userTierProvider,
          builder: (context, _) {
            final tier = userTierProvider.tier;
            return _body(context, tier, l10n);
          },
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.recommendedForYou,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (TierPolicy.canRefresh(userTierProvider.tier))
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => _loading ? null : refresh(),
            icon: FaIcon(
              FontAwesomeIcons.rotate,
              size: 13,
              color: isDark ? AppTheme.brandGold : AppTheme.brandAmber,
            ),
          ),
        GestureDetector(
          onTap: widget.onOpenDiscover,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
      ],
    );
  }

  Widget _body(BuildContext context, UserTier tier, AppLocalizations l10n) {
    final result = _result;

    // First load in flight — show skeleton cards.
    if (_loading && result == null) {
      return _skeletonRail();
    }

    // Nothing fetched yet and the fetch failed — error card with retry.
    if (result == null && _failed) {
      return _errorCard(context, l10n);
    }

    final results = result?.data.results ?? const <RecommendedProgram>[];

    // Empty result set.
    if (results.isEmpty) {
      // Incomplete profile → CTA to finish it.
      if (_profileComplete == false) {
        return _profileCtaCard(context, l10n);
      }
      return _emptyCard(context, l10n);
    }

    final visible = TierPolicy.cap(results, tier, TierPolicy.dashboardLimit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 262,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                RecommendationCard(program: visible[i], tier: tier),
          ),
        ),
        if (result?.fromCache == true) ...[
          const SizedBox(height: 8),
          _offlineChip(context, l10n),
        ],        if (TierPolicy.showUpgradeBanner(
          tier,
          total: results.length,
          shown: visible.length,
        )) ...[          const SizedBox(height: 8),
          TierUpgradeBanner(
            message: l10n.upgradeToSeeAllRecommendations,
          ),
        ],
      ],
    );
  }

  Widget _skeletonRail() {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SkeletonRecommendationCard(),
      ),
    );
  }

  Widget _offlineChip(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        FaIcon(
          FontAwesomeIcons.wifi,
          size: 11,
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : AppTheme.brandInk.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.offlineShowingCached,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.45)
                : AppTheme.brandInk.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandYellow.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.school,
            size: 18,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandInk.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noRecommendationsTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.noRecommendationsMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.brandInk.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCtaCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.brandYellow,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.userPen,
                size: 17,
                color: AppTheme.brandInk,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.completeProfileCtaTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.completeProfileCtaMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
                    color: AppTheme.brandInk.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onCompleteProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppTheme.brandInk,
              ),
              child: Text(
                l10n.completeProfileButton,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            FontAwesomeIcons.triangleExclamation,
            size: 18,
            color: isDark ? AppTheme.brandGold : AppTheme.brandAmber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.couldNotLoadRecommendations,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandInk.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: refresh,
            child: Text(
              l10n.retry,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
