import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/media_service.dart';
import '../../profile/profile_avatar.dart';
import '../../student_onboarding/step_ui.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';
import 'counselor_profile_page.dart';

/// Guided "Become a counselor" flow for new counselors.
///
/// Four steps: identity -> practice -> pricing & availability ->
/// verification & payout. Saves through the same server functions the setup
/// page uses (saveCounselorProfile + submitVerification), so the result is a
/// profile with `verificationStatus: pending`. Existing data is prefilled if
/// the user already has a partial profile.
class CounselorOnboardingPage extends StatefulWidget {
  final String counselorUid;

  const CounselorOnboardingPage({super.key, required this.counselorUid});

  @override
  State<CounselorOnboardingPage> createState() => _CounselorOnboardingPageState();
}

class _CounselorOnboardingPageState extends State<CounselorOnboardingPage> {
  final CounselorService _service = CounselorService();
  final CounselorFunctions _functions = CounselorFunctions();
  final MediaService _media = MediaService();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _specialtyInput = TextEditingController();
  final TextEditingController _languageInput = TextEditingController();
  final TextEditingController _rate = TextEditingController();
  final TextEditingController _accountName = TextEditingController();
  final TextEditingController _accountNumber = TextEditingController();

  String? _photoUrl;
  final List<String> _specialties = [];
  final List<String> _languages = [];
  String _currency = 'NGN';
  final List<AvailabilityRule> _availability = [];
  String _payoutProvider = 'mobile_money';
  String? _credentialsUrl;
  bool _uploadingCredential = false;

  int _step = 0;
  bool _loaded = false;
  bool _saving = false;
  bool _done = false;

  static const List<String> _timeOptions = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _specialtyInput.dispose();
    _languageInput.dispose();
    _rate.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    // Prefill from a partial profile (re-entry) — public fields from the
    // profile doc, credentials + payout from the owner-only private doc.
    final results = await Future.wait([
      _service.fetchProfile(widget.counselorUid),
      _service.fetchPrivateProfile(widget.counselorUid),
    ]);
    final profile = results[0] as CounselorProfile?;
    final private = results[1] as Map<String, dynamic>?;
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (profile != null) {
        _name.text = profile.displayName == 'Counselor' ? '' : profile.displayName;
        _bio.text = profile.bio;
        _photoUrl = profile.photoUrl;
        _specialties.addAll(profile.specialties);
        _languages.addAll(profile.languages);
        if (profile.hourlyRate > 0) {
          _rate.text = profile.hourlyRate == profile.hourlyRate.roundToDouble()
              ? profile.hourlyRate.toStringAsFixed(0)
              : profile.hourlyRate.toStringAsFixed(2);
        }
        _currency = profile.currency;
        _availability.addAll(profile.availability);
      }
      final privateData = private ?? const <String, dynamic>{};
      _credentialsUrl = privateData['credentialsUrl'] as String?;
      final payout =
          (privateData['payoutAccountDetails'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      if (payout.isNotEmpty) {
        _payoutProvider = (payout['provider'] as String?) ?? 'mobile_money';
        _accountName.text = (payout['accountName'] as String?) ?? '';
        _accountNumber.text = (payout['accountNumber'] as String?) ?? '';
      }
    });
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        final rate = double.tryParse(_rate.text.trim()) ?? 0;
        return rate > 0 && _availability.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickPhoto() async {
    final file = await _media.pickImage();
    if (file == null) return;
    final url = await _media.uploadProfilePhoto(uid: widget.counselorUid, file: file);
    if (mounted) setState(() => _photoUrl = url);
  }

