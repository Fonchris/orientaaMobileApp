import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker_flutter_plus/country_picker_flutter_plus.dart'
    as cpf;

import '../app_theme.dart';
import '../google_fonts.dart';
import '../../data/african_regions.dart';
import 'student_onboarding_model.dart';
import 'step_ui.dart';

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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ──
                const StepReveal(
                  child: StepHeroCard(
                    icon: FontAwesomeIcons.planeDeparture,
                    title: 'Location & Logistics',
                    subtitle:
                        'Where are you from, and where do you want to study?',
                    chips: ['Diaspora friendly', 'Global reach'],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Destination illustration banner ──
                const StepReveal(
                  delay: Duration(milliseconds: 70),
                  child: _DestinationIllustration(),
                ),
                const SizedBox(height: 22),

                // ── Home Country ──
                StepReveal(
                  delay: const Duration(milliseconds: 120),
                  child: _HomeCountrySection(model: model),
                ),
                const SizedBox(height: 22),

                // ── Home City ──
                StepReveal(
                  delay: const Duration(milliseconds: 160),
                  child: _HomeCitySection(model: model),
                ),
                const SizedBox(height: 22),

                // ── Preferred Study Destinations ──
                StepReveal(
                  delay: const Duration(milliseconds: 200),
                  child: _DestinationsSection(model: model),
                ),
                const SizedBox(height: 22),

                // ── Preferred Language of Instruction ──
                StepReveal(
                  delay: const Duration(milliseconds: 240),
                  child: _LanguageSection(model: model),
                ),
              ],
            ),
          ),
        ),
        StepNavBar(
          onBack: onBack,
          onNext: onNext,
          nextLabel: model.step2Valid ? 'Continue' : 'Complete required fields',
          nextEnabled: model.step2Valid,
          hint: model.step2Valid
              ? null
              : 'Select your home country and city to continue',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sections
// ─────────────────────────────────────────────────────────────────────────────

class _HomeCountrySection extends StatelessWidget {
  final StudentOnboardingModel model;

  const _HomeCountrySection({required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepSectionLabel(
          icon: FontAwesomeIcons.flag,
          label: 'Home Country',
          helper: 'Your country of residence',
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openCountryPicker(context, (country) {
            final region = AfricanRegions.getRegion(country.code);
            model.homeCountry = region != null
                ? '${country.name} ($region)'
                : country.name;
            model.homeCountryCode = country.code;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : scheme.outline.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.brandBlue, const Color(0xFF3B82F6)],
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.globe,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.homeCountry ?? 'Select your home country',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: model.homeCountry != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: model.homeCountry != null
                              ? (isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E))
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : AppTheme.brandBlue.withValues(
                                        alpha: 0.4,
                                      )),
                        ),
                      ),
                      if (model.homeCountry != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          model.homeCountryCode ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : AppTheme.brandBlue.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (model.homeCountryCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _regionColor(model.homeCountryCode!),
                    ),
                    child: Text(
                      _regionLabel(model.homeCountryCode!),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                FaIcon(
                  FontAwesomeIcons.chevronDown,
                  size: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppTheme.brandBlue.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCitySection extends StatelessWidget {
  final StudentOnboardingModel model;

  const _HomeCitySection({required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepSectionLabel(
          icon: FontAwesomeIcons.city,
          label: 'Home City',
          helper: 'The city you currently live in',
        ),
        const SizedBox(height: 10),
        BrandTextField(
          initialText: model.homeCity ?? '',
          label: 'City',
          hint: 'e.g. Lagos, Accra, Nairobi',
          prefixIcon: FontAwesomeIcons.locationDot,
          onChanged: (v) => model.homeCity = v,
        ),
      ],
    );
  }
}

class _DestinationsSection extends StatelessWidget {
  final StudentOnboardingModel model;

  const _DestinationsSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepSectionLabel(
          icon: FontAwesomeIcons.mapLocationDot,
          label: 'Preferred Study Destination(s)',
          helper: 'Select all that apply — can differ from your home country',
        ),
        const SizedBox(height: 10),
        if (model.preferredDestinations.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: model.preferredDestinations.map((dest) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppTheme.brandBlue.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.brandBlue.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.mapPin,
                        size: 12,
                        color: AppTheme.brandBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dest,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => model.toggleDestination(dest),
                        child: FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 12,
                          color: AppTheme.brandBlue.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openCountryPicker(context, (country) {
            final region = AfricanRegions.getRegion(country.code);
            final displayName = region != null
                ? '${country.name} ($region)'
                : country.name;
            model.toggleDestination(displayName);
          }),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.brandBlue.withValues(alpha: 0.15),
              ),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.plus,
                  size: 13,
                  color: isDark ? AppTheme.brandGold : AppTheme.brandBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add destination',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.brandGold : AppTheme.brandBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final StudentOnboardingModel model;

  const _LanguageSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepSectionLabel(
          icon: FontAwesomeIcons.language,
          label: 'Preferred Language of Instruction',
          helper: 'The language you want to study in',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : scheme.outline.withValues(alpha: 0.55),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: model.preferredLanguage,
              isExpanded: true,
              hint: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.commentDots,
                    size: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppTheme.brandBlue.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select a language',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : AppTheme.brandBlue.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              icon: FaIcon(
                FontAwesomeIcons.chevronDown,
                size: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandBlue.withValues(alpha: 0.5),
              ),
              items: Step2LocationPage.languagesOfInstruction.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.brandBlue.withValues(alpha: 0.08),
                          ),
                          child: Center(
                            child: Text(
                              lang.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(lang),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => model.preferredLanguage = v,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _openCountryPicker(
  BuildContext context,
  void Function(cpf.CountryInfo country) onSelected,
) async {
  try {
    final country = await showCountryPickerDialog(context);
    if (country != null && context.mounted) {
      onSelected(country);
    }
  } catch (e) {
    debugPrint('Failed to open country picker: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open country picker. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

String _regionLabel(String countryCode) {
  final region = AfricanRegions.getRegion(countryCode);
  if (region == null) return 'Diaspora';
  if (region == 'West Africa') return 'West';
  if (region == 'East Africa') return 'East';
  if (region == 'Central Africa') return 'Central';
  if (region == 'Southern Africa') return 'South';
  if (region == 'North Africa') return 'North';
  return 'Other';
}

Color _regionColor(String countryCode) {
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
      return AppTheme.brandBlue;
  }
}

/// Compact illustration banner: a student choosing a study destination.
class _DestinationIllustration extends StatelessWidget {
  const _DestinationIllustration();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                  const Color(0xFF243B7A).withValues(alpha: 0.7),
                ]
              : [const Color(0xFFEAF1FF), const Color(0xFFFFF3D6)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dotted path from home to destination
          Positioned(
            left: 24,
            top: 52,
            child: CustomPaint(
              size: const Size(200, 24),
              painter: _DashedPathPainter(
                color: isDark
                    ? AppTheme.brandGold.withValues(alpha: 0.6)
                    : AppTheme.brandBlue.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Home pin
          const Positioned(left: 10, top: 30, child: _PinBadge(label: 'H')),
          // Plane flying along the path
          Positioned(
            left: 104,
            top: 18,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, -4 * (value - 0.9)),
                child: child,
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brandGold, AppTheme.brandBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandBlue.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.planeUp,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Destination pin
          const Positioned(right: 10, top: 30, child: _PinBadge(label: 'A')),
          // Caption
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Text(
                'Find the destination that fits your goals',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppTheme.brandBlue.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  final String label;

  const _PinBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.brandBlue,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandBlue.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const FaIcon(
          FontAwesomeIcons.chevronDown,
          size: 10,
          color: Color(0xFF011F7B),
        ),
      ],
    );
  }
}

class _DashedPathPainter extends CustomPainter {
  final Color color;

  _DashedPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPathPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Country picker (uses country_picker_flutter_plus data)
// ─────────────────────────────────────────────────────────────────────────────

/// Helper to show a searchable country picker bottom sheet.
Future<cpf.CountryInfo?> showCountryPickerDialog(BuildContext context) async {
  final dataManager = cpf.CountryDataManager();
  final countries = await dataManager.getCountries();
  if (!context.mounted) return null;

  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Pin African countries to the top for quicker access.
  final sorted = [...countries]
    ..sort((a, b) {
      final aAf = AfricanRegions.isAfrican(a.code);
      final bAf = AfricanRegions.isAfrican(b.code);
      if (aAf != bAf) return aAf ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return showModalBottomSheet<cpf.CountryInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _CountryPickerSheet(countries: sorted, isDark: isDark),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final List<cpf.CountryInfo> countries;
  final bool isDark;

  const _CountryPickerSheet({required this.countries, required this.isDark});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late final TextEditingController _searchController;
  late List<cpf.CountryInfo> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    final lower = query.trim().toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries.where((country) {
          return country.name.toLowerCase().contains(lower) ||
              country.code.toLowerCase().contains(lower) ||
              (country.capital?.toLowerCase().contains(lower) == true);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select a country',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                // autofocus off to avoid IME show-animation jank on open
                autofocus: false,
                onChanged: _filterCountries,
                style: GoogleFonts.inter(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search countries, codes, capitals…',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: subtitleColor.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 14,
                            color: subtitleColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterCountries('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.brandBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.brandBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.brandBlue,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.magnifyingGlassMinus,
                            size: 32,
                            color: subtitleColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No countries found',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 64),
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isAfrican = AfricanRegions.isAfrican(
                          country.code,
                        );
                        return InkWell(
                          onTap: () => Navigator.pop(context, country),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country.flagEmoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${country.code} · ${country.phoneCode}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAfrican)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: _regionColor(country.code),
                                    ),
                                    child: Text(
                                      _regionLabel(country.code),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                FaIcon(
                                  FontAwesomeIcons.chevronRight,
                                  size: 13,
                                  color: subtitleColor.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
