import 'package:flutter/foundation.dart';

class StudentOnboardingModel extends ChangeNotifier {
  // ── Step 1: Identity & Academic Stage ──
  String? _educationLevel;
  String? _desiredDegreeLevel;
  final List<String> _fieldsOfInterest = [];
  String? _targetTimeline;

  String? get educationLevel => _educationLevel;
  String? get desiredDegreeLevel => _desiredDegreeLevel;
  List<String> get fieldsOfInterest => List.unmodifiable(_fieldsOfInterest);
  String? get targetTimeline => _targetTimeline;

  set educationLevel(String? v) {
    _educationLevel = v;
    notifyListeners();
  }

  set desiredDegreeLevel(String? v) {
    _desiredDegreeLevel = v;
    notifyListeners();
  }

  void toggleFieldOfInterest(String field) {
    if (_fieldsOfInterest.contains(field)) {
      _fieldsOfInterest.remove(field);
    } else {
      _fieldsOfInterest.add(field);
    }
    notifyListeners();
  }

  set targetTimeline(String? v) {
    _targetTimeline = v;
    notifyListeners();
  }

  bool get step1Valid =>
      _educationLevel != null &&
      _desiredDegreeLevel != null &&
      _fieldsOfInterest.isNotEmpty &&
      _targetTimeline != null;

  // ── Step 2: Location & Logistics ──
  String? _homeCountry;
  String? _homeCity;
  final List<String> _preferredDestinations = [];
  String? _preferredLanguage;

  String? get homeCountry => _homeCountry;
  String? get homeCity => _homeCity;
  List<String> get preferredDestinations =>
      List.unmodifiable(_preferredDestinations);
  String? get preferredLanguage => _preferredLanguage;

  set homeCountry(String? v) {
    _homeCountry = v;
    // Auto-set currency based on home country
    _currency = _currencyForCountry(v);
    notifyListeners();
  }

  set homeCity(String? v) {
    _homeCity = v;
    notifyListeners();
  }

  void toggleDestination(String dest) {
    if (_preferredDestinations.contains(dest)) {
      _preferredDestinations.remove(dest);
    } else {
      _preferredDestinations.add(dest);
    }
    notifyListeners();
  }

  set preferredLanguage(String? v) {
    _preferredLanguage = v;
    notifyListeners();
  }

  bool get step2Valid =>
      _homeCountry != null && _homeCity != null && _homeCity!.trim().isNotEmpty;

  // ── Step 3: Financial ──
  double? _budgetPerYear;
  String? _currency;
  double? _annualIncome;
  bool _seekingScholarship = false;

  double? get budgetPerYear => _budgetPerYear;
  String? get currency => _currency;
  double? get annualIncome => _annualIncome;
  bool get seekingScholarship => _seekingScholarship;

  set budgetPerYear(double? v) {
    _budgetPerYear = v;
    notifyListeners();
  }

  set annualIncome(double? v) {
    _annualIncome = v;
    notifyListeners();
  }

  set seekingScholarship(bool v) {
    _seekingScholarship = v;
    notifyListeners();
  }

  bool get step3Valid => _budgetPerYear != null;

  /// Returns a currency code based on the selected home country.
  String _currencyForCountry(String? country) {
    if (country == null) return 'USD';
    // West Africa
    if (['Nigeria'].contains(country)) return 'NGN';
    if (['Ghana', 'Sierra Leone', 'Liberia', 'Gambia'].contains(country)) {
      return 'GHS'; // approximate; Ghana uses GHS, others use their own
    }
    if (['Senegal', 'Benin', 'Togo', 'Niger', 'Mali', 'Burkina Faso',
             'Guinea', 'Guinea-Bissau', 'Ivory Coast', 'Cape Verde',
             'Mauritania']
        .contains(country)) {
      return 'XOF'; // West African CFA franc
    }
    // East Africa
    if (['Kenya', 'Uganda', 'Tanzania', 'Rwanda', 'Burundi', 'South Sudan',
             'Ethiopia', 'Eritrea', 'Djibouti', 'Somalia', 'Sudan',
             'Comoros', 'Seychelles', 'Mauritius', 'Madagascar', 'Malawi',
             'Zambia', 'Zimbabwe']
        .contains(country)) {
      return 'KES'; // approximate; many different currencies
    }
    // Central Africa
    if (['Cameroon', 'Chad', 'Central African Republic', 'Congo',
             'Gabon', 'Equatorial Guinea', 'São Tomé and Príncipe',
             'Angola', 'DR Congo']
        .contains(country)) {
      return 'XAF'; // Central African CFA franc
    }
    // Southern Africa
    if (['South Africa', 'Botswana', 'Namibia', 'Mozambique', 'Lesotho',
             'Eswatini']
        .contains(country)) {
      return 'ZAR'; // South African rand (used by multiple countries)
    }
    // North Africa
    if (['Egypt', 'Morocco', 'Algeria', 'Tunisia', 'Libya', 'Western Sahara']
        .contains(country)) {
      return 'EGP'; // approximate
    }
    return 'USD';
  }

