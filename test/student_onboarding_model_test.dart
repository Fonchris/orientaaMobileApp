import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/student_onboarding/personality_question_model.dart';
import 'package:orientaa_mobile_app/widgets/student_onboarding/student_onboarding_model.dart';

void main() {
  group('StudentOnboardingModel.toFirestoreMap', () {
    test('stores every onboarding field used for university matching', () {
      final model = StudentOnboardingModel();

      // Step 1: Identity & Academic Stage
      model.educationLevel = "Bachelor's in progress";
      model.desiredDegreeLevel = "Master's";
      model.toggleFieldOfInterest('Computer Science');
      model.toggleFieldOfInterest('Engineering');
      model.customField = 'Data Science';
      model.setStartDate(9, 2027);

      // Step 2: Location & Logistics
      model.homeCountry = 'Nigeria (West Africa)';
      model.homeCountryCode = 'NG';
      model.homeCity = 'Lagos';
      model.toggleDestination('Canada');
      model.toggleDestination('United Kingdom');
      model.preferredLanguage = 'English';

      // Step 3: Financial
      model.budgetPerYear = 15000;
      model.annualIncome = 10000;
      model.annualIncomeLabel = '\$10,000 – \$20,000';
      model.seekingScholarship = true;

      // Step 4: Self-Assessment
      model.toggleStrength('Leadership');
      model.toggleWeakness('Procrastination');
      model.toggleInterest('Technology & Gaming');
      model.careerGoals = 'Computer Science & IT';

      // Step 5: Big Five Personality
      model.setPersonalityQuestions(const [
        PersonalityQuestion(
          id: 'bundled-openness-1',
          text: 'I have a vivid imagination.',
          trait: 'openness',
          reverseScored: false,
          order: 1,
        ),
      ]);
      model.setPersonalityResponse('bundled-openness-1', 5);

      // Step 6: Optional Extras
      model.gpa = '3.5 / 4.0';
      model.addTestScore(TestScore(testName: 'IELTS', score: '7.5'));
      model.accessibilityNeeds = 'Wheelchair access';

      final map = model.toFirestoreMap();
      final data = map['onboardingData'] as Map<String, dynamic>;

      expect(map['onboardingComplete'], isTrue);
      // Step 1
      expect(data['educationLevel'], "Bachelor's in progress");
      expect(data['desiredDegreeLevel'], "Master's");
      expect(
        data['fieldsOfInterest'],
        containsAll(['Computer Science', 'Engineering']),
      );
      expect(data['customField'], 'Data Science');
      expect(data['startMonth'], 9);
      expect(data['startYear'], 2027);
      expect(data['startLabel'], 'September 2027');
      // Step 2
      expect(data['homeCountry'], 'Nigeria (West Africa)');
      expect(data['homeCountryCode'], 'NG');
      expect(data['homeCity'], 'Lagos');
      expect(
        data['preferredDestinations'],
        containsAll(['Canada', 'United Kingdom']),
      );
      expect(data['preferredLanguage'], 'English');
      // Step 3
      expect(data['budgetPerYear'], 15000);
      expect(data['annualIncome'], 10000);
      expect(data['annualIncomeLabel'], '\$10,000 – \$20,000');
      expect(data['seekingScholarship'], isTrue);
      // Step 4
      expect(data['strengths'], contains('Leadership'));
      expect(data['weaknesses'], contains('Procrastination'));
      expect(data['interests'], contains('Technology & Gaming'));
      expect(data['careerGoals'], 'Computer Science & IT');
      // Step 5
      expect(data['personalityResponses'], {'bundled-openness-1': 5});
      // Step 6
      expect(data['gpa'], '3.5 / 4.0');
      expect(data['testScores'], [
        {'testName': 'IELTS', 'score': '7.5'},
      ]);
      expect(data['accessibilityNeeds'], 'Wheelchair access');
    });

    test('omits skipped optional fields instead of writing null values', () {
      final model = StudentOnboardingModel();
      final data = model.toFirestoreMap()['onboardingData']
          as Map<String, dynamic>;

      // Firestore rejects null field values, so nothing in the map may be null.
      var hasNull = false;
      data.forEach((key, value) {
        if (value == null) hasNull = true;
      });
      expect(hasNull, isFalse);

      // Skipped steps simply leave no key behind.
      expect(data.containsKey('gpa'), isFalse);
      expect(data.containsKey('customField'), isFalse);
      expect(data.containsKey('bigFiveReport'), isFalse);
    });

    test('bigFiveReport aggregates reverse-scored trait averages', () {
      final model = StudentOnboardingModel();
      model.setPersonalityQuestions(const [
        PersonalityQuestion(
          id: 'q1',
          text: 'I enjoy new experiences.',
          trait: 'openness',
          reverseScored: false,
          order: 1,
        ),
        PersonalityQuestion(
          id: 'q2',
          text: 'I prefer routine over novelty.',
          trait: 'openness',
          reverseScored: true,
          order: 2,
        ),
        PersonalityQuestion(
          id: 'q3',
          text: 'I finish tasks on time.',
          trait: 'conscientiousness',
          reverseScored: false,
          order: 3,
        ),
      ]);
      model.setPersonalityResponse('q1', 5);
      // Reverse-scored: a 1 on the scale means strongly agree with the trait,
      // so it is flipped to 5 before averaging.
      model.setPersonalityResponse('q2', 1);
      model.setPersonalityResponse('q3', 3);

      final report = model.bigFiveReport!;
      expect(report['openness']['score'], 5.0);
      expect(report['openness']['level'], 'High');
      expect(report['conscientiousness']['score'], 3.0);
      expect(report['conscientiousness']['level'], 'Moderate');

      // The report is persisted inside onboardingData.
      final stored = model.toFirestoreMap()['onboardingData']
          as Map<String, dynamic>;
      expect(stored['bigFiveReport'], report);
    });

    test('bigFiveReport is null when the assessment is skipped', () {
      final model = StudentOnboardingModel();
      expect(model.bigFiveReport, isNull);

      final data = model.toFirestoreMap()['onboardingData']
          as Map<String, dynamic>;
      expect(data.containsKey('bigFiveReport'), isFalse);
    });
  });
}
