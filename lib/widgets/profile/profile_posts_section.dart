import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';
import 'post_composer_page.dart';
import 'profile_models.dart';
import 'profile_post_card.dart';
import 'profile_service.dart';

/// Lists a user's posts (newest first) with a friendly empty state.
class ProfilePostsSection extends StatelessWidget {
  final String uid;
  final bool isOwner;
  final String currentUid;

  const ProfilePostsSection({
    super.key,
    required this.uid,
    required this.isOwner,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<PostData>>(
      stream: ProfileService().watchPosts(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.brandBlue,
              ),
            ),
          );
        }
        final posts = snapshot.data ?? const <PostData>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.brandBlue.withValues(alpha: 0.08),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.newspaper,
                    size: 13,
                    color: AppTheme.brandBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.postsTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.brandBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (posts.isEmpty)
              _EmptyPosts(isOwner: isOwner)
            else
              ...posts.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProfilePostCard(
                    post: p,
                    currentUid: currentUid,
                    isOwner: isOwner,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  final bool isOwner;

  const _EmptyPosts({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.feather,
            size: 30,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandBlue.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            isOwner ? l10n.shareYourJourney : l10n.noPostsYet,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isOwner ? l10n.postsJourneyMessage : l10n.studentNoPostsMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.brandInk.withValues(alpha: 0.5),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PostComposerPage(),
                  ),
                );
              },
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 13),
              label: Text(
                l10n.writeFirstPost,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
