import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../../profile/profile_models.dart' show relativeTime;
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';

/// Admin-only dispute review screen (read gated by the `admin` custom claim
/// in the Firestore rules — non-admins see the permission error state).
///
/// Open disputes can be resolved two ways, both executed by the admin-only
/// `resolveDispute` Cloud Function:
///  - "Pay the counselor"  -> dispute rejected, payout transferred.
///  - "Refund the student" -> dispute upheld, Flutterwave refund.
class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage> {
  final CounselorService _service = CounselorService();
  final CounselorFunctions _functions = CounselorFunctions();

  bool _open = true; // tab: true = Open, false = Resolved
  String? _resolvingBookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminDisputesTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                _tab(context, l10n.adminDisputesOpen, true),
                const SizedBox(width: 10),
                _tab(context, l10n.adminDisputesResolved, false),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DisputeEntry>>(
              stream: _service.watchDisputes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  );
                }
                if (snapshot.hasError) {
                  return _centered(
                    context,
                    FaIcon(
                      FontAwesomeIcons.shieldHalved,
                      size: 36,
                      color: isDark
                          ? AppTheme.brandGold
                          : AppTheme.brandInk.withValues(alpha: 0.45),
                    ),
                    l10n.adminOnlyError,
                  );
                }
                final all = snapshot.data ?? const <DisputeEntry>[];
                final list = _open
                    ? all.where((d) => d.isOpen).toList()
                    : all.where((d) => !d.isOpen).toList();
                if (list.isEmpty) {
                  return _centered(
                    context,
                    FaIcon(
                      FontAwesomeIcons.inbox,
                      size: 36,
                      color: isDark
                          ? AppTheme.brandGold
                          : AppTheme.brandInk.withValues(alpha: 0.45),
                    ),
                    l10n.adminDisputesEmpty,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DisputeCard(
                      entry: list[i],
                      resolving: _resolvingBookingId == list[i].bookingId,
                      onTap: () => _openDetail(context, list[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, bool value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _open == value;
    return Expanded(
      child: Material(
        color: active
            ? AppTheme.brandYellow
            : (isDark ? AppTheme.brandCard : Colors.white),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _open = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppTheme.brandYellow
                    : isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.brandLightOutline,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active
                    ? AppTheme.brandInk
                    : isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.brandInk,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _centered(BuildContext context, Widget icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
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

  Future<void> _openDetail(BuildContext context, DisputeEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  FaIcon(
                    entry.isOpen
                        ? FontAwesomeIcons.triangleExclamation
                        : entry.resolvedAsPaidOut
                            ? FontAwesomeIcons.solidCircleCheck
                            : FontAwesomeIcons.rotateLeft,
                    size: 18,
                    color: entry.isOpen
                        ? AppTheme.danger
                        : entry.resolvedAsPaidOut
                            ? AppTheme.success
                            : AppTheme.brandAmber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.disputeResolveTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(
                context,
                l10n.disputeScheduledLabel,
                entry.scheduledStart == null
                    ? '—'
                    : DateFormat('MMM d, y • h:mm a')
                        .format(entry.scheduledStart!.toLocal()),
              ),
              _detailRow(
                context,
                l10n.disputeReasonLabel,
                entry.reason,
                multiline: true,
              ),
              _detailRow(
                context,
                '${entry.counselorName} ↔ ${entry.studentName}',
                '${entry.currency} ${formatAmount(entry.feeAmount)}',
              ),
              const SizedBox(height: 16),
              if (entry.isOpen) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _resolvingBookingId != null
                        ? null
                        : () => _resolve(ctx, entry, outcome: 'paid_out'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.sackDollar, size: 13),
                    label: Text(
                      l10n.resolvePayCounselor,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _resolvingBookingId != null
                        ? null
                        : () => _resolve(ctx, entry, outcome: 'refunded'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 13),
                    label: Text(
                      l10n.resolveRefundStudent,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool multiline = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(
    BuildContext sheetContext,
    DisputeEntry entry, {
    required String outcome,
  }) async {
    final l10n = AppLocalizations.of(context);
    final pay = outcome == 'paid_out';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.disputeResolveTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          pay ? l10n.resolvePayBody : l10n.resolveRefundBody,
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: pay ? AppTheme.success : AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(pay ? l10n.resolvePayCounselor : l10n.resolveRefundStudent),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resolvingBookingId = entry.bookingId);
    try {
      await _functions.resolveDispute(
        bookingId: entry.bookingId,
        outcome: outcome,
      );
      if (!mounted || !sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resolveSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resolveError)),
      );
    } finally {
      if (mounted) setState(() => _resolvingBookingId = null);
    }
  }

}

class _DisputeCard extends StatelessWidget {
  final DisputeEntry entry;
  final bool resolving;
  final VoidCallback onTap;

  const _DisputeCard({
    required this.entry,
    required this.resolving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final statusColor = entry.isOpen
        ? AppTheme.danger
        : entry.resolvedAsPaidOut
            ? AppTheme.success
            : AppTheme.brandAmber;
    final statusLabel = entry.isOpen
        ? l10n.adminDisputesOpen
        : entry.resolvedAsPaidOut
            ? l10n.resolvePayCounselor
            : l10n.resolveRefundStudent;

    return Material(
      color: isDark ? AppTheme.brandSurface : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppTheme.brandLightOutline,
            ),
          ),
          child: Row(
            children: [
              ProfileAvatar(
                photoUrl: entry.counselorPhotoUrl,
                initials: counselorInitials(entry.counselorName, fallback: '?'),
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.counselorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.brandInk,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: statusColor.withValues(alpha: 0.14),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.currency} ${formatAmount(entry.feeAmount)} • '
                      '${entry.studentName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.brandInk.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppTheme.brandInk.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.clock,
                          size: 10,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : AppTheme.brandInk.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          relativeTime(entry.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : AppTheme.brandInk.withValues(alpha: 0.4),
                          ),
                        ),
                        if (resolving) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppTheme.brandInk.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
