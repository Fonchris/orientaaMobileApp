import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_service.dart';
import 'counselor_profile_page.dart';
import 'counselor_setup_page.dart';

/// Screen 1 — Counselor directory.
///
/// Approved counselors, paginated 20/page with infinite scroll. Filters
/// (specialty chips, price range, online toggle, language) are pushed to
/// Firestore; name search is applied client-side over the loaded pages and is
/// flagged as a limitation (true full-text search needs Algolia/Typesense or
/// a dedicated Cloud Function).
class CounselorDirectoryPage extends StatefulWidget {
  const CounselorDirectoryPage({super.key});

  @override
  State<CounselorDirectoryPage> createState() => _CounselorDirectoryPageState();
}

class _CounselorDirectoryPageState extends State<CounselorDirectoryPage> {
  static const List<String> _languages = [
    'English', 'French', 'Arabic', 'Portuguese', 'Spanish', 'Swahili',
    'Hausa', 'Yoruba', 'Igbo', 'Amharic', 'Zulu', 'Wolof', 'Lingala',
    'German', 'Mandarin', 'Hindi',
  ];

  final CounselorService _service = CounselorService();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<CounselorProfile> _counselors = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  CounselorFilters _filters = const CounselorFilters();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  /// Fetches directory batches until one yields matching profiles (or the
  /// source is exhausted). A batch can legitimately contain zero matches
  /// when a filter excludes the top of the sort order (e.g. a min price
  /// while sorting by recommended), so we keep scanning rather than showing
  /// the empty state prematurely.
  Future<DirectoryPage> _fetchUntilMatch(
    DocumentSnapshot<Map<String, dynamic>>? after,
  ) async {
    var page = await _service.loadDirectoryPage(_filters, startAfter: after);
    while (page.profiles.isEmpty && page.hasMore) {
      page = await _service.loadDirectoryPage(_filters, startAfter: page.lastDoc);
    }
    return page;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loadingFirst = true;
      _error = null;
      _counselors.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    try {
      final page = await _fetchUntilMatch(null);
      if (!mounted) return;
      setState(() {
        _counselors.addAll(page.profiles);
        _hasMore = page.hasMore;
        _lastDoc = _hasMore ? page.lastDoc : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingFirst = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loadingFirst) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetchUntilMatch(_lastDoc);
      if (!mounted) return;
      setState(() {
        _counselors.addAll(page.profiles);
        _hasMore = page.hasMore;
        _lastDoc = _hasMore ? page.lastDoc : null;
      });
    } catch (_) {
      // Keep scrolling silent: infinite scroll failures just stop loading.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<CounselorFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.brandSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet(
        initial: _filters,
        specialtyOptions: {
          ...counselorSpecialtyPresets,
          ..._counselors.expand((c) => c.specialties),
        }.toList(),
        languageOptions: _languages,
      ),
    );
    if (result != null && result != _filters) {
      setState(() => _filters = result);
      await _loadFirstPage();
    }
  }

