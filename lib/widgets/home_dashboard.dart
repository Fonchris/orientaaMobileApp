import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'discovery/screens/recommendations_section.dart';
import 'google_fonts.dart';
import 'profile/edit_profile_page.dart';
import 'profile/profile_avatar.dart';
import 'profile/profile_models.dart';
import 'profile/profile_service.dart';
import 'student_onboarding/step_ui.dart';

/// Home tab: "What is relevant to me today?"
///
/// Surfaces recommended universities, an upcoming counsellor session, recent
/// activity and suggested classrooms. Every data-driven section has a proper
/// empty state — nothing fake is rendered when collections are empty.
class HomeDashboard extends StatefulWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenDiscover;
  final VoidCallback onOpenProfile;

  const HomeDashboard({
    super.key,
    required this.onOpenSearch,
    required this.onOpenDiscover,
    required this.onOpenProfile,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final ProfileService _service = ProfileService();
  final GlobalKey<RecommendationsSectionState> _recommendationsKey =
      GlobalKey<RecommendationsSectionState>();
  String _role = 'student';
  String _displayName = '';
  String _email = '';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadBasics();
  }

  Future<void> _loadBasics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('user_role') ?? 'student';
    _email = user.email ?? '';
    try {
      final snap = await _service.fetchUser(user.uid);
      final data = snap.data() ?? const <String, dynamic>{};
      _displayName = (data['displayName'] as String?) ?? _nameFromEmail(_email);
      _photoUrl = data['photoUrl'] as String?;
    } catch (_) {
      _displayName = _nameFromEmail(_email);
    }
    if (mounted) setState(() {});
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'explorer';
    final words = local
        .split(RegExp(r'[._\- ]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();
    return words.isEmpty ? 'explorer' : words.join(' ');
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await _recommendationsKey.currentState?.refresh();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (_role == 'counsellor') ...[
                      _counsellorCard(context),
                      const SizedBox(height: 14),
                      _sessionsSection(context, uid),
                    ] else ...[
                      _recommendationsSection(context),
                      const SizedBox(height: 14),
                      _sessionsSection(context, uid),
                      const SizedBox(height: 14),
                      _classroomsSection(context),
                      const SizedBox(height: 14),
                      _activitySection(context, uid),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _displayName.split(' ').first;
    final firstName = name.isEmpty ? 'explorer' : name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onOpenProfile,
            child: ProfileAvatar(
              photoUrl: _photoUrl,
              initials: initialsFor(_displayName),
              size: 44,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting(l10n)},',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.brandInk.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          _notificationBell(context),
        ],
      ),
    );
  }

  Widget _notificationBell(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<NotificationData>>(
      stream: _service.watchNotifications(uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <NotificationData>[];
        final unread = items.where((n) => !n.read).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: l10n.notifications,
              onPressed: () => _openNotifications(items),
              icon: FaIcon(
                FontAwesomeIcons.bell,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppTheme.brandInk.withValues(alpha: 0.75),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0245E),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? AppTheme.brandDark : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$unread',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openNotifications(List<NotificationData> items) async {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
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
                l10n.notifications,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.bellSlash,
                      size: 28,
                      color: isDark
                          ? AppTheme.brandGold
                          : AppTheme.brandInk.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noNotificationsYet,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : AppTheme.brandInk.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final n = items[i];
                    return ListTile(
                      leading: FaIcon(
                        n.read
                            ? FontAwesomeIcons.circle
                            : FontAwesomeIcons.solidCircle,
                        size: 14,
                        color: n.read
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppTheme.brandInk.withValues(alpha: 0.3))
                            : AppTheme.brandGold,
                      ),
                      title: Text(
                        n.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        n.body,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.brandInk.withValues(alpha: 0.5),
                        ),
                      ),
                      trailing: Text(
                        relativeTime(n.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : AppTheme.brandInk.withValues(alpha: 0.35),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
    if (uid != null) {
      try {
        await _service.markNotificationsRead(uid);
      } catch (_) {}
    }
  }

  // ── Sections ───────────────────────────────────────────────────────────

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.brandInk,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                actionLabel,
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

  /// Recommendations rail backed by the `getRecommendedUniversities` Cloud
  /// Function (see [RecommendationsSection]).
  Widget _recommendationsSection(BuildContext context) {
    return RecommendationsSection(
      key: _recommendationsKey,
      onOpenDiscover: widget.onOpenDiscover,
      onCompleteProfile: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const EditProfilePage(),
        ),
      ),
    );
  }

  Widget _sessionsSection(BuildContext context, String uid) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, title: l10n.counsellorSession),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _role == 'counsellor'
              ? FirebaseFirestore.instance
                  .collection('sessions')
                  .where('counsellorId', isEqualTo: uid)
                  .limit(1)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('sessions')
                  .where('studentId', isEqualTo: uid)
                  .limit(1)
                  .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return _emptyCard(
                context,
                icon: FontAwesomeIcons.calendarCheck,
                title: _role == 'counsellor'
                    ? l10n.noSessionsScheduled
                    : l10n.noUpcomingSessions,
                message: _role == 'counsellor'
                    ? l10n.sessionsCounsellorEmpty
                    : l10n.sessionsStudentEmpty,
              );
            }
            final data = docs.first.data();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.brandYellow,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.video,
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
                          data['title'] as String? ?? 'Counsellor session',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data['dateLabel'] ?? l10n.upcoming} · ${data['status'] ?? l10n.booked}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.brandInk.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 13,
                    color: AppTheme.brandInk,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _classroomsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: l10n.suggestedClassrooms,
          actionLabel: l10n.seeAll,
          onAction: widget.onOpenSearch,
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('classrooms')
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return _emptyCard(
                context,
                icon: FontAwesomeIcons.chalkboardUser,
                title: l10n.noClassroomsYet,
                message: l10n.noClassroomsMessage,
              );
            }
            return Column(
              children: docs
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _classroomCard(context, d.id, d.data()),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _classroomCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.brandYellow.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: AppTheme.brandYellow.withValues(alpha: 0.14),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.chalkboardUser,
                size: 16,
                color: AppTheme.brandAmber,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data['topic'] as String? ?? data['name'] as String? ?? id,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 13,
            color: AppTheme.brandGold,
          ),
        ],
      ),
    );
  }

  Widget _activitySection(BuildContext context, String uid) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, title: l10n.recentActivity),
        const SizedBox(height: 10),
        StreamBuilder<List<NotificationData>>(
          stream: _service.watchNotifications(uid),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <NotificationData>[];
            if (items.isEmpty) {
              return _emptyCard(
                context,
                icon: FontAwesomeIcons.userClock,
                title: l10n.nothingNewYet,
                message: l10n.activityMessage,
              );
            }
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.brandYellow.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: items.take(3).map((n) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleDot,
                          size: 12,
                          color: AppTheme.brandGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            n.body.isEmpty ? n.title : n.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : AppTheme.brandInk.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        Text(
                          relativeTime(n.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.35)
                                : AppTheme.brandInk.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _counsellorCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StepReveal(
      child: Container(
        padding: const EdgeInsets.all(18),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandYellow,
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.userTie,
                  color: AppTheme.brandInk,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Counsellor workspace',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.brandInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Student booking and guidance tools are coming soon.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.55)
                          : AppTheme.brandInk.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required FaIconData icon,
    required String title,
    required String message,
  }) {
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
              : AppTheme.brandBlue.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            icon,
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
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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
}
