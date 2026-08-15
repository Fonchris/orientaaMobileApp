import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/profile_avatar.dart';
import '../../profile/profile_models.dart' show relativeTime;
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';

/// Admin-only counselor application review screen (read gated by the `admin`
/// custom claim in the Firestore rules — non-admins see the permission error
/// state, exactly like [AdminDisputesPage]).
///
/// Pending + rejected applications are listed newest-first. Tapping a card
/// opens the full application: identity, experience, rate/availability and
/// the sensitive verification documents (government ID + credentials) fetched
/// from the owner+admin-only `counselorPrivate/{uid}` doc. Approve/reject run
/// through the admin-only `reviewCounselorApplication` Cloud Function, which
/// also pushes a notification — the counselor's review screen auto-routes on
/// approval without a re-login.
class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  final CounselorService _service = CounselorService();
  final CounselorFunctions _functions = CounselorFunctions();

  bool _pending = true; // tab: true = Pending, false = Rejected
  String? _reviewingUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminApplicationsTitle,
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
                _tab(context, l10n.adminApplicationsPending, true),
                const SizedBox(width: 10),
                _tab(context, l10n.adminApplicationsRejected, false),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CounselorProfile>>(
              stream: _service.watchApplications(),
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
                final all = snapshot.data ?? const <CounselorProfile>[];
                final list = _pending
                    ? all.where((p) => p.verificationStatus == 'pending').toList()
                    : all.where((p) => p.verificationStatus == 'rejected').toList();
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
                    l10n.adminApplicationsEmpty,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ApplicationCard(
                      profile: list[i],
                      reviewing: _reviewingUid == list[i].uid,
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
    final active = _pending == value;
    return Expanded(
      child: Material(
        color: active
            ? AppTheme.brandYellow
            : (isDark ? AppTheme.brandCard : Colors.white),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _pending = value),
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

  Future<void> _openDetail(BuildContext context, CounselorProfile profile) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ApplicationDetailSheet(
        profile: profile,
        functions: _functions,
        onReviewStart: (uid) {
          if (mounted) setState(() => _reviewingUid = uid);
        },
        onReviewDone: () {
          if (mounted) setState(() => _reviewingUid = null);
        },
      ),
    );
  }
}

/// The application detail sheet: identity, experience, pricing/availability
/// and the sensitive verification documents, with Approve / Reject actions.
class _ApplicationDetailSheet extends StatefulWidget {
  final CounselorProfile profile;
  final CounselorFunctions functions;
  final ValueChanged<String> onReviewStart;
  final VoidCallback onReviewDone;

  const _ApplicationDetailSheet({
    required this.profile,
    required this.functions,
    required this.onReviewStart,
    required this.onReviewDone,
  });

  @override
  State<_ApplicationDetailSheet> createState() => _ApplicationDetailSheetState();
}

