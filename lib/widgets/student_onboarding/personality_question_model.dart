/// Represents a Big Five personality question fetched from Firestore.
class PersonalityQuestion {
  final String id;
  final String text;
  final String trait; // openness, conscientiousness, extraversion, agreeableness, neuroticism
  final bool reverseScored;
  final int order;

  const PersonalityQuestion({
    required this.id,
    required this.text,
    required this.trait,
    required this.reverseScored,
    required this.order,
  });

  factory PersonalityQuestion.fromFirestore(String id, Map<String, dynamic> data) {
    return PersonalityQuestion(
      id: id,
      text: data['text'] as String? ?? '',
      trait: data['trait'] as String? ?? '',
      reverseScored: data['reverseScored'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'trait': trait,
      'reverseScored': reverseScored,
      'order': order,
    };
  }
}

/// Represents a user's response to a personality question.
class PersonalityResponse {
  final String questionId;
  final int score; // 1-5 Likert scale

  const PersonalityResponse({
    required this.questionId,
    required this.score,
  });

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'score': score,
      };
}