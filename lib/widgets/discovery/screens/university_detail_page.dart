import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../counselors/screens/counselor_directory_page.dart';
import '../../google_fonts.dart';
import '../models/tier_policy.dart';
import '../models/university_models.dart';
import '../providers/user_tier_provider.dart';
import '../services/user_interactions_service.dart';
import '../widgets/country_flag.dart';
import '../widgets/save_button.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/tier_upgrade_banner.dart';
import 'maps_config.dart';

/// University detail page.
///
/// Sections: banner image, name + country + verified badge, overview,
/// expandable programs (fee / duration / admission requirements), a map
/// (lat/lng via Google Maps static image), and a gated "Students like you
/// also viewed" strip.
///
/// Opening the page logs a fire-and-forget `university_view` interaction
/// event for the recommendation engine — never blocks rendering.
class UniversityDetailPage extends StatefulWidget {
  final String universityId;
  final RecommendedProgram? initialProgram;

  const UniversityDetailPage({
    super.key,
    required this.universityId,
    this.initialProgram,
  });

  @override
  State<UniversityDetailPage> createState() => _UniversityDetailPageState();
}

class _UniversityDetailPageState extends State<UniversityDetailPage> {
  static const UserInteractionsService _interactions =
      UserInteractionsService();

  late Future<UniversityDetail> _future;

