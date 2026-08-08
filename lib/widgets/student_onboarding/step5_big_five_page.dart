import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'personality_question_model.dart';
import 'step_ui.dart';

class Step5BigFivePage extends StatefulWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step5BigFivePage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  @override
  State<Step5BigFivePage> createState() => _Step5BigFivePageState();
}

class _Step5BigFivePageState extends State<Step5BigFivePage> {
  List<PersonalityQuestion> _questions = [];
  bool _isLoading = true;
  bool _usingBundled = false;

  /// Built-in Big Five questions used when the Firestore collection is empty,
  /// unreachable, or the app is offline. Firestore remains the source of truth
  /// when it is available (seed via `personalityQuestions` collection).
  static const List<PersonalityQuestion> _bundledQuestions = [
    // Openness
    PersonalityQuestion(
      id: 'bundled-openness-1',
      text: 'I have a vivid imagination.',
      trait: 'openness',
      reverseScored: false,
      order: 1,
    ),
    PersonalityQuestion(
      id: 'bundled-openness-2',
      text: 'I enjoy abstract ideas and philosophical discussions.',
      trait: 'openness',
      reverseScored: false,
      order: 2,
    ),
    PersonalityQuestion(
      id: 'bundled-openness-3',
      text: 'I appreciate art, beauty, and creative expression.',
      trait: 'openness',
      reverseScored: false,
      order: 3,
    ),
    PersonalityQuestion(
      id: 'bundled-openness-4',
      text: 'I prefer routine and familiar experiences over novelty.',
      trait: 'openness',
      reverseScored: true,
      order: 4,
    ),
    // Conscientiousness
    PersonalityQuestion(
      id: 'bundled-conscientiousness-1',
      text: 'I complete tasks thoroughly and on time.',
      trait: 'conscientiousness',
      reverseScored: false,
      order: 5,
    ),
    PersonalityQuestion(
      id: 'bundled-conscientiousness-2',
      text: 'I like order, regularity, and keeping things organized.',
      trait: 'conscientiousness',
      reverseScored: false,
      order: 6,
    ),
    PersonalityQuestion(
      id: 'bundled-conscientiousness-3',
      text: 'I often forget to put things back in their place.',
      trait: 'conscientiousness',
      reverseScored: true,
      order: 7,
    ),
    PersonalityQuestion(
      id: 'bundled-conscientiousness-4',
      text: 'I work hard to achieve my goals and meet deadlines.',
      trait: 'conscientiousness',
      reverseScored: false,
      order: 8,
    ),
    // Extraversion
    PersonalityQuestion(
      id: 'bundled-extraversion-1',
      text: 'I am the life of the party and enjoy social gatherings.',
      trait: 'extraversion',
      reverseScored: false,
      order: 9,
    ),
    PersonalityQuestion(
      id: 'bundled-extraversion-2',
      text:
          'I enjoy being around people and feel energized by social interaction.',
      trait: 'extraversion',
      reverseScored: false,
      order: 10,
    ),
    PersonalityQuestion(
      id: 'bundled-extraversion-3',
      text:
          'I prefer solitude and quiet environments over busy social settings.',
      trait: 'extraversion',
      reverseScored: true,
      order: 11,
    ),
    // Agreeableness
    PersonalityQuestion(
      id: 'bundled-agreeableness-1',
      text: "I sympathize with others' feelings and show compassion.",
      trait: 'agreeableness',
      reverseScored: false,
      order: 12,
    ),
    PersonalityQuestion(
      id: 'bundled-agreeableness-2',
      text: "I take time to help others even when I'm busy.",
      trait: 'agreeableness',
      reverseScored: false,
      order: 13,
    ),
    PersonalityQuestion(
      id: 'bundled-agreeableness-3',
      text: "I am not particularly interested in other people's problems.",
      trait: 'agreeableness',
      reverseScored: true,
      order: 14,
    ),
    // Neuroticism
    PersonalityQuestion(
      id: 'bundled-neuroticism-1',
      text: 'I often feel stressed and overwhelmed by daily demands.',
      trait: 'neuroticism',
      reverseScored: false,
      order: 15,
    ),
    PersonalityQuestion(
      id: 'bundled-neuroticism-2',
      text: 'I worry about things and tend to be anxious.',
      trait: 'neuroticism',
      reverseScored: false,
      order: 16,
    ),
  ];

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  static const List<String> likertLabels = [
    'Disagree strongly',
    'Disagree a little',
    'Neutral',
    'Agree a little',
    'Agree strongly',
  ];

  static const Map<String, FaIconData> traitIcons = {
    'openness': FontAwesomeIcons.brain,
    'conscientiousness': FontAwesomeIcons.clipboardList,
    'extraversion': FontAwesomeIcons.users,
    'agreeableness': FontAwesomeIcons.handHoldingHeart,
    'neuroticism': FontAwesomeIcons.bolt,
  };

  static const Map<String, String> traitLabels = {
    'openness': 'Openness',
    'conscientiousness': 'Conscientiousness',
    'extraversion': 'Extraversion',
    'agreeableness': 'Agreeableness',
    'neuroticism': 'Neuroticism',
  };

