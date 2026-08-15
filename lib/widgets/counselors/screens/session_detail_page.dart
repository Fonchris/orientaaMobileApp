import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';
import '../widgets/booking_status_badge.dart';
import 'counselor_chat_page.dart';
import 'rating_page.dart';

/// Screen 5 — Post-session confirmation, rating and dispute entry point.
///
/// Shown for a single booking: session facts, a live chat CTA when the
/// window is open, and the status-specific action area:
///   student  -> "Did this session happen?" (Yes -> rate, No -> dispute)
///   counselor-> lightweight confirm (no rating required)
///   disputed -> waiting-for-review card
/// Only Cloud Functions mutate booking state; this screen just calls them.
class SessionDetailPage extends StatefulWidget {
  final String bookingId;
  final String otherName;
  final String? otherPhotoUrl;

  const SessionDetailPage({
    super.key,
    required this.bookingId,
    required this.otherName,
    this.otherPhotoUrl,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final CounselorService _service = CounselorService();
  final CounselorFunctions _functions = CounselorFunctions();

  bool _disputeMode = false;
  final TextEditingController _disputeReason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _disputeReason.dispose();
    super.dispose();
  }

  bool get _isCounselor {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final booking = _lastBooking;
    return booking != null && booking.counselorUid == uid && booking.studentUid != uid;
  }

  Booking? _lastBooking;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await _functions.confirmSession(widget.bookingId);
      if (!mounted) return;
      if (!_isCounselor) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => RatingPage(
              bookingId: widget.bookingId,
              counselorName: widget.otherName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sessionConfirmed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookingCreationError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitDispute() async {
    final reason = _disputeReason.text.trim();
    if (reason.isEmpty || _busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await _functions.raiseDispute(
        bookingId: widget.bookingId,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _disputeMode = false;
        _disputeReason.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.disputeSubmitted)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookingCreationError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).viewBooking,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<Booking?>(
        stream: _service.watchBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
          }
          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }
          _lastBooking = booking;
          return _detailView(context, booking);
        },
      ),
    );
  }

  Widget _detailView(BuildContext context, Booking b) {
    final now = DateTime.now();
    final ended = b.status == BookingStatus.completed ||
        now.isAfter(b.scheduledEnd.add(sessionCompletionGrace));
    final chatOpen = b.status.chatOpen &&
        !now.isBefore(b.scheduledStart.subtract(
          const Duration(minutes: chatUnlockLeadMinutes),
        )) &&
        !ended;

    final showStudentConfirm = !_isCounselor &&
        b.status == BookingStatus.completed &&
        b.studentConfirmedAt == null &&
        b.status != BookingStatus.disputed;
    final showCounselorConfirm = _isCounselor &&
        b.status == BookingStatus.completed &&
        b.counselorConfirmedAt == null &&
        b.status != BookingStatus.disputed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _factsCard(context, b),
        const SizedBox(height: 16),
        if (chatOpen)
          _chatCta(context, b)
        else
          _chatLockedCard(context, b, ended),
        const SizedBox(height: 16),
        if (b.status == BookingStatus.completed &&
            !_isCounselor &&
            b.studentConfirmedAt != null &&
            b.status != BookingStatus.disputed)
          _rateAgainCard(context),
        if (showStudentConfirm) _studentConfirmCard(context),
        if (showCounselorConfirm) _counselorConfirmCard(context),
        if (b.status == BookingStatus.disputed) _disputedCard(context),
        if (b.status == BookingStatus.refunded || b.status == BookingStatus.cancelled)
          _deadCard(context, b),
      ],
    );
  }

  Widget _factsCard(BuildContext context, Booking b) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                photoUrl: widget.otherPhotoUrl,
                initials: counselorInitials(widget.otherName, fallback: '?'),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    const SizedBox(height: 5),
                    BookingStatusBadge(status: b.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _factRow(context, FontAwesomeIcons.calendarDay, '${l10n.dateLabel}: ${DateFormat('EEE, MMM d').format(b.scheduledStart)}'),
          _factRow(context, FontAwesomeIcons.clock, '${l10n.timeLabel}: ${DateFormat('h:mm a').format(b.scheduledStart)} · ${l10n.sessionLengthLabel}'),
          _factRow(context, FontAwesomeIcons.wallet, '${l10n.sessionFeeLabel}: ${b.currency} ${formatAmount(b.feeAmount)}'),
          _factRow(context, FontAwesomeIcons.percent, l10n.platformCommissionLabel),
          _factRow(context, FontAwesomeIcons.moneyBillWave, '${l10n.statusLabel}: ${_paidStatus(l10n, b)}'),
        ],
      ),
    );
  }

  Widget _factRow(BuildContext context, FaIconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 12, color: AppTheme.brandAmber),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppTheme.brandInk.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _paidStatus(AppLocalizations l10n, Booking b) {
    switch (b.status) {
      case BookingStatus.paidOut:
        return '${l10n.bookingStatusPaidOut} · ${b.currency} ${formatAmount(b.counselorPayoutAmount)}';
      case BookingStatus.refunded:
        return l10n.bookingStatusRefunded;
      case BookingStatus.completed:
        return b.bothConfirmed
            ? l10n.sessionConfirmed
            : l10n.bookingStatusCompleted;
      default:
        return '';
    }
  }

  Widget _chatCta(BuildContext context, Booking b) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppTheme.brandYellow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CounselorChatPage(
              bookingId: b.id,
              currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              otherName: widget.otherName,
              otherPhotoUrl: widget.otherPhotoUrl,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.brandYellow.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandYellow,
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.comments, size: 16, color: AppTheme.brandInk),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.joinSessionChat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.sessionChatHint,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : AppTheme.brandInk.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: AppTheme.brandAmber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatLockedCard(BuildContext context, Booking b, bool ended) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = ended
        ? l10n.sessionHasEnded
        : l10n.sessionStartsAt(DateFormat('h:mm a').format(b.scheduledStart));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            ended ? FontAwesomeIcons.lock : FontAwesomeIcons.clock,
            size: 15,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentConfirmCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.didSessionHappen,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 14),
          if (!_disputeMode) ...[
            FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 13),
              label: Text(l10n.yesItHappened),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _disputeMode = true),
              child: Text(
                l10n.noReportProblem,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            TextField(
              controller: _disputeReason,
              maxLines: 3,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.disputeReasonHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _busy ? null : _submitDispute,
              icon: const FaIcon(FontAwesomeIcons.flag, size: 13),
              label: Text(l10n.submitDispute),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _disputeMode = false),
              child: Text(
                l10n.rateLater,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _counselorConfirmCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.confirmSessionTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sessionConfirmed,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppTheme.brandInk.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _confirm,
            icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 13),
            label: Text(l10n.confirmSessionAction),
          ),
        ],
      ),
    );
  }

  Widget _disputedCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const FaIcon(FontAwesomeIcons.flag, size: 22, color: AppTheme.danger),
          const SizedBox(height: 10),
          Text(
            l10n.disputeSubmitted,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppTheme.brandInk.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deadCard(BuildContext context, Booking b) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cancelled = b.status == BookingStatus.cancelled;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        children: [
          FaIcon(
            cancelled ? FontAwesomeIcons.ban : FontAwesomeIcons.rotateLeft,
            size: 22,
            color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            cancelled ? l10n.sessionCancelled : l10n.sessionRefunded,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateAgainCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.brandYellow.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.brandYellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.rateYourSession,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RatingPage(
                  bookingId: widget.bookingId,
                  counselorName: widget.otherName,
                ),
              ),
            ),
            child: Text(l10n.rateYourSession),
          ),
        ],
      ),
    );
  }

}
