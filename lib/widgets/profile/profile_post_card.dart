import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';
import 'profile_avatar.dart';
import 'profile_models.dart';
import 'profile_service.dart';

/// A single post card. Like is a real (persisted) toggle; owner controls
/// (Edit / Delete) are only rendered when [isOwner] is true.
class ProfilePostCard extends StatefulWidget {
  final PostData post;
  final String currentUid;
  final bool isOwner;

  const ProfilePostCard({
    super.key,
    required this.post,
    required this.currentUid,
    required this.isOwner,
  });

  @override
  State<ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<ProfilePostCard> {
  bool _liked = false;
  bool _likeBusy = false;
  late final bool _initialLiked;
  final ProfileService _service = ProfileService();

  @override
  void initState() {
    super.initState();
    _initialLiked = widget.post.likedByUser(widget.currentUid);
    _liked = _initialLiked;
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    final target = !_liked;
    setState(() {
      _liked = target;
      _likeBusy = true;
    });
    try {
      await _service.likePost(
        widget.post.id,
        widget.currentUid,
        liked: target,
      );      } catch (e) {
      if (mounted) {
        setState(() {
          _liked = _initialLiked;
          _likeBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotUpdateLike(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: widget.post.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.editPost,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(hintText: l10n.whatOnYourMind),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == widget.post.content) {
      return;
    }
    try {
      await _service.updatePost(widget.post.id, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotSaveChanges(e.toString()))),
        );
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.deletePostTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(l10n.cannotUndo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deletePost(widget.post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDeletePost(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final post = widget.post;
    final displayLikes =
        (post.likesCount + (_liked ? 1 : 0) - (_initialLiked ? 1 : 0))
            .clamp(0, 1 << 31);

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
          Row(
            children: [
              ProfileAvatar(
                photoUrl: post.authorPhotoUrl,
                initials: initialsFor(post.authorName),
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    Text(
                      relativeTime(post.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppTheme.brandInk.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  tooltip: l10n.postOptions,
                  icon: FaIcon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.brandInk.withValues(alpha: 0.5),
                  ),
                  onSelected: (v) => v == 'edit' ? _edit() : _delete(),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const FaIcon(
                          FontAwesomeIcons.penToSquare,
                          size: 15,
                        ),
                        title: Text(l10n.editPost),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const FaIcon(
                          FontAwesomeIcons.trash,
                          size: 15,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppTheme.brandInk.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                cacheWidth:
                    (MediaQuery.sizeOf(context).width * 0.9).round(),
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFEFF3FA),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      size: 26,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.brandInk.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _countChip(
                icon: FontAwesomeIcons.solidHeart,
                count: displayLikes,
                highlighted: _liked,
                highlightColor: const Color(0xFFE0245E),
                onTap: _toggleLike,
              ),
              const SizedBox(width: 16),
              _countChip(
                icon: FontAwesomeIcons.solidComment,
                count: post.commentsCount,
              ),
              const SizedBox(width: 16),
              _countChip(
                icon: FontAwesomeIcons.retweet,
                count: post.repostsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip({
    required FaIconData icon,
    required int count,
    bool highlighted = false,
    Color? highlightColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppTheme.brandInk.withValues(alpha: 0.45);

    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: highlighted ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: FaIcon(
            icon,
            size: 14,
            color: highlighted ? (highlightColor ?? base) : base,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: highlighted ? (highlightColor ?? base) : base,
          ),
        ),
      ],
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: chip,
      ),
    );
  }
}
