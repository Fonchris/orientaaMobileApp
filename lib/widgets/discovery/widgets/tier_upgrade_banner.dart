import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';

/// Slim banner shown to free-tier users when more matches exist than their
/// tier allows. Tapping it opens a stub upgrade sheet — the monetization
/// flow is a separate module, so this is a placeholder for now.
class TierUpgradeBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const TierUpgradeBanner({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () => _showUpgradeSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? AppTheme.brandYellow.withValues(alpha: 0.12)
                : AppTheme.brandYellow.withValues(alpha: 0.1),
            border: Border.all(
              color: AppTheme.brandYellow.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.crown,
                size: 15,
                color: AppTheme.brandAmber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.brandInk.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Upgrade',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandAmber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stub upgrade bottom sheet. Wire the real paywall/plans flow here later.
Future<void> showUpgradeSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
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
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandYellow,
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.crown,
                  size: 22,
                  color: AppTheme.brandInk,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock Orientaa Pro & Premium',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plans and payments are coming soon. Upgrade will unlock more '
              'matches, folders, comparisons and counselor booking.',
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
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showUpgradeSheet(BuildContext context) => showUpgradeSheet(context);
