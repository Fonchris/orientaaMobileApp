import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/counselors/services/counselor_service.dart';

void main() {
  group('CounselorFilters', () {
    test('default filters are empty', () {
      const f = CounselorFilters();
      expect(f.isEmpty, isTrue);
      expect(f.sort, CounselorSort.recommended);
    });

    test('copyWith keeps untouched fields', () {
      const f = CounselorFilters(specialties: ['Scholarships'], onlineOnly: true);
      final g = f.copyWith(minPrice: 10);
      expect(g.specialties, ['Scholarships']);
      expect(g.onlineOnly, isTrue);
      expect(g.minPrice, 10);
      expect(g.maxPrice, isNull);
    });

    test('clear resets everything', () {
      const f = CounselorFilters(
        specialties: ['A'],
        languages: ['fr'],
        onlineOnly: true,
        minPrice: 5,
        maxPrice: 50,
        sort: CounselorSort.priceAsc,
      );
      final cleared = f.clear();
      expect(cleared.isEmpty, isTrue);
      expect(cleared.sort, CounselorSort.recommended);
    });

    test('isNotEmpty reflects active filters', () {
      expect(const CounselorFilters(languages: ['en']).isEmpty, isFalse);
      expect(const CounselorFilters(minPrice: 0).isEmpty, isFalse);
      expect(const CounselorFilters(onlineOnly: false).isEmpty, isTrue);
    });
  });

  group('CounselorSort', () {
    test('has all three options', () {
      expect(CounselorSort.values, hasLength(3));
      expect(CounselorSort.values, containsAll([CounselorSort.recommended, CounselorSort.priceAsc, CounselorSort.ratingDesc]));
    });
  });
}
