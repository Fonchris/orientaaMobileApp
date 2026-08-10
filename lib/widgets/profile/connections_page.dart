import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';
import 'profile_avatar.dart';
import 'profile_models.dart';
import 'profile_page.dart';
import 'profile_service.dart';

/// Followers / Following screen reached from the profile stats.
class ConnectionsPage extends StatefulWidget {
  final String uid;
  final bool initialFollowers;

  const ConnectionsPage({
    super.key,
    required this.uid,
    this.initialFollowers = true,
  });

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  late bool _followers = widget.initialFollowers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _followers ? l10n.statFollowers : l10n.statFollowing,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.statFollowers),
                  icon: const Icon(Icons.people_alt_outlined, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.statFollowing),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                ),
              ],
              selected: {_followers},
              onSelectionChanged: (s) => setState(() => _followers = s.first),
            ),
          ),
          Expanded(
            child: _followers
                ? _buildList(ProfileService().watchFollowers(widget.uid))
                : _buildList(ProfileService().watchFollowing(widget.uid)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Stream<List<ConnectionUser>> stream) {
    return StreamBuilder<List<ConnectionUser>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.brandBlue,
            ),
          );
        }
        final users = snapshot.data ?? const <ConnectionUser>[];
        if (users.isEmpty) {
          return _emptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _userTile(users[i]),
        );
      },
    );
  }

  Widget _userTile(ConnectionUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          if (user.uid == widget.uid) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(uid: user.uid),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ProfileAvatar(
                photoUrl: user.photoUrl,
                initials: initialsFor(user.displayName),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppTheme.brandInk.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.userGroup,
              size: 42,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 14),
            Text(
              _followers ? l10n.noFollowersYet : l10n.notFollowingAnyone,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _followers
                  ? l10n.followersEmptyMessage
                  : l10n.followingEmptyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