  @override
  void initState() {
    super.initState();
    _logView();
    _future = _loadDetail();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _logView() {
    // Fire-and-forget by design: view logging must never block render.
    unawaited(_interactions.log(
      uid: _uid,
      type: 'university_view',
      programId: widget.initialProgram?.programId,
      universityId: widget.universityId,
      extra: {
        if (widget.initialProgram != null)
          'programName': widget.initialProgram!.programName,
      },
    ));
  }

  Future<UniversityDetail> _loadDetail() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('universities')
          .doc(widget.universityId)
          .get();
      if (snap.exists) {
        return UniversityDetail.fromSnapshot(snap);
      }
    } catch (e) {
      debugPrint('UniversityDetailPage: fetch failed ($e)');
    }
    // Doc missing / offline — build a minimal detail from the card data so
    // the page never renders blank.
    final p = widget.initialProgram;
    return UniversityDetail(
      id: widget.universityId,
      name: p?.universityName ?? widget.universityId,
      country: p?.country,
      countryCode: p?.countryCode,
      imageUrl: p?.bannerUrl,
      logoUrl: p?.logoUrl,
      latitude: p?.latitude,
      longitude: p?.longitude,
      programs: [
        if (p != null && p.programName.isNotEmpty)
          UniversityProgram(
            id: p.programId,
            name: p.programName,
            degreeLevel: p.degreeLevel,
            fee: p.fee,
            currency: p.currency,
            language: p.language,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UniversityDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _detailSkeleton(context);
          }
          final detail = snapshot.data ??
              UniversityDetail(id: widget.universityId, name: widget.universityId);
          return _detailView(context, detail);
        },
      ),
    );
  }

  Widget _detailView(BuildContext context, UniversityDetail detail) {
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        _bannerSliver(context, detail),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleBlock(context, detail),
                const SizedBox(height: 18),
                _sectionLabel(context, l10n.aboutThisUniversity),
                const SizedBox(height: 8),
                _aboutCard(context, detail),
                const SizedBox(height: 20),
                _sectionLabel(context, l10n.programsTitle),
                const SizedBox(height: 8),
                _programsList(context, detail),
                if (detail.hasLocation) ...[
                  const SizedBox(height: 20),
                  _sectionLabel(context, l10n.locationSection),
                  const SizedBox(height: 8),
                  _mapCard(context, detail),
                ],
                const SizedBox(height: 20),
                // Both the also-viewed strip and the premium booking button
                // depend on tier state, so they share one ListenableBuilder
                // and stay reactive to live subscription changes.
                ListenableBuilder(
                  listenable: userTierProvider,
                  builder: (context, _) {
                    final tier = userTierProvider.tier;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _alsoViewedSection(context, tier),
                        if (TierPolicy.canBookCounselor(tier)) ...[
                          const SizedBox(height: 20),
                          _bookCounselorButton(context),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sections ────────────────────────────────────────────────────────────

  Widget _bannerSliver(BuildContext context, UniversityDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerUrl = detail.imageUrl;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 210,
      backgroundColor: isDark ? AppTheme.brandDark : AppTheme.brandLight,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: FaIcon(
          FontAwesomeIcons.arrowLeft,
          size: 16,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.35),
        ),
      ),
      actions: [
        if (widget.initialProgram != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SaveButton(
              program: widget.initialProgram!,
              iconSize: 15,
              useAppBarStyle: true,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: bannerUrl != null && bannerUrl.isNotEmpty
            ? Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _BannerFallback(),
              )
            : const _BannerFallback(),
      ),
    );
  }

  Widget _titleBlock(BuildContext context, UniversityDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            if (detail.verified)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
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
                      'Verified',
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
        CountryFlag(
          countryCode: detail.countryCode,
          countryName: detail.country,
          flagSize: 18,
          showName: detail.country != null,
        ),
      ],
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

  Widget _aboutCard(BuildContext context, UniversityDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final description = detail.description;
    if (description == null || description.trim().isEmpty) {
      return _surfaceCard(
        context,
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circleInfo,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppTheme.brandInk.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No overview available yet for this university.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
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
    return _surfaceCard(context, child: _ReadMoreText(text: description));
  }

  Widget _programsList(BuildContext context, UniversityDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (detail.programs.isEmpty) {
      return _surfaceCard(
        context,
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.bookOpen,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppTheme.brandInk.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Program details are coming soon.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
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
    return _surfaceCard(
      context,
      child: Column(
        children: detail.programs.asMap().entries.map((entry) {
          final index = entry.key;
          final program = entry.value;
          return Column(
            children: [
              _ProgramTile(program: program),
              if (index < detail.programs.length - 1)
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppTheme.brandLightOutline,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _mapCard(BuildContext context, UniversityDetail detail) {
    final mapUrl = detail.hasLocation
        ? MapsConfig.staticMapUrl(
            lat: detail.latitude!,
            lng: detail.longitude!,
          )
        : null;

    return _surfaceCard(
      context,
      padding: EdgeInsets.zero,
      clip: true,
      child: mapUrl != null
          ? AspectRatio(
              aspectRatio: 2,
              child: Image.network(
                mapUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _mapPlaceholder(context, detail),
              ),
            )
          : _mapPlaceholder(context, detail),
    );
  }

  Widget _mapPlaceholder(BuildContext context, UniversityDetail detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.brandCard
            : AppTheme.brandYellow.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.mapLocationDot,
              size: 24,
              color: AppTheme.brandAmber,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mapNotAvailable,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandInk.withValues(alpha: 0.7),
              ),
            ),
            if (detail.hasLocation) ...[
              const SizedBox(height: 4),
              Text(
                '${detail.latitude!.toStringAsFixed(3)}, ${detail.longitude!.toStringAsFixed(3)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppTheme.brandInk.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Students like you also viewed" — Pro/Premium only.
  ///
  /// TODO: data-fetching depends on a future collaborative-filtering Cloud
  /// Function (e.g. `getAlsoViewed(universityId, uid)`). UI + gating are
  /// built now; free users see a locked/blurred placeholder with an upgrade
  /// CTA instead of real data.
  Widget _alsoViewedSection(BuildContext context, UserTier tier) {
    final l10n = AppLocalizations.of(context);

    if (!TierPolicy.canSeeAlsoViewed(tier)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, l10n.studentsAlsoViewed),
          const SizedBox(height: 8),
          _lockedAlsoViewed(context),
          const SizedBox(height: 8),
          TierUpgradeBanner(message: l10n.lockedAlsoViewedMessage),
        ],
      );
    }

    // Pro/Premium: real strip UI; rows are placeholders until the
    // collaborative-filtering function lands (see TODO above).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, l10n.studentsAlsoViewed),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _alsoViewedStubCard(context),
          ),
        ),
      ],
    );
  }

  Widget _lockedAlsoViewed(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, _) => _alsoViewedStubCard(context),
                ),
              ),
            ),
            // Frosted blur on top of the real UI — no real data leaks.
            Positioned.fill(
              child: Container(
                color: isDark
                    ? AppTheme.brandDark.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppTheme.brandYellow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.lock,
                        size: 11,
                        color: AppTheme.brandInk,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unlock',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder tile for the also-viewed strip. Swap for a real
  /// [RecommendationCard]-style tile once the CF data source exists.
  Widget _alsoViewedStubCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.brandYellow.withValues(alpha: 0.25),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.school,
                size: 13,
                color: AppTheme.brandAmber,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: SkeletonBlock(height: 11, radius: 5),
          ),
        ],
      ),
    );
  }

  Widget _bookCounselorButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: AppTheme.brandYellow.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CounselorDirectoryPage(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brandYellow,
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.userTie,
                      size: 17,
                      color: AppTheme.brandInk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.bookCounselorSession,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.brandInk,
                    ),
                  ),
                ),
                const FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 13,
                  color: AppTheme.brandAmber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  Widget _surfaceCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    bool clip = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: clip ? EdgeInsets.zero : padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: child,
    );
  }

  Widget _detailSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          height: 210,
          color: isDark ? AppTheme.brandSurface : AppTheme.brandLight,
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SkeletonPulse(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBlock(height: 22, radius: 8, width: 220),
                SizedBox(height: 10),
                SkeletonBlock(height: 13, radius: 6, width: 140),
                SizedBox(height: 24),
                SkeletonBlock(height: 15, radius: 7, width: 120),
                SizedBox(height: 10),
                SkeletonBlock(height: 64, radius: 14),
                SizedBox(height: 20),
                SkeletonBlock(height: 15, radius: 7, width: 120),
                SizedBox(height: 10),
                SkeletonBlock(height: 120, radius: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.brandYellow,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.graduationCap,
          size: 64,
          color: AppTheme.brandInk.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Description with read-more/less.
class _ReadMoreText extends StatefulWidget {
  final String text;

  const _ReadMoreText({required this.text});

  @override
  State<_ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<_ReadMoreText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = GoogleFonts.inter(
      fontSize: 13,
      height: 1.5,
      color: isDark
          ? Colors.white.withValues(alpha: 0.75)
          : AppTheme.brandInk.withValues(alpha: 0.75),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: textStyle,
        ),
        if (widget.text.length > 160)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandAmber,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Expandable program row revealing fee / duration / admission requirements.
class _ProgramTile extends StatefulWidget {
  final UniversityProgram program;

  const _ProgramTile({required this.program});

  @override
  State<_ProgramTile> createState() => _ProgramTileState();
}

class _ProgramTileState extends State<_ProgramTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.program;
    final details = <(FaIconData, String)>[
      if (p.degreeLevel != null)
        (FontAwesomeIcons.graduationCap, p.degreeLevel!),
      if (p.fee != null)
        (FontAwesomeIcons.wallet, formatMoney(p.fee, p.currency)),
      if (p.duration != null)
        (FontAwesomeIcons.clock, p.duration!),
      if (p.language != null)
        (FontAwesomeIcons.language, p.language!),
    ];

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.brandInk,
                    ),
                  ),
                ),
                FaIcon(
                  _expanded
                      ? FontAwesomeIcons.chevronUp
                      : FontAwesomeIcons.chevronDown,
                  size: 12,
                  color: AppTheme.brandAmber,
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: details
                    .map((d) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              d.$1,
                              size: 11,
                              color: AppTheme.brandAmber,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              d.$2,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.brandInk.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ],
            if (_expanded && p.admissionRequirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Admission requirements',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
              const SizedBox(height: 6),
              ...p.admissionRequirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.solidCircleCheck,
                          size: 10,
                          color: AppTheme.brandAmber,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            req,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.35,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.brandInk.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
