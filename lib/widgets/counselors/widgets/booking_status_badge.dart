import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/counselor_models.dart';

/// Colored pill showing a booking's lifecycle status, used on session cards,
/// chat headers and detail pages.
class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool compact;

  const BookingStatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color, icon) = _style(l10n);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            FaIcon(icon, size: compact ? 8 : 9, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, FaIconData?) _style(AppLocalizations l10n) {
    switch (status) {
      case BookingStatus.requested:
        return (l10n.bookingStatusRequested, AppTheme.info, FontAwesomeIcons.clock);
      case BookingStatus.paymentPending:
        return (l10n.bookingStatusPaymentPending, AppTheme.orange, FontAwesomeIcons.wallet);
      case BookingStatus.confirmed:
        return (l10n.bookingStatusConfirmed, AppTheme.success, FontAwesomeIcons.solidCircleCheck);
      case BookingStatus.inProgress:
        return (l10n.bookingStatusInProgress, AppTheme.violet, FontAwesomeIcons.bolt);
      case BookingStatus.completed:
        return (l10n.bookingStatusCompleted, AppTheme.brandAmber, FontAwesomeIcons.solidCircleCheck);
      case BookingStatus.cancelled:
        return (l10n.bookingStatusCancelled, AppTheme.danger, FontAwesomeIcons.ban);
      case BookingStatus.disputed:
        return (l10n.bookingStatusDisputed, AppTheme.danger, FontAwesomeIcons.triangleExclamation);
      case BookingStatus.refunded:
        return (l10n.bookingStatusRefunded, AppTheme.info, FontAwesomeIcons.rotateLeft);
      case BookingStatus.paidOut:
        return (l10n.bookingStatusPaidOut, AppTheme.success, FontAwesomeIcons.moneyBillWave);
    }
  }
}