  Future<void> _pickCredential() async {
    final file = await _media.pickImage();
    if (file == null) return;
    setState(() => _uploadingCredential = true);
    try {
      final url = await _uploadCredential(file);
      if (!mounted) return;
      setState(() => _credentialsUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).credentialsSubmitted)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).bookingCreationError)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCredential = false);
    }
  }

  Future<String> _uploadCredential(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = const {'jpg', 'jpeg', 'png', 'heic', 'webp'}.contains(ext) ? ext : 'jpg';
    final ref = FirebaseStorage.instance.ref(
      'counselor_credentials/${widget.counselorUid}.$safeExt',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final rate = double.tryParse(_rate.text.trim()) ?? 0;
      await _functions.saveProfile({
        'displayName': _name.text.trim(),
        'photoUrl': _photoUrl,
        'bio': _bio.text.trim(),
        'specialties': _specialties,
        'languages': _languages,
        'hourlyRate': rate,
        'currency': _currency,
        'availability': _availability.map((a) => a.toMap()).toList(),
        'payoutAccountDetails': {
          'provider': _payoutProvider,
          'accountName': _accountName.text.trim(),
          'accountNumber': _accountNumber.text.trim(),
        },
      });
      if (_credentialsUrl != null) {
        await _functions.submitVerification(credentialUrl: _credentialsUrl!);
      }
      if (!mounted) return;
      setState(() => _done = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingCreationError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_done) return _doneView(context, l10n, isDark);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.counselorOnboardingTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : Column(
              children: [
                _stepBar(context),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: _stepView(context),
                    ),
                  ),
                ),
                StepNavBar(
                  onBack: _step > 0 ? () => setState(() => _step -= 1) : null,
                  onNext: _next,
                  nextEnabled: _canContinue,
                  nextLabel: _step < 3 ? l10n.next : l10n.onboardingFinish,
                  nextIcon: _step < 3
                      ? FontAwesomeIcons.arrowRight
                      : FontAwesomeIcons.solidCircleCheck,
                  loading: _saving,
                  hint: _canContinue
                      ? null
                      : _step == 0
                          ? l10n.enterYourFullName
                          : _step == 2
                              ? '${l10n.availabilityLabel} + ${l10n.hourlyRateLabel(_currency)}'
                              : null,
                ),
              ],
            ),
    );
  }

  Widget _stepBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [
      l10n.onboardingStepIdentity,
      l10n.onboardingStepPractice,
      l10n.onboardingStepPricing,
      l10n.onboardingStepVerify,
    ];
    final activeColor = AppTheme.brandYellow;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppTheme.brandInk.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: current ? 14 : 10,
                        height: current ? 14 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? const Color(0xFFF5B800)
                              : current
                                  ? activeColor
                                  : inactiveColor,
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 7, color: AppTheme.brandInk)
                            : null,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                          color: current
                              ? AppTheme.brandAmber
                              : done
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppTheme.brandInk.withValues(alpha: 0.6))
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : AppTheme.brandInk.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 3)
                  Container(
                    height: 2,
                    width: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: done ? const Color(0xFFF5B800) : inactiveColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _stepView(BuildContext context) {
    switch (_step) {
      case 0:
        return _identityStep(context);
      case 1:
        return _practiceStep(context);
      case 2:
        return _pricingStep(context);
      default:
        return _verifyStep(context);
    }
  }

  Widget _identityStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.userTie,
            label: l10n.onboardingStepIdentity,
            helper: l10n.onboardingIdentitySubtitle,
          ),
        ),
        const SizedBox(height: 20),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: Center(
            child: ProfileAvatar(
              photoUrl: _photoUrl,
              initials: _initials(_name.text),
              size: 96,
              showEditBadge: true,
              onTap: _pickPhoto,
            ),
          ),
        ),
        const SizedBox(height: 20),
        StepReveal(
          delay: const Duration(milliseconds: 120),
          child: BrandTextField(
            controller: _name,
            initialText: _name.text,
            hint: 'Dr. Amina Yusuf',
            label: l10n.enterYourFullName,
            prefixIcon: FontAwesomeIcons.pen,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _practiceStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.suitcaseMedical,
            label: l10n.onboardingStepPractice,
            helper: l10n.onboardingPracticeSubtitle,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, l10n.bioLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _bio,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'I help students with scholarships and university applications…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 120),
          child: _chipEditor(
            context,
            items: _specialties,
            controller: _specialtyInput,
            hint: l10n.specialtiesHint,
            presets: counselorSpecialtyPresets,
            onAdd: _addSpecialty,
            onRemove: (s) => setState(() => _specialties.remove(s)),
            label: l10n.filterSpecialtyLabel,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 180),
          child: _chipEditor(
            context,
            items: _languages,
            controller: _languageInput,
            hint: l10n.languagesHint,
            presets: const ['English', 'French', 'Arabic', 'Portuguese', 'Swahili', 'Hausa'],
            onAdd: _addLanguage,
            onRemove: (s) => setState(() => _languages.remove(s)),
            label: l10n.filterLanguageLabel,
          ),
        ),
      ],
    );
  }

  Widget _pricingStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.wallet,
            label: l10n.onboardingStepPricing,
            helper: l10n.onboardingPricingSubtitle,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: Row(
            children: [
              Expanded(
                child: BrandTextField(
                  controller: _rate,
                  initialText: _rate.text,
                  hint: '50',
                  label: l10n.hourlyRateLabel(_currency),
                  prefixIcon: FontAwesomeIcons.moneyBillWave,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.brandLightOutline,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currency,
                    isExpanded: true,
                    dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : AppTheme.brandInk,
                    ),
                    items: counselorCurrencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'NGN'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.perSession,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.brandInk.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 120),
          child: Row(
            children: [
              Expanded(
                child: _label(context, l10n.availabilityLabel),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _availability.add(
                      const AvailabilityRule(
                        dayOfWeek: 1,
                        startTime: '09:00',
                        endTime: '17:00',
                      ),
                    )),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 11),
                label: Text(
                  l10n.addAvailabilitySlot,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_availability.isEmpty)
          _emptyAvailability(context)
        else
          ..._availability.asMap().entries.map((e) => _availabilityRow(context, e.key)),
      ],
    );
  }

  Widget _verifyStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.shieldHalved,
            label: l10n.onboardingStepVerify,
            helper: l10n.onboardingVerifySubtitle,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: _credentialsCard(context),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, l10n.statusLabel),
              const SizedBox(height: 6),
              _payoutCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doneView(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.solidCircleCheck,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.onboardingDoneTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingDoneBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.brandInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CounselorProfilePage(counselorUid: widget.counselorUid),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    child: Text(l10n.goToProfile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Small form pieces (mirror the setup page's editors) ────────────────

  void _addSpecialty() {
    final v = _specialtyInput.text.trim();
    if (v.isEmpty || _specialties.contains(v)) return;
    setState(() {
      _specialties.add(v);
      _specialtyInput.clear();
    });
  }

  void _addLanguage() {
    final v = _languageInput.text.trim();
    if (v.isEmpty || _languages.contains(v)) return;
    setState(() {
      _languages.add(v);
      _languageInput.clear();
    });
  }

  Widget _label(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
    );
  }

  Widget _chipEditor(
    BuildContext context, {
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required List<String> presets,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, label),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((s) => InputChip(
                      label: Text(s),
                      onDeleted: () => onRemove(s),
                      backgroundColor: AppTheme.brandYellow.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                      deleteIconColor: AppTheme.brandAmber,
                    ))
                .toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(hintText: hint),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onAdd,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
              style: IconButton.styleFrom(backgroundColor: AppTheme.brandYellow),
              color: AppTheme.brandInk,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets
              .where((s) => !items.contains(s))
              .take(6)
              .map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () {
                      if (!items.contains(s)) {
                        setState(() => items.add(s));
                      }
                    },
                    backgroundColor: isDark ? AppTheme.brandCard : AppTheme.brandLight,
                    side: BorderSide.none,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _availabilityRow(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = _availability[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: rule.dayOfWeek,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                  items: [
                    for (var d = 1; d <= 7; d++)
                      DropdownMenuItem(value: d, child: Text(_dayName(l10n, d))),
                  ],
                  onChanged: (v) => setState(() => _availability[index] =
                      _copyRule(rule, dayOfWeek: v ?? 1)),
                ),
              ),
              const SizedBox(width: 8),
              _timeDropdown(
                context,
                value: rule.startTime,
                onChanged: (v) =>
                    setState(() => _availability[index] = _copyRule(rule, startTime: v)),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.endTimeLabel,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.brandAmber),
              ),
              const SizedBox(width: 4),
              _timeDropdown(
                context,
                value: rule.endTime,
                onChanged: (v) =>
                    setState(() => _availability[index] = _copyRule(rule, endTime: v)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _availability.removeAt(index)),
              icon: const FaIcon(FontAwesomeIcons.trash, size: 11),
              label: Text(l10n.removeAvailabilitySlot),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  AvailabilityRule _copyRule(AvailabilityRule r,
          {int? dayOfWeek, String? startTime, String? endTime}) =>
      AvailabilityRule(
        dayOfWeek: dayOfWeek ?? r.dayOfWeek,
        startTime: startTime ?? r.startTime,
        endTime: endTime ?? r.endTime,
      );

  Widget _timeDropdown(BuildContext context,
      {required String value, required ValueChanged<String> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
      items: _timeOptions
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _dayName(AppLocalizations l10n, int day) {
    switch (day) {
      case 1:
        return l10n.dayMonday;
      case 2:
        return l10n.dayTuesday;
      case 3:
        return l10n.dayWednesday;
      case 4:
        return l10n.dayThursday;
      case 5:
        return l10n.dayFriday;
      case 6:
        return l10n.daySaturday;
      default:
        return l10n.daySunday;
    }
  }

  Widget _emptyAvailability(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.calendarPlus,
            size: 15,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.selectSlotHint,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _payoutProvider,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
            items: const [
              DropdownMenuItem(value: 'mobile_money', child: Text('Mobile money')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
              DropdownMenuItem(value: 'card', child: Text('Card')),
            ],
            onChanged: (v) => setState(() => _payoutProvider = v ?? 'mobile_money'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _accountName,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Account name',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _accountNumber,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Account / wallet number',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploaded = _credentialsUrl != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: uploaded
            ? AppTheme.success.withValues(alpha: 0.08)
            : (isDark ? AppTheme.brandCard : AppTheme.brandLight),
        border: Border.all(
          color: uploaded
              ? AppTheme.success.withValues(alpha: 0.3)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.credentialsVerified,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.credentialsUploadHint,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.brandInk.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _uploadingCredential ? null : _pickCredential,
            icon: _uploadingCredential
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FaIcon(
                    uploaded
                        ? FontAwesomeIcons.solidCircleCheck
                        : FontAwesomeIcons.upload,
                    size: 13,
                    color: uploaded ? AppTheme.success : AppTheme.brandAmber,
                  ),
            label: Text(
              uploaded ? l10n.reuploadCredentials : l10n.uploadCredentials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final raw = name.trim();
    if (raw.isEmpty) return 'O';
    final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'O' : letters;
  }
}
