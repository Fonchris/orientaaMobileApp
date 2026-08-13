import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// User subscription tiers that drive every piece of gating in the discovery
/// module. Read from `users/{uid}.subscription_tier` (defaults to [free]).
enum UserTier {
  free('free'),
  pro('pro'),
  premium('premium');

  const UserTier(this.value);

  /// The stored value on the Firestore user document.
  final String value;

  /// Parses any stored value defensively — anything unexpected becomes [free].
  static UserTier fromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pro':
        return UserTier.pro;
      case 'premium':
        return UserTier.premium;
      default:
        return UserTier.free;
    }
  }

  bool get isAtLeastPro => this != UserTier.free;
  bool get isPremium => this == UserTier.premium;
}

/// How search results should be ordered. Relevance is the engine's ranking;
/// the other two are client-side re-sorts of the returned page.
enum SortOption {
  relevance('relevance'),
  feeAscending('fee_asc'),
  alphabetical('alpha');

  const SortOption(this.value);
  final String value;

  static SortOption fromString(String? raw) {
    switch (raw) {
      case 'fee_asc':
        return SortOption.feeAscending;
      case 'alpha':
        return SortOption.alphabetical;
      default:
        return SortOption.relevance;
    }
  }
}

/// A single ranked university/program result returned by the
/// `getRecommendedUniversities` Cloud Function.
///
/// Parsing is deliberately tolerant: it accepts both camelCase and snake_case
/// keys so the client is not coupled to the exact shape the engine returns.
class RecommendedProgram {
  final String universityId;
  final String programId;
  final String universityName;
  final String programName;
  final String? country;
  final String? countryCode;
  final String? logoUrl;
  final String? bannerUrl;
  final double? fee;
  final String? currency;
  final String? degreeLevel;
  final String? language;
  final double? similarity; // 0–1 or 0–100 match score from the engine
  final List<String> matchReasons;
  final double? latitude;
  final double? longitude;

  const RecommendedProgram({
    required this.universityId,
    required this.programId,
    required this.universityName,
    required this.programName,
    this.country,
    this.countryCode,
    this.logoUrl,
    this.bannerUrl,
    this.fee,
    this.currency,
    this.degreeLevel,
    this.language,
    this.similarity,
    this.matchReasons = const [],
    this.latitude,
    this.longitude,
  });

  factory RecommendedProgram.fromJson(dynamic raw) {
    final d = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((k, v) => MapEntry('$k', v))
            : <String, dynamic>{};

    String? str(String key) => _asString(d[key] ?? d[_snake(key)]);

    return RecommendedProgram(
      universityId:
          str('universityId') ?? str('uniId') ?? str('id') ?? '',
      programId:
          str('programId') ?? str('courseId') ?? str('programmeId') ?? '',
      universityName: str('universityName') ?? str('university') ?? '',
      programName: str('programName') ?? str('course') ?? str('program') ?? '',
      country: str('country'),
      countryCode: str('countryCode') ?? str('country_code'),
      logoUrl: str('logoUrl') ?? str('logo'),
      bannerUrl: str('bannerUrl') ?? str('imageUrl') ?? str('image'),
      fee: _asDouble(d['fee'] ?? d['annualFee'] ?? d['annual_fee'] ?? d['tuition']),
      currency: str('currency'),
      degreeLevel: str('degreeLevel') ?? str('level'),
      language: str('language') ?? str('languageOfInstruction'),
      similarity: _asDouble(d['similarity'] ??
          d['similarityScore'] ??
          d['matchScore'] ??
          d['match_score'] ??
          d['score']),
      matchReasons:
          _asStringList(d['matchReasons'] ?? d['match_reasons'] ?? d['reasons']),
      latitude: _asDouble(d['lat'] ?? d['latitude']),
      longitude: _asDouble(d['lng'] ?? d['lon'] ?? d['longitude']),
    );
  }