  // ── Step 4: Self-Assessment ──
  final List<String> _strengths = [];
  final List<String> _weaknesses = [];
  final List<String> _interests = [];
  String? _careerGoals;

  List<String> get strengths => List.unmodifiable(_strengths);
  List<String> get weaknesses => List.unmodifiable(_weaknesses);
  List<String> get interests => List.unmodifiable(_interests);
  String? get careerGoals => _careerGoals;

  void toggleStrength(String s) {
    if (_strengths.contains(s)) {
      _strengths.remove(s);
    } else {
      _strengths.add(s);
    }
    notifyListeners();
  }

  void toggleWeakness(String s) {
    if (_weaknesses.contains(s)) {
      _weaknesses.remove(s);
    } else {
      _weaknesses.add(s);
    }
    notifyListeners();
  }

  void toggleInterest(String s) {
    if (_interests.contains(s)) {
      _interests.remove(s);
    } else {
      _interests.add(s);
    }
    notifyListeners();
  }

  set careerGoals(String? v) {
    _careerGoals = v;
    notifyListeners();
  }

  bool get step4Valid =>
      _strengths.isNotEmpty &&
      _weaknesses.isNotEmpty &&
      _interests.isNotEmpty &&
      _careerGoals != null &&
      _careerGoals!.trim().isNotEmpty;

  // ── Step 5: Optional Extras ──
  String? _gpa;
  final List<TestScore> _testScores = [];
  String? _accessibilityNeeds;

  String? get gpa => _gpa;
  List<TestScore> get testScores => List.unmodifiable(_testScores);
  String? get accessibilityNeeds => _accessibilityNeeds;

  set gpa(String? v) {
    _gpa = v;
    notifyListeners();
  }

  void addTestScore(TestScore score) {
    _testScores.add(score);
    notifyListeners();
  }

  void removeTestScore(int index) {
    _testScores.removeAt(index);
    notifyListeners();
  }

  set accessibilityNeeds(String? v) {
    _accessibilityNeeds = v;
    notifyListeners();
  }

  // Always valid — step 5 is optional
  bool get step5Valid => true;

  /// Converts the model to a Map for Firestore.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'onboardingComplete': true,
      'onboardingData': {
        // Step 1
        'educationLevel': _educationLevel,
        'desiredDegreeLevel': _desiredDegreeLevel,
        'fieldsOfInterest': _fieldsOfInterest,
        'targetTimeline': _targetTimeline,
        // Step 2
        'homeCountry': _homeCountry,
        'homeCity': _homeCity,
        'preferredDestinations': _preferredDestinations,
        'preferredLanguage': _preferredLanguage,
        // Step 3
        'budgetPerYear': _budgetPerYear,
        'currency': _currency,
        'annualIncome': _annualIncome,
        'seekingScholarship': _seekingScholarship,
        // Step 4
        'strengths': _strengths,
        'weaknesses': _weaknesses,
        'interests': _interests,
        'careerGoals': _careerGoals,
        // Step 5
        'gpa': _gpa,
        'testScores': _testScores.map((ts) => ts.toMap()).toList(),
        'accessibilityNeeds': _accessibilityNeeds,
      },
    };
  }
}

/// Represents a standardized test score (e.g., WAEC, IELTS, TOEFL, SAT).
class TestScore {
  final String testName;
  final String score;

  TestScore({required this.testName, required this.score});

  Map<String, dynamic> toMap() => {
        'testName': testName,
        'score': score,
      };
}