  Future<void> _openSort() async {
    final selected = await showModalBottomSheet<CounselorSort>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.brandSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final options = [
          (CounselorSort.recommended, l10n.sortRecommended, FontAwesomeIcons.star),
          (CounselorSort.priceAsc, l10n.sortPriceLowToHigh, FontAwesomeIcons.arrowUpWideShort),
          (CounselorSort.ratingDesc, l10n.sortRatingHighToLow, FontAwesomeIcons.arrowDownWideShort),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  l10n.sortBy,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
              ),
              ...options.map((o) => ListTile(
                    leading: FaIcon(o.$3, size: 15, color: AppTheme.brandAmber),
                    title: Text(
                      o.$2,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    trailing: _filters.sort == o.$1
                        ? const FaIcon(
                            FontAwesomeIcons.solidCircleCheck,
                            size: 15,
                            color: AppTheme.brandYellow,
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, o.$1),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _filters.sort) {
      setState(() => _filters = _filters.copyWith(sort: selected));
      await _loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visible = _query.trim().isEmpty
        ? _counselors
        : _counselors
            .where((c) => c.displayName.toLowerCase().contains(_query.trim().toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _filterBar(context),
            Expanded(child: _body(context, visible, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.counselorDirectoryTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
          if (uid != null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CounselorSetupPage(counselorUid: uid),
                ),
              ),
              icon: const FaIcon(
                FontAwesomeIcons.userTie,
                size: 12,
                color: AppTheme.brandAmber,
              ),
              label: Text(
                l10n.becomeCounselor,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandGold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.counselorSearchHint,
          prefixIcon: FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const FaIcon(FontAwesomeIcons.xmark, size: 13),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chip(String label, FaIconData icon, VoidCallback onTap, {bool active = false}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: active
              ? AppTheme.brandYellow
              : (isDark ? AppTheme.brandCard : Colors.white),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? AppTheme.brandYellow
                      : isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.brandLightOutline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(icon, size: 11, color: active ? AppTheme.brandInk : AppTheme.brandAmber),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppTheme.brandInk
                          : isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppTheme.brandInk,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 5),
                    const FaIcon(
                      FontAwesomeIcons.solidCircle,
                      size: 7,
                      color: AppTheme.brandInk,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filtersActive = !_filters.isEmpty;

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            children: [
              chip(l10n.sortBy, FontAwesomeIcons.arrowUpWideShort, _openSort),
              chip(
                l10n.filterSpecialtyLabel,
                FontAwesomeIcons.tags,
                _openFilters,
                active: filtersActive,
              ),
              chip(l10n.filterPriceRange, FontAwesomeIcons.sliders, _openFilters),
              chip(l10n.filterOnlineOnly, FontAwesomeIcons.wifi, _openFilters),
              chip(l10n.filterLanguageLabel, FontAwesomeIcons.language, _openFilters),
              if (filtersActive)
                chip(l10n.clearFilters, FontAwesomeIcons.xmark, () {
                  setState(() => _filters = const CounselorFilters());
                  _loadFirstPage();
                }),
            ],
          ),
        ),
        _searchField(context),
      ],
    );
  }

  Widget _body(BuildContext context, List<CounselorProfile> visible, bool isDark) {
    final l10n = AppLocalizations.of(context);

    if (_loadingFirst) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: 6,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _CounselorCardSkeleton(),
        ),
      );
    }
    if (_error != null && _counselors.isEmpty) {
      return _emptyState(context, isDark, error: _error);
    }
    if (_counselors.isEmpty) {
      return _emptyState(context, isDark);
    }
    if (visible.isEmpty) {
      return _emptyState(context, isDark, searching: true);
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: visible.length + 1,
      itemBuilder: (context, i) {
        if (i == visible.length) {
          if (!_hasMore && _query.trim().isNotEmpty) {
            // Client-side name search note — flagged limitation.
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.counselorSearchNameNote,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppTheme.brandInk.withValues(alpha: 0.4),
                ),
              ),
            );
          }
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          return const SizedBox(height: 12);
        }
        final c = visible[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CounselorCard(
            counselor: c,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CounselorProfilePage(counselorUid: c.uid),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(
    BuildContext context,
    bool isDark, {
    String? error,
    bool searching = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final message = error != null
        ? l10n.getAvailableSlotsError
        : l10n.noCounselorsMatch;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              error != null
                  ? FontAwesomeIcons.triangleExclamation
                  : FontAwesomeIcons.userSlash,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                _search.clear();
                setState(() {
                  _query = '';
                  _filters = const CounselorFilters();
                });
                _loadFirstPage();
              },
              icon: const FaIcon(FontAwesomeIcons.rotate, size: 12),
              label: Text(l10n.resetFilters),
            ),
          ],
        ),
      ),
    );
  }
}

/// A directory card: photo, name, top 2 specialties, session price, rating +
/// review count, online dot.
class _CounselorCard extends StatelessWidget {
  final CounselorProfile counselor;
  final VoidCallback onTap;

