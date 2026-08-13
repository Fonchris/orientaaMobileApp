import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/discovery/models/tier_policy.dart';
import 'package:orientaa_mobile_app/widgets/discovery/models/university_models.dart';

void main() {
  group('TierPolicy', () {
    test('dashboard limits: free 5, pro 15, premium unlimited', () {
      expect(TierPolicy.dashboardLimit(UserTier.free), 5);
      expect(TierPolicy.dashboardLimit(UserTier.pro), 15);
      expect(TierPolicy.dashboardLimit(UserTier.premium), isNull);
    });

    test('search limits: free 20, pro/premium unlimited', () {
      expect(TierPolicy.searchLimit(UserTier.free), 20);
      expect(TierPolicy.searchLimit(UserTier.pro), isNull);
      expect(TierPolicy.searchLimit(UserTier.premium), isNull);
    });

    test('feature gates by tier', () {
      // Sort: Pro/Premium only.
      expect(TierPolicy.canSort(UserTier.free), isFalse);
      expect(TierPolicy.canSort(UserTier.pro), isTrue);
      expect(TierPolicy.canSort(UserTier.premium), isTrue);

      // Compare: Premium only.
      expect(TierPolicy.canCompare(UserTier.free), isFalse);
      expect(TierPolicy.canCompare(UserTier.pro), isFalse);
      expect(TierPolicy.canCompare(UserTier.premium), isTrue);

      // Folders: Pro/Premium only.
      expect(TierPolicy.canUseFolders(UserTier.free), isFalse);
      expect(TierPolicy.canUseFolders(UserTier.pro), isTrue);
      expect(TierPolicy.canUseFolders(UserTier.premium), isTrue);

      // Also-viewed strip: Pro/Premium only.
      expect(TierPolicy.canSeeAlsoViewed(UserTier.free), isFalse);
      expect(TierPolicy.canSeeAlsoViewed(UserTier.pro), isTrue);

      // Counselor booking: Premium only.
      expect(TierPolicy.canBookCounselor(UserTier.free), isFalse);
      expect(TierPolicy.canBookCounselor(UserTier.pro), isFalse);
      expect(TierPolicy.canBookCounselor(UserTier.premium), isTrue);

      // Dashboard refresh: Premium only.
      expect(TierPolicy.canRefresh(UserTier.free), isFalse);
      expect(TierPolicy.canRefresh(UserTier.pro), isFalse);
      expect(TierPolicy.canRefresh(UserTier.premium), isTrue);

      // LLM explanation: Premium only.
      expect(TierPolicy.usesLlmExplanation(UserTier.free), isFalse);
      expect(TierPolicy.usesLlmExplanation(UserTier.pro), isFalse);
      expect(TierPolicy.usesLlmExplanation(UserTier.premium), isTrue);
    });

    test('upgrade banner shows only for free tier with hidden results', () {
      expect(
        TierPolicy.showUpgradeBanner(UserTier.free, total: 6, shown: 5),
        isTrue,
      );
      expect(
        TierPolicy.showUpgradeBanner(UserTier.free, total: 5, shown: 5),
        isFalse,
      );
      expect(
        TierPolicy.showUpgradeBanner(UserTier.pro, total: 20, shown: 15),
        isFalse,
      );
      expect(
        TierPolicy.showUpgradeBanner(UserTier.premium, total: 50, shown: 50),
        isFalse,
      );
    });

    test('cap limits lists for a tier', () {
      final items = List.generate(10, (i) => i);
      expect(
        TierPolicy.cap(items, UserTier.free, TierPolicy.dashboardLimit),
        hasLength(5),
      );
      expect(
        TierPolicy.cap(items, UserTier.pro, TierPolicy.dashboardLimit),
        hasLength(10),
      );
      expect(
        TierPolicy.cap(items, UserTier.premium, TierPolicy.dashboardLimit),
        hasLength(10),
      );
      expect(
        TierPolicy.cap(const [1, 2], UserTier.free, TierPolicy.dashboardLimit),
        hasLength(2),
      );
    });
  });
}
