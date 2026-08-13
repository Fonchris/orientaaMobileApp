import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/university_models.dart';
import '../models/tier_policy.dart';
import '../services/recommendation_service.dart';

/// Renders the pre-computed `match_reasons` from the recommendation engine as
/// compact bullet/tag chips ("✓ Within budget", "✓ Matches your field").
///
/// The engine computes these server-side — the client never derives reasons.
///
/// Premium tier: the chips are replaced by a single natural-language sentence
/// from the `explainRecommendation` Cloud Function. If that call fails (or
/// the user isn't premium) the UI falls back to the bullet-point version.
class MatchReasons extends StatefulWidget {
  final RecommendedProgram program;
  final UserTier tier;
  final bool dense; // smaller chips for compact card layouts

  const MatchReasons({
    super.key,
    required this.program,
    required this.tier,
    this.dense = false,
  });

  @override
  State<MatchReasons> createState() => _MatchReasonsState();
}

class _MatchReasonsState extends State<MatchReasons> {
  final RecommendationService _service = RecommendationService();

  String? _llmExplanation;
  bool _triedLlm = false;

  @override
  void initState() {
    super.initState();
    _maybeFetchExplanation();
  }

  @override
  void didUpdateWidget(MatchReasons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.programId != widget.program.programId ||
        oldWidget.tier != widget.tier) {
      _llmExplanation = null;
      _triedLlm = false;
      _maybeFetchExplanation();
    }
  }

  /// Premium-only LLM sentence. Wired now, stubbed server-side (the
  /// `explainRecommendation` function may not be deployed yet) — any failure
  /// falls back to the bullet chips below.
  void _maybeFetchExplanation() {
    if (!TierPolicy.usesLlmExplanation(widget.tier) || _triedLlm) return;
    _triedLlm = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    unawaited(() async {
      final text = await _service.explainRecommendation(
        uid: uid,
        programId: widget.program.programId,
        universityId: widget.program.universityId,
      );
      if (mounted && text != null) {
        setState(() => _llmExplanation = text);
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    if (_llmExplanation != null) {
      return _LlmSentence(text: _llmExplanation!, dense: widget.dense);
    }
    if (widget.program.matchReasons.isEmpty) {
      return const SizedBox.shrink();
    }
    return _ReasonChips(reasons: widget.program.matchReasons, dense: widget.dense);
  }
}

class _ReasonChips extends StatelessWidget {
  final List<String> reasons;
  final bool dense;

  const _ReasonChips({required this.reasons, required this.dense});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark
        ? AppTheme.brandYellow.withValues(alpha: 0.1)
        : AppTheme.brandYellow.withValues(alpha: 0.08);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reasons.take(3).map((reason) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.solidCircleCheck,
                size: 10,
                color: AppTheme.brandAmber,
              ),
              SizedBox(width: dense ? 4 : 6),
              Text(
                reason,
                style: GoogleFonts.inter(
                  fontSize: dense ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppTheme.brandInk.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LlmSentence extends StatelessWidget {
  final String text;
  final bool dense;

  const _LlmSentence({required this.text, required this.dense});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? AppTheme.brandYellow.withValues(alpha: 0.1)
            : AppTheme.brandYellow.withValues(alpha: 0.08),
        border: Border.all(
          color: AppTheme.brandYellow.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            size: 12,
            color: AppTheme.brandAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: dense ? 11.5 : 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.brandInk.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