  /// A match percentage in 0–100 for display ("Match: 92%"). The engine may
  /// return 0–1 or 0–100, so normalize defensively.
  int? get matchPercent {
    final s = similarity;
    if (s == null) return null;
    if (s > 1) return s.round().clamp(0, 100);
    return (s * 100).round().clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
        'universityId': universityId,
        'programId': programId,
        'universityName': universityName,
        'programName': programName,
        'country': country,
        'countryCode': countryCode,
        'logoUrl': logoUrl,
        'bannerUrl': bannerUrl,
        'fee': fee,
        'currency': currency,
        'degreeLevel': degreeLevel,
        'language': language,
        'similarity': similarity,
        'matchReasons': matchReasons,
        'latitude': latitude,
        'longitude': longitude,
      };

  RecommendedProgram copyWith({List<String>? matchReasons}) =>
      RecommendedProgram(
        universityId: universityId,
        programId: programId,
        universityName: universityName,
        programName: programName,
        country: country,
        countryCode: countryCode,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        fee: fee,
        currency: currency,
        degreeLevel: degreeLevel,
        language: language,
        similarity: similarity,
        matchReasons: matchReasons ?? this.matchReasons,
        latitude: latitude,
        longitude: longitude,
      );
}

/// The ranked result set returned by `getRecommendedUniversities`.
class RecommendationResponse {
  final List<RecommendedProgram> results;
  final bool hasMore;
  final String? cursor;
  final int? total;
  final DateTime fetchedAt;

