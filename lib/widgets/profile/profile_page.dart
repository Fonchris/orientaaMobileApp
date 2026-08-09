import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import '../student_onboarding/step_ui.dart';
import 'academic_summary_card.dart';
import 'chat_page.dart';
import 'connections_page.dart';
import 'edit_profile_page.dart';
import 'messaging_service.dart';
import 'profile_header.dart';
import 'profile_models.dart';
import 'profile_posts_section.dart';
import 'profile_service.dart';
import 'profile_stats.dart';
import 'settings_page.dart';

/// Full profile experience.
///
/// With [uid] == null (or equal to the current user) this renders the signed-in
/// user's profile with owner controls. With another [uid] it renders that
/// user's public profile with Follow / Message actions.
class ProfilePage extends StatefulWidget {
  final String? uid;

  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _service = ProfileService();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _postsKey = GlobalKey();
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  late final String _myUid;
  late final String _myEmail;
  late final String _viewingUid;
  late final bool _isOwn;
  String _fallbackRole = 'student';
  String _myDisplayName = '';
  String? _myPhotoUrl;
  bool? _isFollowing;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _myEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    _viewingUid = widget.uid ?? _myUid;
    _isOwn = widget.uid == null || widget.uid == _myUid;
    _userStream = _service.watchUser(_viewingUid);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'student';
    _fallbackRole = role;
    if (_isOwn) {
      // Read my photo (for the remove-photo action) and best-effort persist
      // the role so other users can see it.
      try {
        final snap = await _service.fetchUser(_myUid);
        final data = snap.data();
        if (data != null) {
          _myPhotoUrl = data['photoUrl'] as String?;
          if (data['role'] == null) {
            await _service.saveProfileFields(_myUid, {'role': role});
          }
        }
      } catch (_) {}
    } else {
      // Load my own name/photo for the follow action and check follow state.
      try {
        final snap = await _service.fetchUser(_myUid);
        final data = snap.data() ?? const <String, dynamic>{};
        _myDisplayName =
            (data['displayName'] as String?) ?? _nameFromEmail(_myEmail);
        _myPhotoUrl = data['photoUrl'] as String?;
        _isFollowing = await _service.isFollowing(_myUid, _viewingUid);
      } catch (_) {
        _isFollowing = false;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Orientaa explorer';
    final words = local
        .split(RegExp(r'[._\- ]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();
    return words.isEmpty ? 'Orientaa explorer' : words.join(' ');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _userStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _ProfileSkeleton();
                  }
                  if (snapshot.hasError) {
                    return _errorState(context, snapshot.error.toString());
                  }
                  final data = snapshot.data?.data();
                  if (data == null) {
                    return _errorState(context, 'profile-not-found');
                  }
                  final profile = ProfileData.fromSnapshot(
                    snapshot.data!,
                    email: _myEmail,
                    fallbackRole: _isOwn ? _fallbackRole : 'student',
                  );
                  final savedUniversities =
                      (data['savedUniversitiesCount'] as num?)?.toInt() ?? 0;
                  return _content(context, profile, savedUniversities);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: FaIcon(
                FontAwesomeIcons.arrowLeft,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandBlue,
              ),
            ),
          Expanded(
            child: Text(
              _isOwn ? 'My Profile' : 'Profile',
              textAlign: canPop ? TextAlign.center : TextAlign.start,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (_isOwn)
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandBlue,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ProfileData profile,
    int savedUniversities,
  ) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          StepReveal(
            child: ProfileHeader(
              profile: profile,
              isOwn: _isOwn,
              onEditPhoto: _isOwn ? _openPhotoSheet : () {},
              onEditProfile: _openEditProfile,
            ),
          ),
          const SizedBox(height: 14),
          ProfileStats(
            followers: profile.followersCount,
            following: profile.followingCount,
            posts: profile.postsCount,
            onTapFollowers: () => _openConnections(profile, true),
            onTapFollowing: () => _openConnections(profile, false),
            onTapPosts: _scrollToPosts,
          ),
          const SizedBox(height: 14),
          _actions(profile),
          const SizedBox(height: 14),
          AcademicSummaryCard(
            profile: profile,
            savedUniversities: savedUniversities,
            onEditProfile: _openEditProfile,
            onViewDetails: () => _showDetailsSheet(profile),
            onBrowseUniversities: () => _toast(
              'University discovery is coming to the Search tab soon.',
            ),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _postsKey,
            child: ProfilePostsSection(
              uid: profile.uid,
              isOwner: _isOwn,
              currentUid: _myUid,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Widget _actions(ProfileData profile) {
    if (_isOwn) {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: FontAwesomeIcons.penToSquare,
              label: 'Edit Profile',
              filled: true,
              onTap: _openEditProfile,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: FontAwesomeIcons.shareNodes,
              label: 'Share',
              filled: false,
              onTap: _shareProfile,
            ),
          ),
        ],
      );
    }

    final following = _isFollowing ?? false;
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: following
                ? FontAwesomeIcons.check
                : FontAwesomeIcons.userPlus,
            label: following ? 'Following' : 'Follow',
            filled: !following,
            busy: _followBusy,
            onTap: _isFollowing == null || _followBusy ? null : _toggleFollow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: FontAwesomeIcons.solidMessage,
            label: 'Message',
            filled: false,
            onTap: () => _openChat(profile),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required FaIconData icon,
    required String label,
    required bool filled,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: Material(
        color: filled
            ? (isDark ? scheme.primary : AppTheme.brandBlue)
            : isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        icon,
                        size: 13,
                        color: filled
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.brandBlue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: filled
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.brandBlue),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  Future<void> _openConnections(ProfileData profile, bool followers) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectionsPage(
          uid: profile.uid,
          initialFollowers: followers,
        ),
      ),
    );
  }

  Future<void> _openChat(ProfileData profile) async {
    final allowed = await MessagingService().canMessage(_myUid, profile.uid);
    if (!allowed) {
      _toast('This user only accepts messages from people they follow.');
      return;
    }
    final conversationId = await MessagingService().ensureConversation(
      myUid: _myUid,
      otherUid: profile.uid,
      myProfile: {
        'displayName': _myDisplayName.isEmpty
            ? _nameFromEmail(_myEmail)
            : _myDisplayName,
        'photoUrl': _myPhotoUrl,
      },
      otherProfile: {
        'displayName': profile.displayName,
        'photoUrl': profile.photoUrl,
      },
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          currentUid: _myUid,
          otherUid: profile.uid,
          otherName: profile.displayName,
          otherPhotoUrl: profile.photoUrl,
          otherRole: profile.role,
        ),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    final target = !(_isFollowing ?? false);
    setState(() {
      _isFollowing = target;
      _followBusy = true;
    });
    try {
      if (target) {
        await _service.follow(
          targetUid: _viewingUid,
          myUid: _myUid,
          myName: _myDisplayName.isEmpty ? _nameFromEmail(_myEmail) : _myDisplayName,
          myPhotoUrl: _myPhotoUrl,
        );
      } else {
        await _service.unfollow(targetUid: _viewingUid, myUid: _myUid);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !target);
        _toast('Could not update follow status: $e');
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _shareProfile() async {
    final uid = _isOwn ? _myUid : _viewingUid;
    await Clipboard.setData(ClipboardData(text: 'orientaa://profile/$uid'));
    _toast('Profile link copied to clipboard');
  }

  void _scrollToPosts() {
    final ctx = _postsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _openPhotoSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF10131D) : Colors.white,
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
            const SizedBox(height: 16),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.camera,
                color: AppTheme.brandBlue,
              ),
              title: Text(
                'Change profile photo',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Photo upload is coming soon',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toast(
                  'Photo upload is coming soon — you will be able to pick and crop from your gallery.',
                );
              },
            ),
            if (_isOwn && _myPhotoUrl != null)
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.trash,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'Remove photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _service.saveProfileFields(_myUid, {
                      'photoUrl': FieldValue.delete(),
                    });
                    _myPhotoUrl = null;
                    if (mounted) setState(() {});
                    _toast('Profile photo removed');
                  } catch (e) {
                    _toast('Could not remove photo: $e');
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(ProfileData profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF10131D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) => _DetailsSheet(
            profile: profile,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notFound = error == 'profile-not-found';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 44,
              color: AppTheme.brandGold,
            ),
            const SizedBox(height: 14),
            Text(
              notFound ? 'Profile not found' : 'Could not load this profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              notFound
                  ? 'This user may have deleted their account.'
                  : error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
            if (!notFound) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _userStream = _service.watchUser(_viewingUid);
                  });
                },
                icon: const FaIcon(FontAwesomeIcons.rotate, size: 13),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Full onboarding details bottom sheet ────────────────────────────────

