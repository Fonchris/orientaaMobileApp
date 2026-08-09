import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';

/// One cohesive statistics strip: Followers / Following / Posts.
///
/// Each stat is individually tappable but the whole group reads as a single
/// profile component (shared card, subtle dividers, consistent touch targets).
class ProfileStats extends StatelessWidget {
  final int followers;
  final int following;
  final int posts;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;
  final VoidCallback onTapPosts;

  const ProfileStats({
    super.key,
    required this.followers,
    required this.following,
    required this.posts,
    required this.onTapFollowers,
    required this.onTapFollowing,
    required this.onTapPosts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : scheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: FontAwesomeIcons.userGroup,
              value: followers,
              label: 'Followers',
              onTap: onTapFollowers,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _StatItem(
              icon: FontAwesomeIcons.userPlus,
              value: following,
              label: 'Following',
              onTap: onTapFollowing,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _StatItem(
              icon: FontAwesomeIcons.newspaper,
              value: posts,
              label: 'Posts',
              onTap: onTapPosts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 34,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppTheme.brandBlue.withValues(alpha: 0.1),
      );
}

class _StatItem extends StatefulWidget {
  final FaIconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scale,
      child: InkWell(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              FaIcon(
                widget.icon,
                size: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppTheme.brandBlue.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.value}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.brandInk.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
