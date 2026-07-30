import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_onboarding_model.dart';
import 'personality_question_model.dart';

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
  String? _error;

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
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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

  bool get _allAnswered => _questions.isNotEmpty && _responses.length == _questions.length;

  /// Get trait icons for trait grouping.
  FaIconData _traitIcon(String trait) => traitIcons[trait] ?? FontAwesomeIcons.question;
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

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.triangleExclamation, size: 48, color: _brandGold),
              const SizedBox(height: 16),
              Text(
                'Could not load questions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again.',
                style: GoogleFonts.inter(fontSize: 14, color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchQuestions();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _brandBlue),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onNext,
                child: Text(
                  'Skip this step',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtitleColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
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
              FaIcon(FontAwesomeIcons.fileCircleQuestion, size: 48, color: _brandGold),
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
                child: const Text('Continue', style: TextStyle(color: Colors.white)),
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _brandBlue.withValues(alpha: 0.1),
                ),
                child: FaIcon(FontAwesomeIcons.faceSmile, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personality Assessment',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Rate how well each statement describes you',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_responses.length} of ${_questions.length} answered',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _allAnswered ? _brandBlue : subtitleColor,
            ),
          ),
          const SizedBox(height: 20),

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: traitColor.withValues(alpha: 0.1),
                    border: Border.all(color: traitColor.withValues(alpha: 0.2)),
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
                                onTap: () => _setResponse(q.id, likertScore),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    left: i == 0 ? 0 : 4,
                                    right: i == 4 ? 0 : 4,
                                  ),
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: isSelected
                                        ? traitColor
                                        : isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : _brandBlue.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: isSelected
                                          ? traitColor
                                          : isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : _brandBlue.withValues(alpha: 0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$likertScore',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : isDark
                                                  ? Colors.white.withValues(alpha: 0.5)
                                                  : _brandBlue.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      Text(
                                        likertLabels[i].split(' ').last,
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : isDark
                                                  ? Colors.white.withValues(alpha: 0.3)
                                                  : _brandBlue.withValues(alpha: 0.3),
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

          // Navigation buttons
          Row(
            children: [
              if (widget.onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : _brandBlue.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : _brandBlue.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _allAnswered ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : _brandBlue.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: _allAnswered ? 4 : 0,
                      shadowColor: _brandBlue.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      _allAnswered ? 'Continue' : 'Answer all questions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _allAnswered ? Colors.white : subtitleColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}