  RecommendationResponse({
    required this.results,
    this.hasMore = false,
    this.cursor,
    this.total,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Tolerates every common envelope shape: a bare list, `{results: [...]}`,
  /// `{universities: [...]}`, `{items: [...]}` or `{data: [...]}`.
  factory RecommendationResponse.fromJson(dynamic raw,
      {DateTime? fetchedAt}) {
    final d = raw is Map<String, dynamic>
        ? raw
        : raw is Map
            ? raw.map((k, v) => MapEntry('$k', v))
            : null;
    dynamic list = raw;
    if (d != null) {
      list = d['results'] ??
          d['universities'] ??
          d['items'] ??
          d['recommendations'] ??
          d['data'];
    }
    final items = list is List ? list : const [];
    final results = items
        .map(RecommendedProgram.fromJson)
        .where((p) => p.universityId.isNotEmpty || p.programId.isNotEmpty)
        .toList();
    return RecommendationResponse(
      results: results,
      hasMore: d?['hasMore'] == true || d?['has_more'] == true,
      cursor: _asString(d?['cursor'] ?? d?['nextCursor']),
      total: (d?['total'] as num?)?.toInt(),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'results': results.map((r) => r.toJson()).toList(),
        'hasMore': hasMore,
        'cursor': cursor,
        'total': total,
        'fetchedAt': fetchedAt.toIso8601String(),
      };
}

/// Filters for the paginated `getRecommendedUniversities` call. The engine
/// applies these as hard constraints BEFORE ranking, so the client never
/// renders anything outside them.
class RecommendationFilters {
  final String? country; // free-text country name, e.g. "Nigeria"
  final String? countryCode; // ISO code when picked from the country picker
  final String? region; // e.g. "West Africa" (from AfricanRegions)
  final String? degreeLevel; // e.g. "Bachelor's"
  final double? minFee;
  final double? maxFee;
  final String? currency;
  final List<String> fields; // fields of study (OR within the list)
  final String? language; // language of instruction
  final SortOption sort;
  final String? cursor;
  final int pageSize;

  const RecommendationFilters({
    this.country,
    this.countryCode,
    this.region,
    this.degreeLevel,
    this.minFee,
    this.maxFee,
    this.currency,
    this.fields = const [],
    this.language,
    this.sort = SortOption.relevance,
    this.cursor,
    this.pageSize = 20,
  });

  static const RecommendationFilters none = RecommendationFilters();

  bool get isEmpty =>
      country == null &&
      countryCode == null &&
      region == null &&
      degreeLevel == null &&
      minFee == null &&
      maxFee == null &&
      fields.isEmpty &&
      language == null &&
      sort == SortOption.relevance &&
      cursor == null;

  RecommendationFilters copyWith({
    String? country,
    String? countryCode,
    String? region,
    String? degreeLevel,
    double? minFee,
    double? maxFee,
    String? currency,
    List<String>? fields,
    String? language,
    SortOption? sort,
    String? cursor,
    int? pageSize,
    bool clearCountry = false,
    bool clearCountryCode = false,
    bool clearRegion = false,
    bool clearDegree = false,
    bool clearFee = false,
    bool clearCurrency = false,
    bool clearLanguage = false,
  }) {
    return RecommendationFilters(
      country: clearCountry ? null : (country ?? this.country),
      countryCode: clearCountryCode ? null : (countryCode ?? this.countryCode),
      region: clearRegion ? null : (region ?? this.region),
      degreeLevel:
          clearDegree ? null : (degreeLevel ?? this.degreeLevel),
      minFee: clearFee ? null : (minFee ?? this.minFee),
      maxFee: clearFee ? null : (maxFee ?? this.maxFee),
      currency: clearCurrency ? null : (currency ?? this.currency),
      fields: fields ?? this.fields,
      language: clearLanguage ? null : (language ?? this.language),
      sort: sort ?? this.sort,
      cursor: cursor ?? this.cursor,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Payload sent to the Cloud Function.
  Map<String, dynamic> toFunctionData() => {
        'country': country,
        'countryCode': countryCode,
        'region': region,
        'degreeLevel': degreeLevel,
        'minFee': minFee,
        'maxFee': maxFee,
        'currency': currency,
        'fields': fields,
        'language': language,
        'sort': sort.value,
        'cursor': cursor,
        'pageSize': pageSize,
      };

  /// Deterministic cache key so the offline cache is scoped to the exact
  /// filter combination (dashboard = the empty-filters key).
  String get cacheKey {
    final parts = [
      'c=$countryCode',
      'r=$region',
      'd=$degreeLevel',
      'f=${fields.join(',')}',
      'l=$language',
      'fee=${minFee?.round()}-${maxFee?.round()}',
      'cur=$currency',
      's=${sort.value}',
    ];
    return parts.join('|');
  }
}

/// One program offered by a university (used on the detail page).
class UniversityProgram {
  final String id;
  final String name;
  final String? degreeLevel;
  final double? fee;
  final String? currency;
  final String? duration;
  final String? language;
  final List<String> admissionRequirements;

  const UniversityProgram({
    required this.id,
    required this.name,
    this.degreeLevel,
    this.fee,
    this.currency,
    this.duration,
    this.language,
    this.admissionRequirements = const [],
  });

  factory UniversityProgram.fromMap(String id, Map<String, dynamic> d) {
    return UniversityProgram(
      id: id,
      name: d['name'] as String? ?? d['title'] as String? ?? id,
      degreeLevel: _asString(d['degreeLevel'] ?? d['level']),
      fee: _asDouble(d['fee'] ?? d['annualFee'] ?? d['tuition']),
      currency: _asString(d['currency']),
      duration: _asString(d['duration']),
      language: _asString(d['language'] ?? d['languageOfInstruction']),
      admissionRequirements:
          _asStringList(d['admissionRequirements'] ?? d['requirements']),
    );
  }
}

/// Full university document from the `universities/{id}` collection.
class UniversityDetail {
  final String id;
  final String name;
  final String? country;
  final String? countryCode;
  final bool verified;
  final String? description;
  final String? imageUrl;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final List<UniversityProgram> programs;
  final List<String> fields;

  const UniversityDetail({
    required this.id,
    required this.name,
    this.country,
    this.countryCode,
    this.verified = false,
    this.description,
    this.imageUrl,
    this.logoUrl,
    this.latitude,
    this.longitude,
    this.programs = const [],
    this.fields = const [],
  });

  factory UniversityDetail.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final d = snapshot.data() ?? const <String, dynamic>{};
    final rawPrograms = d['programs'];
    final programs = <UniversityProgram>[];
    if (rawPrograms is List) {
      for (final p in rawPrograms) {
        if (p is Map) {
          final id = _asString(p['id'] ?? p['programId']) ?? 'program-${programs.length}';
          programs.add(UniversityProgram.fromMap(id, p.map((k, v) => MapEntry('$k', v))));
        }
      }
    } else if (rawPrograms is Map) {
      rawPrograms.forEach((key, value) {
        if (value is Map) {
          programs.add(UniversityProgram.fromMap(
              '$key', value.map((k, v) => MapEntry('$k', v))));
        }
      });
    }
    return UniversityDetail(
      id: snapshot.id,
      name: d['name'] as String? ?? snapshot.id,
      country: _asString(d['country']),
      countryCode: _asString(d['countryCode'] ?? d['country_code']),
      verified: d['verified'] == true,
      description: _asString(d['description'] ?? d['overview']),
      imageUrl: _asString(d['imageUrl'] ?? d['bannerUrl'] ?? d['image']),
      logoUrl: _asString(d['logoUrl'] ?? d['logo']),
      latitude: _asDouble(d['lat'] ?? d['latitude']),
      longitude: _asDouble(d['lng'] ?? d['lon'] ?? d['longitude']),
      programs: programs,
      fields: _asStringList(d['fields'] ?? d['fieldsOfStudy']),
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

/// A saved program under `saved_universities/{uid}/items/{programId}`.
class SavedUniversity {
  final String programId;
  final String universityId;
  final String universityName;
  final String programName;
  final String? country;
  final String? countryCode;
  final String? degreeLevel;
  final String? folderId;
  final DateTime? savedAt;

  const SavedUniversity({
    required this.programId,
    required this.universityId,
    required this.universityName,
    required this.programName,
    this.country,
    this.countryCode,
    this.degreeLevel,
    this.folderId,
    this.savedAt,
  });

  factory SavedUniversity.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final d = snapshot.data() ?? const <String, dynamic>{};
    return SavedUniversity(
      programId: snapshot.id,
      universityId: d['universityId'] as String? ?? '',
      universityName: d['universityName'] as String? ?? 'University',
      programName: d['programName'] as String? ?? '',
      country: d['country'] as String?,
      countryCode: d['countryCode'] as String?,
      degreeLevel: d['degreeLevel'] as String?,
      folderId: d['folderId'] as String?,
      savedAt: (d['savedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A named folder/collection of saved universities (Pro/Premium only).
class SavedFolder {
  final String id;
  final String name;
  final DateTime? createdAt;

  const SavedFolder({required this.id, required this.name, this.createdAt});

  factory SavedFolder.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final d = snapshot.data() ?? const <String, dynamic>{};
    return SavedFolder(
      id: snapshot.id,
      name: d['name'] as String? ?? 'Folder',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ── Shared parsing helpers ────────────────────────────────────────────────

String? _asString(dynamic v) => v is String && v.trim().isNotEmpty
    ? v
    : v is num
        ? v.toString()
        : null;

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<String> _asStringList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
}

String _snake(String camel) => camel
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m[1]}_${m[2]!.toLowerCase()}',
    )
    .toLowerCase();

// ── Display helpers ───────────────────────────────────────────────────────

/// Turns an ISO 3166-1 alpha-2 code into a flag emoji via regional indicator
/// symbols. Falls back to a globe when the code is missing/malformed.
String flagEmojiFor(String? countryCode) {
  final code = countryCode?.trim().toUpperCase() ?? '';
  if (code.length != 2 || !RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '🌍';
  const base = 0x1F1E6; // regional indicator A
  return code
      .codeUnits
      .map((c) => String.fromCharCode(base + (c - 0x41)))
      .join();
}

const Map<String, String> _currencySymbols = {
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'NGN': '₦',
  'GHS': 'GH₵',
  'KES': 'KSh ',
  'ZAR': 'R',
  'EGP': 'E£',
  'CAD': r'C$',
  'AUD': r'A$',
  'XOF': 'CFA ',
  'XAF': 'FCFA ',
  'CNY': '¥',
  'JPY': '¥',
  'INR': '₹',
  'AED': 'AED ',
};

/// Formats a fee for display, e.g. 12000 USD -> "$12,000".
String formatMoney(double? amount, String? currency) {
  if (amount == null) return '';
  final symbol = _currencySymbols[currency?.toUpperCase().trim()];
  final formatted = NumberFormat('#,##0.##').format(amount);
  if (symbol == null) {
    return currency == null || currency.trim().isEmpty
        ? formatted
        : '$formatted ${currency.toUpperCase()}';
  }
  return '$symbol$formatted';
}
