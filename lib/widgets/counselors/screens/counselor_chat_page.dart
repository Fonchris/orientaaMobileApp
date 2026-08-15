import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/chat_widgets.dart';
import '../../profile/profile_avatar.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_service.dart';
import 'session_detail_page.dart';

/// Screen 4 — Counselor session chat.
///
/// Real-time listener on `bookings/{id}/messages`. Messaging is locked until
/// within [chatUnlockLeadMinutes] of `scheduledStart` while the booking is
/// confirmed, and locked again after the session (plus the 30-minute grace)
/// ends. Cancelled/refunded bookings show a status card instead of the chat.
class CounselorChatPage extends StatefulWidget {
  final String bookingId;
  final String currentUid;
  final String otherName;
  final String? otherPhotoUrl;

  const CounselorChatPage({
    super.key,
    required this.bookingId,
    required this.currentUid,
    required this.otherName,
    this.otherPhotoUrl,
  });

  @override
  State<CounselorChatPage> createState() => _CounselorChatPageState();
}

class _CounselorChatPageState extends State<CounselorChatPage> {
  final CounselorService _service = CounselorService();
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the messaging window every 30s so the input unlocks right
    // when the 10-minute lead starts and locks when the session ends.
    _lockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _composer.clear();
    try {
      await _service.sendBookingMessage(
        bookingId: widget.bookingId,
        senderUid: widget.currentUid,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        _composer.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).messageSendFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markRead(List<BookingMessage> messages, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    var dirty = false;
    for (final m in messages) {
      if (m.senderUid != uid && m.readAt == null) {
        batch.update(
          _service.bookingMessageRef(widget.bookingId, m.id),
          {'readAt': FieldValue.serverTimestamp()},
        );
        dirty = true;
      }
    }
    if (dirty) await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Booking?>(
      stream: _service.watchBooking(widget.bookingId),
      builder: (context, snapshot) {
        final booking = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        if (booking == null) {
          return const Scaffold(
            body: Center(child: Text('Booking not found')),
          );
        }
        return _chatView(context, booking);
      },
    );
  }

  Widget _chatView(BuildContext context, Booking booking) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dead = booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.refunded;
    final now = DateTime.now();
    final ended = booking.status == BookingStatus.completed ||
        now.isAfter(booking.scheduledEnd.add(sessionCompletionGrace));
    final unlocked = booking.status.chatOpen &&
        !now.isBefore(booking.scheduledStart.subtract(
          const Duration(minutes: chatUnlockLeadMinutes),
        )) &&
        !ended;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              photoUrl: widget.otherPhotoUrl,
              initials: counselorInitials(widget.otherName, fallback: '?'),
              size: 36,
            ),
            const SizedBox(width: 10),
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  _statusBadge(context, booking, now),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsis, size: 16),
            color: isDark ? AppTheme.brandCard : Colors.white,
            onSelected: (v) {
              if (v == 'report') _reportIssue(context, booking);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.flag,
                      size: 13,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.reportIssue,
                      style: GoogleFonts.inter(fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: dead
          ? _statusCard(context, booking)
          : Column(
              children: [
                if (!unlocked) _lockBanner(context, booking, ended),
                Expanded(
                  child: StreamBuilder<List<BookingMessage>>(
                    stream: _service.watchBookingMessages(widget.bookingId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        );
                      }
                      final messages = snapshot.data ?? const <BookingMessage>[];
                      if (messages.isEmpty) {
                        return _emptyState(isDark);
                      }
                      // Fire-and-forget read receipts.
                      _markRead(messages, widget.currentUid);
                      return ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[messages.length - 1 - i];
                          return ChatBubble(
                            text: msg.text,
                            isMine: msg.senderUid == widget.currentUid,
                            sentAt: msg.sentAt,
                          );
                        },
                      );
                    },
                  ),
                ),
                ChatComposer(
                  controller: _composer,
                  sending: _sending,
                  enabled: unlocked,
                  onSend: _send,
                  hintText: l10n.sessionChatHint,
                ),
              ],
            ),
    );
  }

  Widget _statusBadge(BuildContext context, Booking booking, DateTime now) {
    final l10n = AppLocalizations.of(context);
    final ended = booking.status == BookingStatus.completed ||
        now.isAfter(booking.scheduledEnd.add(sessionCompletionGrace));

    final (label, color) = booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.inProgress
        ? (now.isBefore(booking.scheduledStart)
            ? (l10n.sessionUpcomingBadge, AppTheme.success)
            : ended
                ? (l10n.sessionEndedBadge, AppTheme.brandAmber)
                : (l10n.sessionLiveBadge, AppTheme.success))
        : (l10n.sessionEndedBadge, AppTheme.brandAmber);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _lockBanner(BuildContext context, Booking booking, bool ended) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = ended
        ? l10n.sessionHasEnded
        : l10n.sessionStartsAt(
            DateFormat('h:mm a').format(booking.scheduledStart),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? AppTheme.brandSurface : AppTheme.brandYellow.withValues(alpha: 0.14),
      child: Row(
        children: [
          FaIcon(
            ended ? FontAwesomeIcons.lock : FontAwesomeIcons.clock,
            size: 12,
            color: ended ? AppTheme.brandAmber : AppTheme.brandAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.brandInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context, Booking booking) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cancelled = booking.status == BookingStatus.cancelled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              cancelled ? FontAwesomeIcons.ban : FontAwesomeIcons.rotateLeft,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 14),
            Text(
              cancelled ? l10n.sessionCancelled : l10n.sessionRefunded,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.reportIssueStub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.comments,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sessionChatHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportIssue(BuildContext context, Booking booking) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Completed sessions route to the dispute flow; anything else is a stub.
    if (booking.status == BookingStatus.completed) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(
            bookingId: booking.id,
            otherName: widget.otherName,
            otherPhotoUrl: widget.otherPhotoUrl,
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.flag, size: 24, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(
                l10n.reportIssue,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reportIssueStub,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.gotIt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
