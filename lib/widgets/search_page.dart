import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'google_fonts.dart';
import 'profile/profile_avatar.dart';
import 'profile/profile_models.dart';
import 'profile/profile_page.dart';

const List<String> _suggestedSearches = [
  'Computer Science',
  'Medicine',
  'Scholarships',
  'Engineering',
  'IELTS',
];

const List<String> _trendingSearches = [
  'University of Cape Town',
  'Study in Canada',
  'Counsellor',
  'Renewable Energy',
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _SearchTab { people, universities, classrooms, posts }

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _SearchTab _tab = _SearchTab.people;
  String? _roleFilter; // null = all, 'student', 'counsellor'
  List<String> _recent = const [];

  String get _me => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? const [];
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _remember(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [q, ..._recent.where((r) => r.toLowerCase() != q.toLowerCase())]
        .take(8)
        .toList();
    await prefs.setStringList('recent_searches', updated);
    if (mounted) setState(() => _recent = updated);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) setState(() => _recent = const []);
  }

  void _onQueryChanged(String value) {
    // Refresh the clear-button visibility immediately.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  // Search is now pushed from the Home header, so it needs a
                  // way back when it's not a bottom tab.
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip: l10n.back,
                      onPressed: () => Navigator.pop(context),
                      icon: FaIcon(
                        FontAwesomeIcons.arrowLeft,
                        size: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppTheme.brandInk.withValues(alpha: 0.75),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      l10n.searchTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: false,
                onChanged: _onQueryChanged,
                onSubmitted: (v) => _remember(v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  // Material icon (not FaIcon): it vertically centers inside
                  // the prefix slot so it lines up with the placeholder text.
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 21,
                    color: AppTheme.brandBlue,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          tooltip: l10n.clear,
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                            setState(() {});
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 13,
                            color: AppTheme.brandBlue,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_query.isNotEmpty) _tabs(context) else _preSearchState(context),
          ],
        ),
      ),
    );
  }

  // ── Pre-search state ───────────────────────────────────────────────────

  Widget _preSearchState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _chipList(
            context,
            title: l10n.recentSearches,
            icon: FontAwesomeIcons.clockRotateLeft,
            items: _recent,
            trailing: _recent.isEmpty
                ? null
                : GestureDetector(
                    onTap: _clearRecent,
                    child: Text(
                      l10n.clear,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandGold,
                      ),
                    ),
                  ),
            onTap: (q) => _submit(q),
          ),
          const SizedBox(height: 24),
          _chipList(
            context,
            title: l10n.suggestedSearches,
            icon: FontAwesomeIcons.lightbulb,
            items: _suggestedSearches,
            onTap: (q) => _submit(q),
          ),
          const SizedBox(height: 24),
          _chipList(
            context,
            title: l10n.trendingSearches,
            icon: FontAwesomeIcons.fireFlameCurved,
            items: _trendingSearches,
            onTap: (q) => _submit(q),
          ),
        ],
      ),
    );
  }

  Widget _chipList(
    BuildContext context, {
    required String title,
    required FaIconData icon,
    required List<String> items,
    required ValueChanged<String> onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            AppLocalizations.of(context).nothingHereYet,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppTheme.brandInk.withValues(alpha: 0.4),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((q) {
              return ActionChip(
                label: Text(q),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandBlue.withValues(alpha: 0.1),
                ),
                onPressed: () => onTap(q),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _submit(String query) {
    _controller.text = query;
    _onQueryChanged(query);
    _remember(query);
    setState(() {});
  }

  // ── Tabs + results ─────────────────────────────────────────────────────

  Widget _tabs(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabChip(_SearchTab.people, l10n.tabPeople),
                  _tabChip(_SearchTab.universities, l10n.tabUniversities),
                  _tabChip(_SearchTab.classrooms, l10n.tabClassrooms),
                  _tabChip(_SearchTab.posts, l10n.tabPosts),
                ],
              ),
            ),
          ),
          if (_tab == _SearchTab.people)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                children: [
                  _roleChip(null, l10n.filterAll),
                  _roleChip('student', l10n.filterStudents),
                  _roleChip('counsellor', l10n.filterCounsellors),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: _results(context),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(_SearchTab tab, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? (isDark
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.brandBlue)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.brandInk.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String? role, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _roleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _roleFilter = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppTheme.brandGold.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? AppTheme.brandGold.withValues(alpha: 0.6)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppTheme.brandGold
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    switch (_tab) {
      case _SearchTab.people:
        return _peopleResults();
      case _SearchTab.universities:
        return _collectionResults(
          collection: 'universities',
          field: 'name',
          icon: FontAwesomeIcons.school,
          emptyTitle:
              AppLocalizations.of(context).noUniversitiesFound,
        );
      case _SearchTab.classrooms:
        return _collectionResults(
          collection: 'classrooms',
          field: 'topic',
          icon: FontAwesomeIcons.chalkboardUser,
          emptyTitle:
              AppLocalizations.of(context).noClassroomsFound,
        );
      case _SearchTab.posts:
        return _postsResults();
    }
  }

  /// People search uses only single-field range constraints (no composite
  /// Firestore index required). The role filter is applied client-side to
  /// avoid an index requirement.
  Stream<QuerySnapshot<Map<String, dynamic>>> _peopleQuery(String q) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: q)
        .where('displayName', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(50)
        .snapshots();
  }

  Widget _peopleResults() {
    final l10n = AppLocalizations.of(context);
    final q = _query;
    if (q.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _peopleQuery(q),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandBlue,
            ),
          );
        }
        final users = (snapshot.data?.docs ?? const [])
            .where((d) => d.id != _me)
            .where((d) =>
                _roleFilter == null || d.data()['role'] == _roleFilter)
            .toList();
        if (users.isEmpty) {
          return _noResults(
            context,
            AppLocalizations.of(context).noPeopleFound(q),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = users[i];
            final data = doc.data();
            final name =
                (data['displayName'] as String?) ?? _nameFromEmail(data);
            final photoUrl = data['photoUrl'] as String?;
            final role = data['role'] as String?;
            return Material(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () {
                  _remember(q);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(uid: doc.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        photoUrl: photoUrl,
                        initials: initialsFor(name),
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : AppTheme.brandInk,
                              ),
                            ),
                            if (role != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                role == 'counsellor'
                                    ? l10n.roleCounsellor
                                    : l10n.roleStudent,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : AppTheme.brandInk.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      FaIcon(
                        FontAwesomeIcons.chevronRight,
                        size: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.35)
                            : AppTheme.brandInk.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _collectionResults({
    required String collection,
    required String field,
    required FaIconData icon,
    required String emptyTitle,
  }) {
    final q = _query;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where(field, isGreaterThanOrEqualTo: q)
          .where(field, isLessThanOrEqualTo: '$q\uf8ff')
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandBlue,
            ),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _noResults(context, '$emptyTitle · $q');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final title =
                (data[field] as String?) ?? (data['name'] as String?) ?? '';
            final subtitle = (data['country'] as String?) ??
                (data['description'] as String?);
            return _resultTile(icon: icon, title: title, subtitle: subtitle);
          },
        );
      },
    );
  }

  Widget _postsResults() {
    final q = _query;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('content', isGreaterThanOrEqualTo: q)
          .where('content', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandBlue,
            ),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _noResults(
            context,
            AppLocalizations.of(context).noPostsFound(q),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            return _resultTile(
              icon: FontAwesomeIcons.feather,
              title: data['authorName'] as String? ?? 'Post',
              subtitle: data['content'] as String?,
            );
          },
        );
      },
    );
  }

  Widget _resultTile({
    required FaIconData icon,
    required String title,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.brandBlue.withValues(alpha: 0.08),
            ),
            child: FaIcon(icon, size: 15, color: AppTheme.brandBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.3,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.brandInk.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noResults(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.tryDifferentKeyword,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nameFromEmail(Map<String, dynamic> data) {
    final email = data['email'] as String? ?? '';
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Orientaa user';
    final words = local
        .split(RegExp(r'[._\- ]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();
    return words.isEmpty ? 'Orientaa user' : words.join(' ');
  }
}
