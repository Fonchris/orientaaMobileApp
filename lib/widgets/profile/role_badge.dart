import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';

/// Small role chip that communicates the user's role without dominating the
/// profile header. Verified counsellors get a distinct treatment; the check is
/// only rendered when [isVerified] comes from real data.
class RoleBadge extends StatelessWidget {
  final String role; // 'student' | 'counsellor'
  final bool isVerified;

  const RoleBadge({
    super.key,
    required this.role,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCounsellor = role == 'counsellor';

    final label = isCounsellor
        ? (isVerified ? 'Verified Counsellor' : 'Counsellor')
        : 'Student';

    final Color fg;
    final Color bg;
    if (isCounsellor && isVerified) {
      fg = isDark ? const Color(0xFF9BD0FF) : const Color(0xFF075985);
      bg = isDark
          ? const Color(0xFF0E3A5C).withValues(alpha: 0.55)
          : const Color(0xFFE0F2FE);
    } else if (isCounsellor) {
      fg = isDark ? const Color(0xFFB4C6FF) : AppTheme.brandBlue;
      bg = isDark
          ? AppTheme.brandBlue.withValues(alpha: 0.28)
          : AppTheme.brandBlue.withValues(alpha: 0.1);
    } else {
      fg = isDark ? const Color(0xFFFFD667) : const Color(0xFF92400E);
      bg = isDark
          ? AppTheme.brandGold.withValues(alpha: 0.16)
          : AppTheme.brandGold.withValues(alpha: 0.22);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            isCounsellor
                ? FontAwesomeIcons.userTie
                : FontAwesomeIcons.userGraduate,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          if (isCounsellor && isVerified) ...[
            const SizedBox(width: 5),
            const FaIcon(
              FontAwesomeIcons.solidCircleCheck,
              size: 11,
              color: AppTheme.brandGold,
            ),
          ],
        ],
      ),
    );
  }
}
