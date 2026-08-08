import 'package:flutter/foundation.dart';

class StudentOnboardingModel extends ChangeNotifier {
  // ── Step 1: Identity & Academic Stage ──
  String? _educationLevel;
  String? _desiredDegreeLevel;
  final List<String> _fieldsOfInterest = [];
  String? _customField;
  int? _startMonth; // 1-12
  int? _startYear; // e.g., 2026, 2027
  String? _startLabel; // display value like "September 2026"

  String? get educationLevel => _educationLevel;
  String? get desiredDegreeLevel => _desiredDegreeLevel;
  List<String> get fieldsOfInterest => List.unmodifiable(_fieldsOfInterest);
  String? get customField => _customField;
  int? get startMonth => _startMonth;
  int? get startYear => _startYear;
  String? get startLabel => _startLabel;

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

  set customField(String? v) {
    _customField = v;
    notifyListeners();
  }

  void setStartDate(int month, int year) {
    _startMonth = month;
    _startYear = year;
    _startLabel = '${_monthNames[month - 1]} $year';
    notifyListeners();
  }

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool get step1Valid =>
      _educationLevel != null &&
      _desiredDegreeLevel != null &&
      _fieldsOfInterest.isNotEmpty &&
      _startMonth != null &&
      _startYear != null;

  // ── Step 2: Location & Logistics ──
  String? _homeCountry;
  String? _homeCountryCode;
  String? _homeCity;
  final List<String> _preferredDestinations = [];
  String? _preferredLanguage;

  String? get homeCountry => _homeCountry;
  String? get homeCountryCode => _homeCountryCode;
  String? get homeCity => _homeCity;
  List<String> get preferredDestinations =>
      List.unmodifiable(_preferredDestinations);
  String? get preferredLanguage => _preferredLanguage;

  set homeCountry(String? v) {
    _homeCountry = v;
    notifyListeners();
  }

  set homeCountryCode(String? v) {
    _homeCountryCode = v;
    // Auto-set currency based on home country code
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
  String? _annualIncomeLabel; // the bracket string shown in the dropdown
  bool _seekingScholarship = false;

  double? get budgetPerYear => _budgetPerYear;
  String? get currency => _currency;
  double? get annualIncome => _annualIncome;
  String? get annualIncomeLabel => _annualIncomeLabel;
  bool get seekingScholarship => _seekingScholarship;

  set budgetPerYear(double? v) {
    _budgetPerYear = v;
    notifyListeners();
  }

  set annualIncome(double? v) {
    _annualIncome = v;
    notifyListeners();
  }

  set annualIncomeLabel(String? v) {
    _annualIncomeLabel = v;
    notifyListeners();
  }

  set seekingScholarship(bool v) {
    _seekingScholarship = v;
    notifyListeners();
  }

  bool get step3Valid => _budgetPerYear != null;

  /// Returns a currency code based on the selected home country code.
  String _currencyForCountry(String? countryCode) {
    if (countryCode == null) return 'USD';
    // West Africa
    if (countryCode == 'NG') return 'NGN';
    if (['GH', 'SL', 'LR', 'GM'].contains(countryCode)) return 'GHS';
    if ([
      'SN',
      'BJ',
      'TG',
      'NE',
      'ML',
      'BF',
      'GN',
      'GW',
      'CI',
      'CV',
      'MR',
    ].contains(countryCode)) {
      return 'XOF';
    }
    // East Africa
    if ([
      'KE',
      'UG',
      'TZ',
      'RW',
      'BI',
      'SS',
      'ET',
      'ER',
      'DJ',
      'SO',
      'SD',
      'KM',
      'SC',
      'MU',
      'MG',
      'MW',
      'ZM',
      'ZW',
    ].contains(countryCode)) {
      return 'KES';
    }
    // Central Africa
    if ([
      'CM',
      'TD',
      'CF',
      'CG',
      'GA',
      'GQ',
      'ST',
      'AO',
      'CD',
    ].contains(countryCode)) {
      return 'XAF';
    }
    // Southern Africa
    if (['ZA', 'BW', 'NA', 'MZ', 'LS', 'SZ'].contains(countryCode)) {
      return 'ZAR';
    }
    // North Africa
    if (['EG', 'MA', 'DZ', 'TN', 'LY', 'EH'].contains(countryCode)) {
      return 'EGP';
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

  // ── Step 5: Big Five Personality Assessment ──
  final Map<String, int> _personalityResponses = {};

  Map<String, int> get personalityResponses =>
      Map.unmodifiable(_personalityResponses);

  void setPersonalityResponse(String questionId, int score) {
    _personalityResponses[questionId] = score;
    notifyListeners();
  }

  bool get step5Valid => _personalityResponses.isNotEmpty;

  // ── Step 6: Optional Extras ──
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

  bool get step6Valid => true;

  /// Converts the model to a Map for Firestore.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'onboardingComplete': true,
      'onboardingData': {
        // Step 1
        'educationLevel': _educationLevel,
        'desiredDegreeLevel': _desiredDegreeLevel,
        'fieldsOfInterest': _fieldsOfInterest,
        'customField': _customField,
        'startMonth': _startMonth,
        'startYear': _startYear,
        'startLabel': _startLabel,
        // Step 2
        'homeCountry': _homeCountry,
        'homeCountryCode': _homeCountryCode,
        'homeCity': _homeCity,
        'preferredDestinations': _preferredDestinations,
        'preferredLanguage': _preferredLanguage,
        // Step 3
        'budgetPerYear': _budgetPerYear,
        'currency': _currency,
        'annualIncome': _annualIncome,
        'annualIncomeLabel': _annualIncomeLabel,
        'seekingScholarship': _seekingScholarship,
        // Step 4
        'strengths': _strengths,
        'weaknesses': _weaknesses,
        'interests': _interests,
        'careerGoals': _careerGoals,
        // Step 5
        'personalityResponses': _personalityResponses,
        // Step 6
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

  Map<String, dynamic> toMap() => {'testName': testName, 'score': score};
}