  static const Map<String, Color> traitColors = {
    'openness': Color(0xFF4CAF50),
    'conscientiousness': Color(0xFF2196F3),
    'extraversion': Color(0xFFFF9800),
    'agreeableness': Color(0xFFE91E63),
    'neuroticism': Color(0xFF9C27B0),
  };

  final Map<String, int> _responses = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('personalityQuestions')
          .orderBy('order')
          .get();

      final questions = snapshot.docs.map((doc) {
        return PersonalityQuestion.fromFirestore(doc.id, doc.data());
      }).toList();

      if (!mounted) return;
      if (questions.isEmpty) {
        // Collection exists but has not been seeded yet — use bundled questions.
        setState(() {
          _questions = _bundledQuestions;
          _usingBundled = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _questions = questions;
        _usingBundled = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Firestore unreachable (offline, rules, or not configured) — fall back
      // to the bundled set so the assessment always works.
      debugPrint('Personality questions fallback (Firestore unavailable): $e');
      setState(() {
        _questions = _bundledQuestions;
        _usingBundled = true;
        _isLoading = false;
      });
    }
  }

  void _setResponse(String questionId, int score) {
    setState(() {
      _responses[questionId] = score;
    });
    widget.model.setPersonalityResponse(questionId, score);
  }

  bool get _allAnswered =>
      _questions.isNotEmpty && _responses.length == _questions.length;

  /// Get trait icons for trait grouping.
  FaIconData _traitIcon(String trait) =>
      traitIcons[trait] ?? FontAwesomeIcons.question;
  String _traitLabel(String trait) => traitLabels[trait] ?? trait;
  Color _traitColor(String trait) => traitColors[trait] ?? _brandBlue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _brandBlue),
            const SizedBox(height: 16),
            Text(
              'Loading personality assessment...',
              style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.fileCircleQuestion,
                size: 48,
                color: _brandGold,
              ),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personality assessment questions have not been set up yet.',
                style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(backgroundColor: _brandBlue),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group questions by trait
    final grouped = <String, List<PersonalityQuestion>>{};
    for (final q in _questions) {
      grouped.putIfAbsent(q.trait, () => []).add(q);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepHeroCard(
                  icon: FontAwesomeIcons.faceSmile,
                  title: 'Personality Assessment',
                  subtitle: 'Rate how well each statement describes you.',
                  chips: ['Big Five', 'No wrong answers'],
                ),
                const SizedBox(height: 14),
                // Answer progress
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: _questions.isEmpty
                              ? 0
                              : _responses.length / _questions.length,
                        ),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : _brandBlue.withValues(alpha: 0.1),
                              color: _allAnswered
                                  ? AppTheme.brandGold
                                  : _brandBlue,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_responses.length}/${_questions.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _allAnswered
                            ? AppTheme.brandGold
                            : subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_usingBundled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.brandGold.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppTheme.brandGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.cloudArrowDown,
                          size: 12,
                          color: AppTheme.brandGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Using built-in questions — seed Firestore to load the full set.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.brandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Questions grouped by trait
                ...grouped.entries.map((entry) {
                  final trait = entry.key;
                  final questions = entry.value;
                  final traitColor = _traitColor(trait);
                  final traitIcon = _traitIcon(trait);
                  final traitName = _traitLabel(trait);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trait header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: traitColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: traitColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            FaIcon(traitIcon, color: traitColor, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              traitName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: traitColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Questions for this trait
                      ...questions.asMap().entries.map((qEntry) {
                        final q = qEntry.value;
                        final score = _responses[q.id] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isDark
                                ? const Color(0xFF323232).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.9),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : _brandBlue.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.text,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Likert scale
                              Row(
                                children: List.generate(5, (i) {
                                  final likertScore = i + 1;
                                  final isSelected = score == likertScore;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          _setResponse(q.id, likertScore),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: EdgeInsets.only(
                                          left: i == 0 ? 0 : 4,
                                          right: i == 4 ? 0 : 4,
                                        ),
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: isSelected
                                              ? traitColor
                                              : isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                              : _brandBlue.withValues(
                                                  alpha: 0.04,
                                                ),
                                          border: Border.all(
                                            color: isSelected
                                                ? traitColor
                                                : isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : _brandBlue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$likertScore',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.5,
                                                              )
                                                        : _brandBlue.withValues(
                                                            alpha: 0.5,
                                                          ),
                                                  ),
                                            ),
                                            Text(
                                              likertLabels[i].split(' ').last,
                                              style: GoogleFonts.inter(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w400,
                                                color: isSelected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.8,
                                                      )
                                                    : isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.3,
                                                      )
                                                    : _brandBlue.withValues(
                                                        alpha: 0.3,
                                                      ),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        StepNavBar(
          onBack: widget.onBack,
          onNext: widget.onNext,
          nextLabel: _allAnswered ? 'Continue' : 'Answer all questions',
          nextEnabled: _allAnswered,
          hint: _allAnswered
              ? null
              : 'Answer every question to unlock the next step',
          extra: SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: widget.onNext,
              child: Text(
                "Skip this step — I'll answer later",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
