import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/african_regions.dart';
import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../student_onboarding/step1_identity_page.dart';
import '../../student_onboarding/step2_location_page.dart';
import '../models/tier_policy.dart';
import '../models/university_models.dart';
import '../providers/user_tier_provider.dart';
import '../services/recommendation_service.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/tier_upgrade_banner.dart';
import '../widgets/university_search_card.dart';
import 'university_compare_page.dart';

/// University discovery / search page.
///
/// A filter bar (country/region, degree level, fee range, field of study,
/// language) sends HARD constraints to the paginated
/// `getRecommendedUniversities` call BEFORE any ranking. Filter changes are
/// debounced 300 ms so slider ticks never fire a request.
///
/// Tier gating:
/// - Free: results capped at 20 with an "Upgrade to see all matches" banner.
/// - Pro/Premium: unlimited results + a sort dropdown.
/// - Premium only: multi-select compare mode with a Compare button.
class UniversityListPage extends StatefulWidget {
  const UniversityListPage({super.key});

  @override
  State<UniversityListPage> createState() => _UniversityListPageState();
}

class _UniversityListPageState extends State<UniversityListPage> {
  final RecommendationService _service = RecommendationService();
  final ScrollController _scrollController = ScrollController();

  RecommendationFilters _filters = RecommendationFilters.none;
  final List<RecommendedProgram> _results = [];
  final Set<String> _selected = {};
  List<RecommendedProgram> _selectedPrograms = [];

