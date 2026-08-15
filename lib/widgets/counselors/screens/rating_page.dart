import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../services/counselor_functions.dart';

/// Star rating screen (1–5) with optional review text. Writes
/// `ratings/{bookingId}` via the `submitRating` Cloud Function, which also
/// recalculates the counselor's ratingAverage/ratingCount in a transaction.
class RatingPage extends StatefulWidget {
  final String bookingId;
  final String counselorName;

  const RatingPage({
    super.key,
    required this.bookingId,
    required this.counselorName,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final CounselorFunctions _functions = CounselorFunctions();
  final TextEditingController _review = TextEditingController();

  int _stars = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _functions.submitRating(
        bookingId: widget.bookingId,
        stars: _stars,
        reviewText: _review.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).thanksForRating)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).paymentError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.rateYourSession,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.counselorName,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.rateHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return IconButton(
                  onPressed: () => setState(() => _stars = i + 1),
                  icon: FaIcon(
                    filled ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                    size: 30,
                    color: filled
                        ? AppTheme.brandAmber
                        : isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.brandInk.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _review,
              maxLines: 4,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.reviewOptionalHint,
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _stars == 0 || _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(l10n.submitRating),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n.rateLater,
                style: GoogleFonts.inter(fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
