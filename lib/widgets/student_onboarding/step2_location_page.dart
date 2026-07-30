import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker_flutter_plus/country_picker_flutter_plus.dart' as cpf;
import '../../data/african_regions.dart';
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
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _brandBlue.withValues(alpha: 0.1),
                ),
                child: const FaIcon(FontAwesomeIcons.globe, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location & Logistics',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Where are you from and where do you want to study?',
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
          const SizedBox(height: 24),

          // ── Home Country ──
          _sectionLabel(FontAwesomeIcons.flag, 'Home Country', isDark),
          const SizedBox(height: 8),
          _buildCountryPicker(context),
          const SizedBox(height: 20),

          // ── Home City ──
          _sectionLabel(FontAwesomeIcons.city, 'City', isDark),
          const SizedBox(height: 8),
          _buildCityField(context),
          const SizedBox(height: 20),

          // ── Preferred Study Destinations ──
          _sectionLabel(FontAwesomeIcons.plane, 'Preferred Study Destination(s)', isDark),
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
          _sectionLabel(FontAwesomeIcons.language, 'Preferred Language of Instruction', isDark),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: model.step2Valid ? Colors.white : subtitleColor,
                          ),
                        ),
                        if (model.step2Valid) ...[
                          const SizedBox(width: 8),
                          const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 16),
                        ],
                      ],
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

  Widget _sectionLabel(FaIconData icon, String label, bool isDark) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: _brandBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Country Picker (using country_picker_flutter_plus) ──
  Widget _buildCountryPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16, color: _brandBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model.homeCountry != null
                    ? model.homeCountry!
                    : 'Select your home country',
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
            if (model.homeCountry != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getRegionColor(model.homeCountryCode ?? ''),
                ),
                child: Text(
                  _getRegionLabel(model.homeCountryCode ?? ''),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCountryPicker(BuildContext context) async {
    final countryInfo = await showCountryPickerDialog(context);

    if (countryInfo != null) {
      final countryName = countryInfo.name;
      final countryCode = countryInfo.code;

      // Determine region for African countries
      final region = AfricanRegions.getRegion(countryCode);
      final displayName = region != null ? '$countryName ($region)' : countryName;

      model.homeCountry = displayName;
      model.homeCountryCode = countryCode;
    }
  }

  String _getRegionLabel(String countryCode) {
    final region = AfricanRegions.getRegion(countryCode);
    if (region == null) return 'Diaspora';
    // Abbreviate
    if (region == 'West Africa') return 'West';
    if (region == 'East Africa') return 'East';
    if (region == 'Central Africa') return 'Central';
    if (region == 'Southern Africa') return 'South';
    if (region == 'North Africa') return 'North';
    return 'Other';
  }

  Color _getRegionColor(String countryCode) {
    final region = AfricanRegions.getRegion(countryCode);
    switch (region) {
      case 'West Africa':
        return const Color(0xFF4CAF50);
      case 'East Africa':
        return const Color(0xFF2196F3);
      case 'Central Africa':
        return const Color(0xFFFF9800);
      case 'Southern Africa':
        return const Color(0xFFE91E63);
      case 'North Africa':
        return const Color(0xFF9C27B0);
      default:
        return _brandBlue;
    }
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
            : Colors.white.withValues(alpha: 0.9),
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
    // Show a button to add destinations and display existing ones
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing destinations
        ...List.generate(model.preferredDestinations.length, (index) {
          final dest = model.preferredDestinations[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _brandBlue.withValues(alpha: 0.1),
              border: Border.all(color: _brandBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.check, size: 12, color: _brandBlue),
                const SizedBox(width: 8),
                Text(
                  dest,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _brandBlue,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => model.toggleDestination(dest),
                  child: FaIcon(FontAwesomeIcons.xmark, size: 12, color: _brandBlue.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showAddDestinationDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : _brandBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.plus, size: 14, color: _brandBlue),
                const SizedBox(width: 8),
                Text(
                  'Add destination',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _brandBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDestinationDialog(BuildContext context) async {
    final countryInfo = await showCountryPickerDialog(context);

    if (countryInfo != null) {
      final countryName = countryInfo.name;
      final countryCode = countryInfo.code;
      final region = AfricanRegions.getRegion(countryCode);
      final displayName = region != null ? '$countryName ($region)' : countryName;
      model.toggleDestination(displayName);
    }
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
            : Colors.white.withValues(alpha: 0.9),
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
          icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
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

/// Helper to show a country picker dialog using EnhancedCountrySelector.
Future<cpf.CountryInfo?> showCountryPickerDialog(BuildContext context) async {
  final dataManager = cpf.CountryDataManager();
  final countries = await dataManager.getCountries();
  if (!context.mounted) return null;

  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<cpf.CountryInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a country',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCountryList(ctx, countries, isDark),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCountryList(BuildContext context, List<cpf.CountryInfo> countries, bool isDark) {
  final searchController = TextEditingController();
  final searchResults = ValueNotifier<List<cpf.CountryInfo>>(countries);

  void onSearch(String query) {
    if (query.isEmpty) {
      searchResults.value = countries;
    } else {
      final lower = query.toLowerCase();
      searchResults.value = countries.where((c) =>
        c.name.toLowerCase().contains(lower) ||
        (c.nativeName?.toLowerCase().contains(lower) == true) ||
        c.code.toLowerCase().contains(lower)
      ).toList();
    }
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search countries...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF323232).withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.06),
          ),
          onChanged: onSearch,
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ValueListenableBuilder<List<cpf.CountryInfo>>(
          valueListenable: searchResults,
          builder: (context, filtered, _) {
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final country = filtered[index];
                return ListTile(
                  leading: Text(country.flagEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    country.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  subtitle: country.capital != null
                      ? Text(country.capital!, style: GoogleFonts.inter(fontSize: 12))
                      : null,
                  onTap: () => Navigator.pop(context, country),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
