import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'profile_avatar.dart';
import 'profile_models.dart';
import 'role_badge.dart';

/// Hero header for the profile: avatar, name, role badge, location and a
/// compact, expandable bio. The bio card shows a subtle completion prompt on
/// the owner's own profile when it is empty.
class ProfileHeader extends StatefulWidget {
  final ProfileData profile;
  final bool isOwn;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwn,
    required this.onEditPhoto,
    required this.onEditProfile,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.profile;

    return Column(
      children: [
        _buildHeroCard(context, isDark, p),
        const SizedBox(height: 14),
        _buildBioCard(context, isDark, p),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    ProfileData p,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF243B7A),
                  const Color(0xFF10131D),
                ]
              : [
                  Colors.white,
                  const Color(0xFFEAF1FF),
                  const Color(0xFFFDF8E8),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.brandBlue.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileAvatar(
            photoUrl: p.photoUrl,
            initials: p.initials,
            size: 92,
            showEditBadge: widget.isOwn,
            onTap: widget.isOwn ? widget.onEditPhoto : null,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  p.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
              ),
              if (p.isVerified) ...[
                const SizedBox(width: 7),
                const FaIcon(
                  FontAwesomeIcons.solidCircleCheck,
                  size: 18,
                  color: AppTheme.brandGold,
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          RoleBadge(role: p.role, isVerified: p.isVerified),
          if (p.location != null) ...[
            const SizedBox(height: 11),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 12,
                  color: subtitleColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    p.location!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioCard(BuildContext context, bool isDark, ProfileData p) {
    final scheme = Theme.of(context).colorScheme;
    final bio = p.bio?.trim();

    if (bio == null || bio.isEmpty) {
      if (!widget.isOwn) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? AppTheme.brandGold.withValues(alpha: 0.09)
              : AppTheme.brandGold.withValues(alpha: 0.12),
          border: Border.all(
            color: AppTheme.brandGold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandGold.withValues(alpha: 0.18),
              ),
              child: const FaIcon(
                FontAwesomeIcons.pen,
                size: 13,
                color: AppTheme.brandGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a short bio so students and counsellors can learn more about you.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: widget.onEditProfile,
              style: TextButton.styleFrom(foregroundColor: AppTheme.brandGold),
              child: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandGold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : scheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.brandBlue,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bio,
            maxLines: _bioExpanded ? null : 3,
            overflow: _bioExpanded ? null : TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          if (bio.length > 140)
            GestureDetector(
              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _bioExpanded ? 'Show less' : 'Read more',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandGold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