class _ApplicationDetailSheetState extends State<_ApplicationDetailSheet> {
  final CounselorService _service = CounselorService();
  Map<String, dynamic>? _private;
  bool _loadingPrivate = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPrivate();
  }

  Future<void> _loadPrivate() async {
    try {
      final data = await _service.fetchPrivateProfile(widget.profile.uid);
      if (mounted) setState(() => _private = data);
    } catch (_) {
      // Documents simply show as unavailable — the profile itself is enough
      // to make an approve/reject decision.
    } finally {
      if (mounted) setState(() => _loadingPrivate = false);
    }
  }

  Future<void> _openDocument(BuildContext context, String? url) async {
    final l10n = AppLocalizations.of(context);
    if (url == null || url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text(l10n.adminOpenDocumentError)),
      );
    }
  }

  Future<void> _review(BuildContext context, String action) async {
    final l10n = AppLocalizations.of(context);
    // Captured before any await so the snackbar works even after the sheet
    // starts its exit animation.
    final messenger = ScaffoldMessenger.of(context);
    final approve = action == 'approve';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve ? l10n.adminApproveTitle : l10n.adminRejectTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          approve ? l10n.adminApproveBody : l10n.adminRejectBody,
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
              backgroundColor: approve ? AppTheme.success : AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? l10n.adminApproveAction : l10n.adminRejectAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    widget.onReviewStart(widget.profile.uid);
    try {
      await widget.functions.reviewApplication(
        uid: widget.profile.uid,
        action: action,
      );
      widget.onReviewDone();
      if (!mounted) return;
      Navigator.of(this.context).pop(); // close the sheet
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminReviewSuccess)),
      );
    } catch (_) {
      widget.onReviewDone();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminReviewError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.profile;
    final pending = p.verificationStatus == 'pending';
    final statusColor = pending ? AppTheme.brandAmber : AppTheme.danger;
    final statusLabel = pending
        ? l10n.adminApplicationsPending
        : l10n.adminApplicationsRejected;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        maxChildSize: 0.92,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    photoUrl: p.photoUrl,
                    initials: _initials(p.displayName),
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.brandInk,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.clock,
                    size: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppTheme.brandInk.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    relativeTime(p.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppTheme.brandInk.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle(l10n.applicationStatus, isDark),
              const SizedBox(height: 8),
              _detailRow(context, l10n.legalNameLabel, p.legalName),
              _detailRow(
                context,
                l10n.institutionLabel,
                p.institution?.isNotEmpty == true ? p.institution! : '—',
              ),
              _detailRow(
                context,
                l10n.yearsExperienceLabel,
                '${p.yearsOfExperience}',
              ),
              _detailRow(
                context,
                l10n.sessionFeeLabel,
                '${p.currency} ${_amount(p.hourlyRate)} ${l10n.perSession}',
              ),
              _detailRow(
                context,
                l10n.languagesTitle,
                p.languages.isEmpty ? '—' : p.languages.join(', '),
              ),
              _detailRow(
                context,
                l10n.specialtiesTitle,
                p.specialties.isEmpty ? '—' : p.specialties.join(', '),
              ),
              const SizedBox(height: 12),
              _sectionTitle(l10n.bioLabel, isDark),
              const SizedBox(height: 6),
              Text(
                p.bio.isEmpty ? '—' : p.bio,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppTheme.brandInk.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(l10n.adminViewDocuments, isDark),
              const SizedBox(height: 8),
              if (_loadingPrivate)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                _documents(context),
              const SizedBox(height: 20),
              if (pending) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _review(context, 'approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 13),
                    label: Text(
                      l10n.adminApproveAction,
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
                    onPressed: _busy
                        ? null
                        : () => _review(context, 'reject'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 13),
                    label: Text(
                      l10n.adminRejectAction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _review(context, 'approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 13),
                    label: Text(
                      l10n.adminApproveAction,
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

  Widget _documents(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idUrl = _private?['idDocumentUrl'] as String?;
    final credentialsUrl = _private?['credentialsUrl'] as String?;
    final none = (idUrl == null || idUrl.isEmpty) &&
        (credentialsUrl == null || credentialsUrl.isEmpty);

    if (none) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
        ),
        child: Text(
          l10n.adminNoDocuments,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : AppTheme.brandInk.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (idUrl != null && idUrl.isNotEmpty)
          _documentButton(
            context,
            FontAwesomeIcons.idCard,
            l10n.adminViewIdDocument,
            () => _openDocument(context, idUrl),
          ),
        if (credentialsUrl != null && credentialsUrl.isNotEmpty)
          _documentButton(
            context,
            FontAwesomeIcons.fileShield,
            l10n.adminViewCredentials,
            () => _openDocument(context, credentialsUrl),
          ),
      ],
    );
  }

  Widget _documentButton(
    BuildContext context,
    FaIconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: FaIcon(icon, size: 16, color: AppTheme.brandAmber),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
        ),
        trailing: const FaIcon(
          FontAwesomeIcons.upRightFromSquare,
          size: 12,
          color: AppTheme.brandAmber,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionTitle(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  String _amount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}

/// A directory-style application card: avatar, name, status badge, submitted
/// time and a rate/specialty summary line.
class _ApplicationCard extends StatelessWidget {
  final CounselorProfile profile;
  final bool reviewing;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.profile,
    required this.reviewing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final p = profile;
    final pending = p.verificationStatus == 'pending';
    final statusColor = pending ? AppTheme.brandAmber : AppTheme.danger;
    final statusLabel = pending
        ? l10n.adminApplicationsPending
        : l10n.adminApplicationsRejected;

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
                photoUrl: p.photoUrl,
                initials: _initials(p.displayName),
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
                            p.displayName,
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
                      '${p.currency} ${_amount(p.hourlyRate)} ${l10n.perSession}'
                      '${p.specialties.isNotEmpty ? ' • ${p.specialties.length} ${l10n.specialtiesTitle}' : ''}',
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
                          relativeTime(p.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : AppTheme.brandInk.withValues(alpha: 0.4),
                          ),
                        ),
                        if (reviewing) ...[
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  String _amount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