  const _CounselorCard({required this.counselor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = counselor;

    return Material(
      color: isDark ? AppTheme.brandSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppTheme.brandLightOutline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    photoUrl: c.photoUrl,
                    initials: _initials(c.displayName),
                    size: 56,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.isOnline ? AppTheme.success : Colors.grey,
                        border: Border.all(
                          color: isDark ? AppTheme.brandSurface : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.brandInk,
                            ),
                          ),
                        ),
                        if (c.isApproved) ...[
                          const SizedBox(width: 6),
                          const FaIcon(
                            FontAwesomeIcons.solidCircleCheck,
                            size: 13,
                            color: AppTheme.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: c.specialties
                          .take(2)
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppTheme.brandYellow
                                      .withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brandAmber,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${c.currency} ${_amount(c.hourlyRate)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandGold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context).perSession,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.45)
                                : AppTheme.brandInk.withValues(alpha: 0.45),
                          ),
                        ),
                        const Spacer(),
                        if (c.ratingCount > 0) ...[
                          const FaIcon(
                            FontAwesomeIcons.solidStar,
                            size: 11,
                            color: AppTheme.brandAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.ratingAverage.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppTheme.brandInk.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${c.ratingCount})',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : AppTheme.brandInk.withValues(alpha: 0.45),
                            ),
                          ),
                        ] else
                          Text(
                            AppLocalizations.of(context).noReviewsYet,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : AppTheme.brandInk.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  String _amount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}

class _CounselorCardSkeleton extends StatelessWidget {
  const _CounselorCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandYellow,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.brandLightOutline,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 90,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : AppTheme.brandLightOutline,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter bottom sheet: specialty multi-select, price range slider, online
/// toggle and language dropdown. Returns an updated [CounselorFilters].
class _FilterSheet extends StatefulWidget {
  final CounselorFilters initial;
  final List<String> specialtyOptions;
  final List<String> languageOptions;

  const _FilterSheet({
    required this.initial,
    required this.specialtyOptions,
    required this.languageOptions,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<String> _specialties = [...widget.initial.specialties];
  late bool _onlineOnly = widget.initial.onlineOnly;
  late double? _min = widget.initial.minPrice;
  late double? _max = widget.initial.maxPrice;
  late String? _language = widget.initial.languages.isEmpty
      ? null
      : widget.initial.languages.first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lo = _min ?? 0;
    final hi = _max ?? 200;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                l10n.applyFilters,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(l10n.filterSpecialtyLabel, isDark),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.specialtyOptions.map((s) {
                        final selected = _specialties.contains(s);
                        return ChoiceChip(
                          label: Text(s),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _specialties = {..._specialties, s}.toList();
                            } else {
                              _specialties = _specialties.where((x) => x != s).toList();
                            }
                          }),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.brandInk
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppTheme.brandInk),
                          ),
                          selectedColor: AppTheme.brandYellow,
                          backgroundColor: isDark
                              ? AppTheme.brandCard
                              : AppTheme.brandLight,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.filterPriceRange, isDark),
                    const SizedBox(height: 4),
                    Text(
                      '$lo – $hi ${l10n.perSession}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandAmber,
                      ),
                    ),
                    RangeSlider(
                      values: RangeValues(lo, hi),
                      min: 0,
                      max: 200,
                      divisions: 40,
                      activeColor: AppTheme.brandYellow,
                      inactiveColor: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppTheme.brandLightOutline,
                      onChanged: (v) => setState(() {
                        _min = v.start;
                        _max = v.end;
                      }),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.filterOnlineOnly,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.brandInk,
                        ),
                      ),
                      value: _onlineOnly,
                      activeTrackColor: AppTheme.brandYellow,
                      onChanged: (v) => setState(() => _onlineOnly = v),
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel(l10n.filterLanguageLabel, isDark),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _language,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            l10n.allLanguages,
                            style: GoogleFonts.inter(fontSize: 13.5),
                          ),
                        ),
                        ...widget.languageOptions.map((l) =>
                            DropdownMenuItem<String?>(value: l, child: Text(l))),
                      ],
                      onChanged: (v) => setState(() => _language = v),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    CounselorFilters(
                      specialties: _specialties,
                      languages: _language == null ? const [] : [_language!],
                      onlineOnly: _onlineOnly,
                      minPrice: _min,
                      maxPrice: _max,
                      sort: widget.initial.sort,
                    ),
                  );
                },
                child: Text(l10n.applyFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
    );
  }
}