  Timer? _debounce;
  bool _loading = false;
  bool _failed = false;
  bool _hasMore = false;
  String? _cursor;
  bool _compareMode = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid.isNotEmpty) userTierProvider.watch(uid);
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Querying ────────────────────────────────────────────────────────────

  /// Debounces filter changes (300 ms) before re-querying.
  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load(reset: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    final uid = _uid;
    if (uid.isEmpty || _loading) return;

    if (reset) {
      _selected.clear();
      _selectedPrograms = [];
    }

    // Free tier never paginates past the cap.
    final free = userTierProvider.tier == UserTier.free;
    if (!reset && free && _results.length >= TierPolicy.freeSearchLimit) {
      return;
    }

    final filters = reset
        ? _filters
        : _filters.copyWith(cursor: _cursor);

    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _results.clear();
        _hasMore = false;
        _cursor = null;
      }
    });

    try {
      final result =
          await _service.fetchRecommendations(uid: uid, filters: filters);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _results
            ..clear()
            ..addAll(result.data.results);
        } else {
          _results.addAll(result.data.results);
        }
        _hasMore = result.data.hasMore;
        _cursor = result.data.cursor;
        _loading = false;
        _applyClientSort();
      });
    } catch (e) {
      debugPrint('UniversityListPage: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_results.isEmpty) _failed = true;
      });
    }
  }

  /// Client-side re-sort of the current page (Pro/Premium sort dropdown).
  void _applyClientSort() {
    switch (_filters.sort) {
      case SortOption.relevance:
        break; // engine order
      case SortOption.feeAscending:
        _results.sort((a, b) {
          final af = a.fee ?? double.infinity;
          final bf = b.fee ?? double.infinity;
          return af.compareTo(bf);
        });
      case SortOption.alphabetical:
        _results.sort((a, b) => a.universityName
            .toLowerCase()
            .compareTo(b.universityName.toLowerCase()));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.discoverTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _filterBar(context),
            const SizedBox(height: 4),
            ListenableBuilder(
              listenable: userTierProvider,
              builder: (context, _) =>
                  _toolbar(context, userTierProvider.tier),
            ),
            const Divider(height: 1),
            Expanded(child: _resultsArea(context)),
            if (_compareMode && _selected.length >= 2)
              _compareBar(context, userTierProvider.tier),
          ],
        ),
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────

  Widget _filterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = !_filters.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _filterChip(
            context,
            label: _filters.country ?? l10n.filterCountry,
            icon: FontAwesomeIcons.flag,
            active: _filters.countryCode != null,
            onTap: _openCountrySheet,
            onClear: _filters.countryCode != null
                ? () => _setFilters(
                    _filters.copyWith(
                      country: null,
                      countryCode: null,
                      region: null,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          _filterChip(
            context,
            label: _filters.degreeLevel ?? l10n.filterDegreeLevel,
            icon: FontAwesomeIcons.graduationCap,
            active: _filters.degreeLevel != null,
            onTap: _openDegreeSheet,
            onClear: _filters.degreeLevel != null
                ? () => _setFilters(_filters.copyWith(clearDegree: true))
                : null,
          ),
          const SizedBox(width: 8),
          _filterChip(
            context,
            label: _feeChipLabel(),
            icon: FontAwesomeIcons.wallet,
            active: _filters.minFee != null || _filters.maxFee != null,
            onTap: _openFeeSheet,
            onClear: _filters.minFee != null || _filters.maxFee != null
                ? () => _setFilters(_filters.copyWith(clearFee: true))
                : null,
          ),
          const SizedBox(width: 8),
          _filterChip(
            context,
            label: _filters.fields.isEmpty
                ? l10n.filterFieldOfStudy
                : '${_filters.fields.length} ${l10n.fieldsShort}',
            icon: FontAwesomeIcons.bookOpen,
            active: _filters.fields.isNotEmpty,
            onTap: _openFieldsSheet,
            onClear: _filters.fields.isNotEmpty
                ? () => _setFilters(_filters.copyWith(fields: const []))
                : null,
          ),
          const SizedBox(width: 8),
          _filterChip(
            context,
            label: _filters.language ?? l10n.filterLanguage,
            icon: FontAwesomeIcons.language,
            active: _filters.language != null,
            onTap: _openLanguageSheet,
            onClear: _filters.language != null
                ? () => _setFilters(_filters.copyWith(clearLanguage: true))
                : null,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _setFilters(RecommendationFilters.none),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Text(
                  l10n.clearFilters,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.brandGold : AppTheme.brandAmber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _feeChipLabel() {
    final f = _filters;
    if (f.minFee == null && f.maxFee == null) {
      return AppLocalizations.of(context).filterFeeRange;
    }
    final currency = f.currency ?? 'USD';
    if (f.minFee == null) return '${f.maxFee!.round()} $currency−';
    if (f.maxFee == null) return '${f.minFee!.round()}+ $currency';
    return '${f.minFee!.round()}–${f.maxFee!.round()} $currency';
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required FaIconData icon,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? AppTheme.brandYellow
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white),
          border: Border.all(
            color: active
                ? AppTheme.brandYellow
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.brandLightOutline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 11,
              color: active
                  ? AppTheme.brandInk
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.55)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppTheme.brandInk
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.brandInk.withValues(alpha: 0.7)),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 10,
                  color: active
                      ? AppTheme.brandInk.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setFilters(RecommendationFilters next) {
    setState(() => _filters = next);
    _scheduleReload();
  }

  // ── Toolbar: sort (Pro/Premium) + compare toggle (Premium) ─────────────

  Widget _toolbar(BuildContext context, UserTier tier) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSort = TierPolicy.canSort(tier);
    final showCompare = TierPolicy.canCompare(tier);

    if (!showSort && !showCompare) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          if (showSort) ...[
            FaIcon(
              FontAwesomeIcons.arrowDownWideShort,
              size: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.brandInk.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: _filters.sort,
                isDense: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
                icon: FaIcon(
                  FontAwesomeIcons.chevronDown,
                  size: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.brandInk.withValues(alpha: 0.5),
                ),
                items: [
                  DropdownMenuItem(
                    value: SortOption.relevance,
                    child: Text(l10n.sortRelevance),
                  ),
                  DropdownMenuItem(
                    value: SortOption.feeAscending,
                    child: Text(l10n.sortFeeAsc),
                  ),
                  DropdownMenuItem(
                    value: SortOption.alphabetical,
                    child: Text(l10n.sortAlphabetical),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filters = _filters.copyWith(sort: v));
                  _applyClientSort();
                  _scheduleReload();
                },
              ),
            ),
          ],
          const Spacer(),
          if (showCompare)
            GestureDetector(
              onTap: () {
                setState(() {
                  _compareMode = !_compareMode;
                  _selected.clear();
                  _selectedPrograms = [];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _compareMode
                      ? AppTheme.brandYellow
                      : Colors.transparent,
                  border: Border.all(
                    color: _compareMode
                        ? AppTheme.brandYellow
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppTheme.brandLightOutline),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.scaleBalanced,
                      size: 11,
                      color: _compareMode
                          ? AppTheme.brandInk
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.brandInk.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.compare,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _compareMode
                            ? AppTheme.brandInk
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.brandInk.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Results area ────────────────────────────────────────────────────────

  Widget _resultsArea(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tier = userTierProvider.tier;

    if (_loading && _results.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonSearchCard(),
      );
    }

    if (_failed && _results.isEmpty) {
      return _noResults(
        context,
        icon: FontAwesomeIcons.triangleExclamation,
        title: l10n.couldNotLoadRecommendations,
        message: l10n.retry,
        onAction: () => _load(reset: true),
      );
    }

    if (_results.isEmpty) {
      return _noResults(
        context,
        icon: FontAwesomeIcons.magnifyingGlass,
        title: l10n.noUniversitiesFound,
        message: l10n.tryAdjustingFilters,
      );
    }

    // Free tier: only render the first 20. Pagination is blocked at the cap,
    // so "hidden" means more matches exist beyond what this tier may see
    // (otherwise the banner would never render and an endless spinner would).
    final limit = TierPolicy.searchLimit(tier);
    final shown = limit == null || _results.length <= limit
        ? _results
        : _results.sublist(0, limit);
    final hidden = limit != null && (_hasMore || _results.length > limit);

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: shown.length + (_hasMore && !hidden ? 1 : 0) + (hidden ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i < shown.length) {
          final program = shown[i];
          return UniversitySearchCard(
            program: program,
            tier: tier,
            compareMode: _compareMode,
            selected: _selected.contains(program.programId),
            onSelectionChanged: (v) => _toggleSelected(program, v),
          );
        }
        if (hidden) {
          return TierUpgradeBanner(message: l10n.upgradeToSeeAllMatches);
        }
        if (_hasMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDarkSafe ? AppTheme.brandGold : AppTheme.brandAmber,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  bool get isDarkSafe => Theme.of(context).brightness == Brightness.dark;

  void _toggleSelected(RecommendedProgram program, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(program.programId);
        _selectedPrograms
          ..removeWhere((p) => p.programId == program.programId)
          ..add(program);
      } else {
        _selected.remove(program.programId);
        _selectedPrograms.removeWhere((p) => p.programId == program.programId);
      }
    });
  }

  Widget _compareBar(BuildContext context, UserTier tier) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.brandSurface
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.brandLightOutline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.compareSelectedCount(_selected.length),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.brandInk,
              ),
            ),
          ),
          FilledButton(
            onPressed: _selected.length >= 2
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UniversityComparePage(
                          programs: List.of(_selectedPrograms),
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(l10n.compare),
          ),
        ],
      ),
    );
  }

  // ── Filter sheets ───────────────────────────────────────────────────────

  Future<void> _openCountrySheet() async {
    final country = await showCountryPickerDialog(context);
    if (country == null || !mounted) return;
    final region = AfricanRegions.getRegion(country.code);
    _setFilters(
      _filters.copyWith(
        country: country.name,
        countryCode: country.code,
        region: region,
      ),
    );
  }

  Future<void> _openDegreeSheet() => _showSheet<String>(
        title: AppLocalizations.of(context).filterDegreeLevel,
        options: ['', ...Step1IdentityPage.degreeLevels],
        labels: (o) => o.isEmpty ? 'Any' : o,
        selected: _filters.degreeLevel,
        onSelected: (v) =>
            _setFilters(_filters.copyWith(degreeLevel: v.isEmpty ? null : v)),
      );

  Future<void> _openLanguageSheet() => _showSheet<String>(
        title: AppLocalizations.of(context).filterLanguage,
        options: ['', ...Step2LocationPage.languagesOfInstruction],
        labels: (o) => o.isEmpty ? 'Any' : o,
        selected: _filters.language,
        onSelected: (v) =>
            _setFilters(_filters.copyWith(language: v.isEmpty ? null : v)),
      );

  Future<void> _openFieldsSheet() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = Set<String>.of(_filters.fields);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  _sheetHandle(isDark),
                  _sheetTitle(ctx, l10n.filterFieldOfStudy),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Step1IdentityPage.fieldsOfInterest.map((f) {
                          final on = current.contains(f);
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              on ? current.remove(f) : current.add(f);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: on
                                    ? AppTheme.brandYellow
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.white),
                                border: Border.all(
                                  color: on
                                      ? AppTheme.brandYellow
                                      : (isDark
                                          ? Colors.white.withValues(
                                              alpha: 0.1,
                                            )
                                          : AppTheme.brandLightOutline),
                                ),
                              ),
                              child: Text(
                                f,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: on
                                      ? AppTheme.brandInk
                                      : (isDark
                                          ? Colors.white.withValues(
                                              alpha: 0.75,
                                            )
                                          : AppTheme.brandInk.withValues(
                                              alpha: 0.7,
                                            )),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, current.toList()),
                        child: Text(l10n.applyFilters),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result != null && mounted) {
      _setFilters(_filters.copyWith(fields: result));
    }
  }

  Future<void> _openFeeSheet() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maxRange = 100000.0;

    double minFee = _filters.minFee ?? 0;
    double maxFee = _filters.maxFee ?? maxRange;
    String currency = _filters.currency ?? 'USD';
    const currencies = [
      'USD',
      'EUR',
      'GBP',
      'NGN',
      'GHS',
      'KES',
      'ZAR',
      'CAD',
      'AUD',
    ];

    final applied = await showModalBottomSheet<({double? min, double? max, String currency})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  _sheetHandle(isDark),
                  _sheetTitle(ctx, l10n.filterFeeRange),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          l10n.currencyLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.brandInk.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currency,
                          isDense: true,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor:
                              isDark ? AppTheme.brandCard : Colors.white,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppTheme.brandInk,
                          ),
                          items: currencies
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setSheetState(() => currency = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${formatMoney(minFee, currency)} — ${maxFee >= maxRange ? '${formatMoney(maxFee, currency)}+' : formatMoney(maxFee, currency)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                  ),
                  RangeSlider(
                    values: RangeValues(minFee, maxFee),
                    max: maxRange,
                    divisions: 40,
                    activeColor: AppTheme.brandYellow,
                    inactiveColor: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.grey.shade300,
                    labels: RangeLabels(
                      formatMoney(minFee, currency),
                      maxFee >= maxRange
                          ? '${formatMoney(maxFee, currency)}+'
                          : formatMoney(maxFee, currency),
                    ),
                    onChanged: (v) => setSheetState(() {
                      minFee = v.start;
                      maxFee = v.end;
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          ctx,
                          (
                            min: minFee <= 0 ? null : minFee,
                            max: maxFee >= maxRange ? null : maxFee,
                            currency: currency,
                          ),
                        ),
                        child: Text(l10n.applyFilters),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (applied != null && mounted) {
      _setFilters(
        _filters.copyWith(
          minFee: applied.min,
          maxFee: applied.max,
          currency: applied.currency,
        ),
      );
    }
  }

  Future<void> _showSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labels,
    required T? selected,
    required ValueChanged<T> onSelected,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosen = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _sheetHandle(isDark),
            _sheetTitle(ctx, title),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map((o) => ListTile(
                          leading: FaIcon(
                            o == selected
                                ? FontAwesomeIcons.solidCircleDot
                                : FontAwesomeIcons.circle,
                            size: 14,
                            color: o == selected
                                ? AppTheme.brandYellow
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : AppTheme.brandInk.withValues(
                                        alpha: 0.35,
                                      )),
                          ),
                          title: Text(
                            labels(o),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: o == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.brandInk,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, o),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) onSelected(chosen);
  }

  Widget _sheetHandle(bool isDark) => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _sheetTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppTheme.brandInk,
        ),
      ),
    );
  }

  Widget _noResults(
    BuildContext context, {
    required FaIconData icon,
    required String title,
    required String message,
    VoidCallback? onAction,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandAmber.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                child: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
