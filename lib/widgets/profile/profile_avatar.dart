import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../google_fonts.dart';

/// Reusable circular profile avatar.
///
/// Shows the user photo when a [photoUrl] exists, otherwise falls back to a
/// brand gradient circle with initials. When [showEditBadge] is true a small
/// camera affordance is overlaid (used on the owner's own profile).
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.size = 64,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandGold, AppTheme.brandBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlue.withValues(alpha: isDark ? 0.4 : 0.25),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : ClipOval(
              child: Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Decode at a resolution close to the rendered size to keep
                // memory low when avatars are listed (posts, followers, chats).
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );

    final avatarWithBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showEditBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1B2333) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: size * 0.16,
                color: AppTheme.brandBlue,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return avatarWithBadge;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatarWithBadge,
    );
  }
}
