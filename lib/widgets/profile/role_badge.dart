import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context);
    final label = isCounsellor
        ? (isVerified ? l10n.roleVerifiedCounsellor : l10n.roleCounsellor)
        : l10n.roleStudent;

    final Color fg;
    final Color bg;
    if (isCounsellor && isVerified) {
      // Verified counsellor: gold/amber identity with the check icon.
      fg = isDark ? const Color(0xFFFFD667) : const Color(0xFF92400E);
      bg = isDark
          ? AppTheme.brandGold.withValues(alpha: 0.16)
          : AppTheme.brandGold.withValues(alpha: 0.22);
    } else if (isCounsellor) {
      fg = isDark ? const Color(0xFFFFD667) : AppTheme.brandAmber;
      bg = isDark
          ? AppTheme.brandYellow.withValues(alpha: 0.14)
          : AppTheme.brandYellow.withValues(alpha: 0.12);
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
