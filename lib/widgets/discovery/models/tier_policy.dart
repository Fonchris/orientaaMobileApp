import 'university_models.dart';

/// Central, pure mapping from [UserTier] to every gating rule in the
/// discovery module. Keeping this free of Flutter/Firebase imports makes the
/// business rules unit-testable and guarantees one source of truth — screens
/// never re-implement tier checks inline.
class TierPolicy {
  const TierPolicy._();

  /// Free tier: first 5 recommendation cards on the dashboard.
  static const int freeDashboardLimit = 5;

  /// Pro tier: 15 dashboard cards.
  static const int proDashboardLimit = 15;

  /// Free tier: search results capped at 20.
  static const int freeSearchLimit = 20;

  /// How many dashboard recommendation cards a tier may see.
  /// Null = unlimited (premium sees the full list).
  static int? dashboardLimit(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return freeDashboardLimit;
      case UserTier.pro:
        return proDashboardLimit;
      case UserTier.premium:
        return null;
    }
  }

  /// Max search results per tier. Null = unlimited.
  static int? searchLimit(UserTier tier) =>
      tier == UserTier.free ? freeSearchLimit : null;

  /// Sort dropdown on the search page: Pro/Premium only.
  static bool canSort(UserTier tier) => tier != UserTier.free;

  /// Multi-select + Compare on the search page: Premium only.
  static bool canCompare(UserTier tier) => tier == UserTier.premium;

  /// Named saved folders: Pro/Premium only. Free tier gets a flat list.
  static bool canUseFolders(UserTier tier) => tier != UserTier.free;

  /// "Students like you also viewed" strip: Pro/Premium only.
  static bool canSeeAlsoViewed(UserTier tier) => tier != UserTier.free;

  /// "Book a counselor session" button on the detail page: Premium only.
  static bool canBookCounselor(UserTier tier) => tier == UserTier.premium;

  /// Manual "refresh" affordance on the dashboard: Premium only.
  static bool canRefresh(UserTier tier) => tier == UserTier.premium;

  /// LLM natural-language explanation of a match: Premium only.
  static bool usesLlmExplanation(UserTier tier) => tier == UserTier.premium;

  /// True when a tier-limited view should hint that more matches exist.
  static bool showUpgradeBanner(UserTier tier,
          {required int total, required int shown}) =>
      tier == UserTier.free && total > shown;

  /// Limits [items] for a tier (null limit = all items).
  static List<T> cap<T>(List<T> items, UserTier tier, int? Function(UserTier) limitOf) {
    final limit = limitOf(tier);
    if (limit == null || items.length <= limit) return items;
    return items.sublist(0, limit);
  }
}
