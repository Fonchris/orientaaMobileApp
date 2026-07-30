import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_onboarding_model.dart';

class Step2LocationPage extends StatelessWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step2LocationPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  /// African countries grouped by region, plus a diaspora option.
  static const Map<String, List<String>> africanCountriesByRegion = {
    'West Africa': [
      'Nigeria',
      'Ghana',
      'Ivory Coast',
      'Senegal',
      'Benin',
      'Togo',
      'Niger',
      'Mali',
      'Burkina Faso',
      'Guinea',
      'Guinea-Bissau',
      'Liberia',
      'Sierra Leone',
      'Gambia',
      'Cape Verde',
      'Mauritania',
    ],
    'East Africa': [
      'Kenya',
      'Tanzania',
      'Uganda',
      'Ethiopia',
      'Rwanda',
      'Somalia',
      'South Sudan',
      'Sudan',
      'Djibouti',
      'Eritrea',
      'Burundi',
      'Comoros',
      'Seychelles',
      'Mauritius',
      'Madagascar',
      'Malawi',
      'Zambia',
      'Zimbabwe',
    ],
    'Central Africa': [
      'DR Congo',
      'Cameroon',
      'Angola',
      'Chad',
      'Central African Republic',
      'Congo',
      'Gabon',
      'Equatorial Guinea',
      'São Tomé and Príncipe',
    ],
    'Southern Africa': [
      'South Africa',
      'Botswana',
      'Namibia',
      'Mozambique',
      'Lesotho',
      'Eswatini',
    ],
    'North Africa': [
      'Egypt',
      'Morocco',
      'Algeria',
      'Tunisia',
      'Libya',
      'Western Sahara',
    ],
  };

  /// All African countries as a flat list for search.
  static List<String> get _allAfricanCountries {
    return africanCountriesByRegion.values.expand((x) => x).toList();
  }

  /// Full list of country options including diaspora.
  static List<String> get _allCountryOptions {
    return ['Outside Africa / Diaspora', ..._allAfricanCountries];
  }

  static const List<String> languagesOfInstruction = [
    'English',
    'French',
    'Portuguese',
    'Arabic',
    'Spanish',
    'German',
    'Chinese',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.5);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Location & Logistics',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where are you from and where do you want to study?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 24),

          // ── Home Country ──
          _sectionLabel('Home Country', isDark),
          const SizedBox(height: 8),
          _buildSearchableCountryDropdown(context),
          const SizedBox(height: 20),

          // ── Home City ──
          _sectionLabel('City', isDark),
          const SizedBox(height: 8),
          _buildCityField(context),
          const SizedBox(height: 20),

          // ── Preferred Study Destinations ──
          _sectionLabel('Preferred Study Destination(s)', isDark),
          const SizedBox(height: 4),
          Text(
            'Select all that apply (can differ from your home country)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDestinationsMultiSelect(context),
          const SizedBox(height: 20),

          // ── Preferred Language of Instruction ──
          _sectionLabel('Preferred Language of Instruction', isDark),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            context,
            value: model.preferredLanguage,
            items: languagesOfInstruction,
            hint: 'Select language',
            onChanged: (v) => model.preferredLanguage = v,
          ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onBack,
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
                    onPressed: model.step2Valid ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : _brandBlue.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: model.step2Valid ? 4 : 0,
                      shadowColor: _brandBlue.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: model.step2Valid ? Colors.white : subtitleColor,
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

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue,
        letterSpacing: 0.2,
      ),
    );
  }

  // ── Searchable Country Dropdown ──
  Widget _buildSearchableCountryDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showCountrySearchDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? const Color(0xFF323232).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.85),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _brandBlue.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                model.homeCountry ?? 'Select your home country',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: model.homeCountry != null
                      ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : _brandBlue.withValues(alpha: 0.3)),
                ),
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : _brandBlue.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCountrySearchDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    final searchResult = ValueNotifier<List<_CountryGroup>>(_buildCountryGroups(''));

    void onSearchChanged(String query) {
      searchResult.value = _buildCountryGroups(query);
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search countries...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF323232).withValues(alpha: 0.6)
                          : Colors.grey.withValues(alpha: 0.06),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<_CountryGroup>>(
                  valueListenable: searchResult,
                  builder: (context, groups, _) {
                    if (groups.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No countries found'),
                      );
                    }
                    return Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: groups.expand((group) {
                          return [
                            if (group.name.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  group.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _brandBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ...group.countries.map((country) {
                              final isSelected = model.homeCountry == country;
                              return ListTile(
                                dense: true,
                                title: Text(
                                  country,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? _brandBlue
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E)),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: _brandBlue, size: 20)
                                    : null,
                                onTap: () => Navigator.pop(ctx, country),
                              );
                            }),
                          ];
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      model.homeCountry = selected;
    }
  }

  List<_CountryGroup> _buildCountryGroups(String query) {
    final lowerQuery = query.toLowerCase();
    if (query.isEmpty) {
      return [
        _CountryGroup('', ['Outside Africa / Diaspora']),
        ...africanCountriesByRegion.entries.map((e) =>
            _CountryGroup(e.key, e.value)),
      ];
    }

    // Filter by query
    final allMatching = _allCountryOptions
        .where((c) => c.toLowerCase().contains(lowerQuery))
        .toList();

    if (allMatching.isEmpty) return [];

    // Group matching results
    final groups = <_CountryGroup>[];
    final diasporaMatch = 'Outside Africa / Diaspora'.toLowerCase().contains(lowerQuery);
    if (diasporaMatch && 'Outside Africa / Diaspora'.toLowerCase().contains(lowerQuery)) {
      groups.add(_CountryGroup('', ['Outside Africa / Diaspora']));
    }

    for (final entry in africanCountriesByRegion.entries) {
      final matching = entry.value
          .where((c) => c.toLowerCase().contains(lowerQuery))
          .toList();
      if (matching.isNotEmpty) {
        groups.add(_CountryGroup(entry.key, matching));
      }
    }
    return groups;
  }

  // ── City Text Field ──
  Widget _buildCityField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: TextEditingController(text: model.homeCity ?? '')
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: model.homeCity?.length ?? 0),
        ),
      onChanged: (v) => model.homeCity = v,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: 'Enter your city',
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : _brandBlue.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _brandBlue.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _brandBlue.withValues(alpha: 0.08),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Destinations Multi-Select ──
  Widget _buildDestinationsMultiSelect(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = _allCountryOptions;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = model.preferredDestinations.contains(option);
        return GestureDetector(
          onTap: () => model.toggleDestination(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected
                  ? _brandBlue
                  : isDark
                      ? const Color(0xFF323232).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: isSelected
                    ? _brandBlue
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check, size: 14, color: _brandGold),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Generic Dropdown ──
  Widget _buildDropdown<T>(
    BuildContext context, {
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.85),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _brandBlue.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : _brandBlue.withValues(alpha: 0.3),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : _brandBlue.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(14),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Helper class for grouping countries in the search dialog.
class _CountryGroup {
  final String name;
  final List<String> countries;
  _CountryGroup(this.name, this.countries);
}