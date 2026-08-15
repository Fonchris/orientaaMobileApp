import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../models/counselor_models.dart';
import 'booking_status_badge.dart';

/// Card for a single booking, used in "My Sessions" and the home dashboard.
/// Shows the other party's avatar, when the session happens, its status and
/// the fee.
class SessionCard extends StatelessWidget {
  final Booking booking;
  final String otherName;
  final String? otherPhotoUrl;
  final VoidCallback onTap;

  const SessionCard({
    super.key,
    required this.booking,
    required this.otherName,
    this.otherPhotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = booking.scheduledStart;
    final day = DateFormat('EEE, MMM d').format(start);
    final time = DateFormat('h:mm a').format(start);

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppTheme.brandLightOutline,
            ),
          ),
          child: Row(
            children: [
              ProfileAvatar(
                photoUrl: otherPhotoUrl,
                initials: _initials(otherName),
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendarDay,
                          size: 10,
                          color: AppTheme.brandAmber,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$day · $time',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.55)
                                : AppTheme.brandInk.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BookingStatusBadge(status: booking.status, compact: true),
                        const SizedBox(width: 8),
                        Text(
                          '${booking.currency} ${_amount(booking.feeAmount)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.brandInk.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 13,
                color: AppTheme.brandGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  String _amount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