class _DetailsSheet extends StatelessWidget {
  final ProfileData profile;
  final ScrollController scrollController;

  const _DetailsSheet({
    required this.profile,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final o = profile.onboardingData;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Full profile details',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
        ),
        const SizedBox(height: 18),
        _section(context, 'Academic', [
          _row(context, 'Education level', o['educationLevel']),
          _row(context, 'Desired degree', o['desiredDegreeLevel']),
          _row(context, 'Fields of interest', _list(o['fieldsOfInterest'])),
          _row(context, 'Planned start', o['startLabel']),
        ]),
        const SizedBox(height: 14),
        _section(context, 'Location & Logistics', [
          _row(context, 'Home', _home(o)),
          _row(context, 'Study destinations', _list(o['preferredDestinations'])),
          _row(context, 'Language of instruction', o['preferredLanguage']),
        ]),
        const SizedBox(height: 14),
        _section(context, 'Financial', [
          _row(context, 'Annual budget', _budget(o)),
          _row(context, 'Household income', o['annualIncomeLabel']),
          _row(
            context,
            'Scholarships',
            o['seekingScholarship'] == true
                ? 'Seeking scholarship info'
                : 'Not currently seeking',
          ),
        ]),
        const SizedBox(height: 14),
        _section(context, 'Assessment', [
          _row(context, 'Career goal', o['careerGoals']),
          _row(context, 'Strengths', _list(o['strengths'])),
          _row(context, 'Interests', _list(o['interests'])),
          _row(context, 'GPA', o['gpa']),
          _row(context, 'Test scores', _scores(o['testScores'])),
        ]),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
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
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
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

  String? _list(Object? v) =>
      v is List && v.isNotEmpty ? v.join(', ') : null;

  String? _home(Map<String, dynamic> o) {
    final c = o['homeCountry'];
    final city = o['homeCity'];
    if (c == null && city == null) return null;
    return [city, c]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
  }

  String? _budget(Map<String, dynamic> o) {
    final budget = o['budgetPerYear'];
    if (budget == null) return null;
    final amount = budget is num ? budget : 0;
    final formatted = amount >= 1000
        ? '\$${(amount / 1000).toStringAsFixed(0)}k'
        : '\$${amount.toStringAsFixed(0)}';
    final currency = o['currency'];
    return currency != null ? '$currency $formatted' : formatted;
  }

  String? _scores(Object? v) {
    if (v is! List || v.isEmpty) return null;
    return v
        .map((e) => e is Map ? '${e['testName']}: ${e['score']}' : e.toString())
        .join(' · ');
  }
}

// ── Skeleton ────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE6EBF5);

    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: base,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: base,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: base,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: base,
            ),
          ),
        ],
      ),
    );
  }
}
