import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import 'my_sessions_page.dart';

/// Screen 3 — Booking flow.
///
/// Step A: pick a 60-minute slot (server-generated availability).
/// Step B: `createBooking` validates the slot again server-side, computes fee
/// + 10% commission and returns a hosted Flutterwave checkout link.
/// Step C: the link is opened; only the verified webhook may confirm the
/// booking, so the client polls `verifyPayment` (and offers a manual retry)
/// until the server says the money landed. Failure/cancel releases the slot
/// via `cancelBooking` and offers a retry.
class BookingFlowPage extends StatefulWidget {
  final String counselorUid;
  final String counselorName;
  final double rate;
  final String currency;

  const BookingFlowPage({
    super.key,
    required this.counselorUid,
    required this.counselorName,
    required this.rate,
    required this.currency,
  });

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

enum _Stage { selecting, creating, payment, verifying, success, failed }

class _BookingFlowPageState extends State<BookingFlowPage> {
  final CounselorFunctions _functions = CounselorFunctions();

  _Stage _stage = _Stage.selecting;
  List<AvailableSlot> _slots = [];
  bool _slotsLoading = true;
  String? _slotsError;

  DateTime? _selectedDay;
  AvailableSlot? _selectedSlot;

  String? _bookingId;
  double _fee = 0;
  String _currency = 'USD';
  bool _verifying = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _slotsLoading = true;
      _slotsError = null;
    });
    final now = DateTime.now();
    try {
      final slots = await _functions.getAvailableSlots(
        counselorUid: widget.counselorUid,
        rangeStart: now,
        rangeEnd: now.add(const Duration(days: availabilityWindowDays)),
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsLoading = false;
        // Preselect the first day that still has slots.
        if (_selectedDay == null && _days.isNotEmpty) {
          _selectedDay = _days.first;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _slotsLoading = false;
          _slotsError = '$e';
        });
      }
    }
  }

  List<DateTime> get _days {
    final seen = <int>{};
    final days = <DateTime>[];
    for (final s in _slots) {
      if (seen.add(s.dayKey)) {
        days.add(DateTime(s.start.year, s.start.month, s.start.day));
      }
    }
    return days;
  }

  List<AvailableSlot> get _daySlots =>
      _slots.where((s) => s.dayKey == _selectedDay?.millisecondsSinceEpoch).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  // ── Step B/C: create + pay ─────────────────────────────────────────────

  Future<void> _confirmSlot() async {
    final slot = _selectedSlot;
    if (slot == null || _stage != _Stage.selecting) return;
    setState(() => _stage = _Stage.creating);
    try {
      final result = await _functions.createBooking(
        counselorUid: widget.counselorUid,
        scheduledStart: slot.start,
      );
      if (!mounted) return;
      setState(() {
        _bookingId = result.bookingId;
        _fee = result.feeAmount;
        _currency = result.currency;
        _stage = _Stage.payment;
      });
      await _openPaymentLink(result.paymentLink);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.selecting);
      _snack(AppLocalizations.of(context).bookingCreationError);
    }
  }

  Future<void> _openPaymentLink(String link) async {
    final uri = Uri.parse(link);
    final ok = await launchUrl(
      uri,
      mode: Theme.of(context).platform == TargetPlatform.android ||
              Theme.of(context).platform == TargetPlatform.iOS
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
    if (ok) _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _stage == _Stage.payment) _verifyNow();
    });
  }

  Future<void> _verifyNow() async {
    final bookingId = _bookingId;
    if (bookingId == null || _verifying) return;
    setState(() => _verifying = true);
    try {
      final data = await _functions.verifyPayment(bookingId);
      if (!mounted) return;
      final status = data['status'] as String? ?? 'payment_pending';
      setState(() {
        _verifying = false;
        if (status == 'confirmed') {
          _pollTimer?.cancel();
          _stage = _Stage.success;
        } else if (status == 'requested' || status == 'cancelled') {
          // Payment never landed — the webhook (or timeout) reverted it.
          _pollTimer?.cancel();
          _stage = _Stage.failed;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _retry() async {
    final bookingId = _bookingId;
    if (bookingId == null) return;
    setState(() => _stage = _Stage.creating);
    try {
      final result = await _functions.retryPayment(bookingId);
      if (!mounted) return;
      setState(() {
        _fee = result.feeAmount;
        _currency = result.currency;
        _stage = _Stage.payment;
      });
      await _openPaymentLink(result.paymentLink);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.failed);
      _snack(AppLocalizations.of(context).paymentError);
    }
  }

  Future<void> _cancelPayment() async {
    final bookingId = _bookingId;
    _pollTimer?.cancel();
    if (bookingId != null) {
      try {
        await _functions.cancelBooking(bookingId);
      } catch (_) {
        // Best-effort release; the server also times out stale payments.
      }
    }
    if (!mounted) return;
    setState(() {
      _bookingId = null;
      _selectedSlot = null;
      _stage = _Stage.selecting;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).counselorBookingTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (_stage == _Stage.payment) {
              _cancelPayment();
            } else {
              Navigator.of(context).maybePop();
            }
          },
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
        ),
      ),
      body: switch (_stage) {
        _Stage.selecting => _slotSelection(context),
        _Stage.creating => _progressView(context),
        _Stage.payment => _paymentView(context),
        _Stage.verifying => _progressView(context),
        _Stage.success => _successView(context),
        _Stage.failed => _failedView(context),
      },
    );
  }

  Widget _slotSelection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_slotsLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_slotsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 32,
                color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.getAvailableSlotsError,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.brandInk.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadSlots,
                icon: const FaIcon(FontAwesomeIcons.rotate, size: 12),
                label: Text(l10n.refresh),
              ),
            ],
          ),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.calendarXmark,
                size: 32,
                color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noAvailability,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
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

    final daySlots = _daySlots;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              Text(
                l10n.selectDate,
                style: _labelStyle(context),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = _days[i];
                    final selected = _selectedDay != null &&
                        _selectedDay!.millisecondsSinceEpoch == d.millisecondsSinceEpoch;
                    return _dayChip(context, d, selected);
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.selectTimeSlot,
                style: _labelStyle(context),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.selectSlotHint,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.brandInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 10),
              if (daySlots.isEmpty)
                _noSlotsCard(context)
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: daySlots.map((s) {
                    final selected = _selectedSlot?.start == s.start;
                    return _slotChip(context, s, selected);
                  }).toList(),
                ),
            ],
          ),
        ),
        if (_selectedSlot != null) _summaryCard(context),
      ],
    );
  }

  Widget _dayChip(BuildContext context, DateTime d, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = DateTime.now().day == d.day &&
        DateTime.now().month == d.month &&
        DateTime.now().year == d.year;
    return Material(
      color: selected
          ? AppTheme.brandYellow
          : (isDark ? AppTheme.brandCard : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _selectedDay = d;
          _selectedSlot = null;
        }),
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.brandYellow
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandLightOutline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(d),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppTheme.brandInk.withValues(alpha: 0.7)
                      : AppTheme.brandAmber,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${d.day}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.brandInk : (isDark ? Colors.white : AppTheme.brandInk),
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 1),
                Text(
                  AppLocalizations.of(context).today,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppTheme.brandInk.withValues(alpha: 0.6)
                        : AppTheme.brandAmber,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotChip(BuildContext context, AvailableSlot s, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppTheme.brandYellow
          : (isDark ? AppTheme.brandCard : Colors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedSlot = selected ? null : s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.brandYellow
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandLightOutline,
            ),
          ),
          child: Text(
            s.label12h,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.brandInk : (isDark ? Colors.white : AppTheme.brandInk),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noSlotsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            FontAwesomeIcons.calendarXmark,
            size: 15,
            color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.noSlotsForDate,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = _selectedSlot!;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.brandLightOutline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingSummary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow(context, FontAwesomeIcons.userTie, widget.counselorName),
          _summaryRow(
            context,
            FontAwesomeIcons.clock,
            '${DateFormat('EEE, MMM d').format(slot.start)} · ${slot.label12h} · ${l10n.sessionLengthLabel}',
          ),
          _summaryRow(
            context,
            FontAwesomeIcons.wallet,
            '${l10n.sessionFeeLabel}: ${widget.currency} ${_amount(widget.rate)}',
          ),
          _summaryRow(
            context,
            FontAwesomeIcons.percent,
            l10n.platformCommissionLabel,
            note: l10n.commissionNote,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.totalToPay,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
              ),
              Text(
                '${widget.currency} ${_amount(widget.rate)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.currencyNote,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              height: 1.35,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirmSlot,
              icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 14),
              label: Text(l10n.confirmSlot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, FaIconData icon, String text, {String? note}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 12, color: AppTheme.brandAmber),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppTheme.brandInk.withValues(alpha: 0.85),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.35,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : AppTheme.brandInk.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              _stage == _Stage.creating ? l10n.confirmSlot : l10n.paymentProcessing,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.brandInk.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandYellow.withValues(alpha: 0.15),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.moneyBillWave, size: 24, color: AppTheme.brandAmber),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.paymentProcessing,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.chargedAmount}: $_currency ${_amount(_fee)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandGold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.currencyNote,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _verifying ? null : _verifyNow,
                icon: _verifying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 13),
                label: Text(_verifying ? l10n.paymentProcessing : l10n.checkPaymentStatus),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cancelPayment,
              child: Text(
                l10n.cancel,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failedView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.danger.withValues(alpha: 0.12),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.xmark, size: 24, color: AppTheme.danger),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.paymentFailedTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paymentFailedMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _retry,
                icon: const FaIcon(FontAwesomeIcons.rotate, size: 13),
                label: Text(l10n.retryPayment),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cancelPayment,
              child: Text(
                l10n.cancel,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = _selectedSlot;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withValues(alpha: 0.15),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.solidCircleCheck, size: 30, color: AppTheme.success),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.bookingConfirmedTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bookingConfirmedMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            if (slot != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? AppTheme.brandSurface : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.brandLightOutline,
                  ),
                ),
                child: Column(
                  children: [
                    _summaryRow(context, FontAwesomeIcons.userTie, widget.counselorName),
                    _summaryRow(
                      context,
                      FontAwesomeIcons.clock,
                      '${DateFormat('EEE, MMM d').format(slot.start)} · ${slot.label12h} · ${l10n.sessionLengthLabel}',
                    ),
                    _summaryRow(
                      context,
                      FontAwesomeIcons.wallet,
                      '$_currency ${_amount(_fee)} ${l10n.perSession}',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _addToCalendar(),
                icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 13),
                label: Text(l10n.addToCalendar),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const MySessionsPage()),
                    (route) => route.isFirst,
                  );
                },
                child: Text(l10n.goToMySessions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCalendar() async {
    final slot = _selectedSlot;
    if (slot == null) return;
    final title = '$widget.counselorName — Orientaa session';
    final startUtc = slot.start.toUtc();
    final endUtc = slot.end.toUtc();
    final fmt = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&dates=${fmt.format(startUtc)}/${fmt.format(endUtc)}';
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _snack(AppLocalizations.of(context).addToCalendar);
    }
  }

  TextStyle _labelStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.plusJakartaSans(
      fontSize: 14.5,
      fontWeight: FontWeight.w800,
      color: isDark ? Colors.white : AppTheme.brandInk,
    );
  }

  String _amount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
