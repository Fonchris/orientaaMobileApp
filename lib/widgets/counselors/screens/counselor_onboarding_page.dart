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
import '../widgets/counselor_form_widgets.dart';
import 'counselor_review_screen.dart';

/// Guided "Become a counselor" flow for new counselors.
///
/// Five steps, in order:
///   1. Identity & credentials — display name, full legal name, government
///      ID, professional credentials, institution.
///   2. Experience & specialty — years of experience, bio, specialties,
///      languages.
///   3. Rate & availability — per-session rate + currency, weekly slots.
///   4. Payout details — Flutterwave payout target.
///   5. Submit — summary + application submission.
///
/// On submit the profile is created with `verificationStatus: pending` and
/// the user is routed to [CounselorReviewScreen], which listens for approval
/// and drops them into the normal counselor experience automatically. The
/// government ID and credentials URLs are stored on the owner-only
/// `counselorPrivate/{uid}` document — never on the public profile students
/// read.
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
  final TextEditingController _legalName = TextEditingController();
  final TextEditingController _institution = TextEditingController();
  final TextEditingController _yearsExperience = TextEditingController();
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
  String? _idDocumentUrl;
  bool _uploadingCredential = false;
  bool _uploadingId = false;

  int _step = 0;
  bool _loaded = false;
  bool _saving = false;

  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _name.dispose();
    _legalName.dispose();
    _institution.dispose();
    _yearsExperience.dispose();
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
    // profile doc, credentials + ID + payout from the owner-only private doc.
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
        _legalName.text = profile.legalName;
        _bio.text = profile.bio;
        _photoUrl = profile.photoUrl;
        _institution.text = profile.institution ?? '';
        _yearsExperience.text = profile.yearsOfExperience == 0
            ? ''
            : '${profile.yearsOfExperience}';
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
      _idDocumentUrl = privateData['idDocumentUrl'] as String?;
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
        return _name.text.trim().isNotEmpty && _legalName.text.trim().isNotEmpty;
      case 1:
        return (int.tryParse(_yearsExperience.text.trim()) ?? -1) >= 0;
      case 2:
        final rate = double.tryParse(_rate.text.trim()) ?? 0;
        return rate > 0 && _availability.isNotEmpty;
      case 3:
        return true;
      case 4:
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

  /// Uploads a sensitive document (ID or credentials) to a private Storage
  /// path. Images and PDFs are both supported (the native file picker
  /// restricts the extensions). The uid lives in its own path segment so the
  /// Storage rules can bind it directly to `request.auth.uid` — the rules
  /// only let the owner write and the owner/admin read.
  Future<String> _uploadDocument(File file, String folder) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt =
        const {'jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'}.contains(ext) ? ext : 'jpg';
    final ref = FirebaseStorage.instance
        .ref('$folder/${widget.counselorUid}/document.$safeExt');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _pickId() async {
    final file = await _media.pickDocument();
    if (file == null) return;
    setState(() => _uploadingId = true);
    try {
      final url = await _uploadDocument(file, 'counselor_ids');
      if (!mounted) return;
      setState(() => _idDocumentUrl = url);
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _uploadingId = false);
    }
  }

  Future<void> _pickCredential() async {
    final file = await _media.pickDocument();
    if (file == null) return;
    setState(() => _uploadingCredential = true);
    try {
      final url = await _uploadDocument(file, 'counselor_credentials');
      if (!mounted) return;
      setState(() => _credentialsUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).credentialsSubmitted)),
      );
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _uploadingCredential = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).bookingCreationError)),
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final rate = double.tryParse(_rate.text.trim()) ?? 0;
      await _functions.saveProfile({
        'displayName': _name.text.trim(),
        'legalName': _legalName.text.trim(),
        'institution': _institution.text.trim(),
        'yearsOfExperience': int.tryParse(_yearsExperience.text.trim()) ?? 0,
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
        'idDocumentUrl': _idDocumentUrl,
      });
      // Always move the application back to `pending` on submit — including a
      // resubmission after a rejection where the counselor kept their earlier
      // credentials (submitVerification accepts a null/empty URL for that).
      await _functions.submitVerification(credentialUrl: _credentialsUrl);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CounselorReviewScreen(counselorUid: widget.counselorUid),
        ),
      );
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                  nextLabel: _step < _totalSteps - 1 ? l10n.next : l10n.onboardingFinish,
                  nextIcon: _step < _totalSteps - 1
                      ? FontAwesomeIcons.arrowRight
                      : FontAwesomeIcons.solidCircleCheck,
                  loading: _saving,
                  hint: _canContinue
                      ? null
                      : _step == 0
                          ? l10n.enterYourFullName
                          : _step == 1
                              ? l10n.yearsExperienceLabel
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
      l10n.onboardingStepExperience,
      l10n.onboardingStepPricing,
      l10n.onboardingStepPayout,
      l10n.onboardingStepSubmit,
    ];
    final activeColor = AppTheme.brandYellow;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppTheme.brandInk.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: List.generate(_totalSteps, (i) {
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
                if (i < _totalSteps - 1)
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
        return _experienceStep(context);
      case 2:
        return _pricingStep(context);
      case 3:
        return _payoutStep(context);
      default:
        return _submitStep(context);
    }
  }

  // ── Step 1: Identity & credentials ────────────────────────────────────

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
          delay: const Duration(milliseconds: 100),
          child: BrandTextField(
            controller: _name,
            initialText: _name.text,
            hint: 'Dr. Amina Yusuf',
            label: l10n.enterYourFullName,
            prefixIcon: FontAwesomeIcons.pen,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        StepReveal(
          delay: const Duration(milliseconds: 140),
          child: BrandTextField(
            controller: _legalName,
            initialText: _legalName.text,
            hint: l10n.legalNameHint,
            label: l10n.legalNameLabel,
            prefixIcon: FontAwesomeIcons.idCard,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        StepReveal(
          delay: const Duration(milliseconds: 180),
          child: BrandTextField(
            controller: _institution,
            initialText: _institution.text,
            hint: l10n.institutionHint,
            label: l10n.institutionLabel,
            prefixIcon: FontAwesomeIcons.buildingColumns,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 220),
          child: CounselorUploadCard(
            title: l10n.idUploadTitle,
            hint: l10n.idUploadHint,
            uploaded: _idDocumentUrl != null,
            uploading: _uploadingId,
            buttonLabel: l10n.uploadId,
            reuploadLabel: l10n.reuploadId,
            onPick: _pickId,
          ),
        ),
        const SizedBox(height: 12),
        StepReveal(
          delay: const Duration(milliseconds: 260),
          child: CounselorUploadCard(
            title: l10n.credentialsVerified,
            hint: l10n.credentialsUploadHint,
            uploaded: _credentialsUrl != null,
            uploading: _uploadingCredential,
            buttonLabel: l10n.uploadCredentials,
            reuploadLabel: l10n.reuploadCredentials,
            onPick: _pickCredential,
          ),
        ),
      ],
    );
  }

  // ── Step 2: Experience & specialty ────────────────────────────────────

  Widget _experienceStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.suitcaseMedical,
            label: l10n.onboardingStepExperience,
            helper: l10n.onboardingPracticeSubtitle,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: BrandTextField(
            controller: _yearsExperience,
            initialText: _yearsExperience.text,
            hint: '5',
            label: l10n.yearsExperienceLabel,
            prefixIcon: FontAwesomeIcons.briefcase,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CounselorFieldLabel(l10n.bioLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _bio,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.bioGuidance,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 140),
          child: CounselorChipEditor(
            items: _specialties,
            controller: _specialtyInput,
            hint: l10n.specialtiesHint,
            presets: counselorSpecialtyPresets,
            label: l10n.filterSpecialtyLabel,
            onAddValue: _addSpecialtyValue,
            onRemove: (s) => setState(() => _specialties.remove(s)),
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 180),
          child: CounselorChipEditor(
            items: _languages,
            controller: _languageInput,
            hint: l10n.languagesHint,
            presets: const [
              'English', 'French', 'Arabic', 'Portuguese', 'Swahili', 'Hausa',
            ],
            label: l10n.filterLanguageLabel,
            onAddValue: _addLanguageValue,
            onRemove: (s) => setState(() => _languages.remove(s)),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Rate & availability ───────────────────────────────────────

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
          child: AvailabilityListEditor(
            initial: _availability,
            onChanged: (rules) => setState(() => _availability
              ..clear()
              ..addAll(rules)),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Payout details ────────────────────────────────────────────

  Widget _payoutStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.moneyCheckDollar,
            label: l10n.onboardingStepPayout,
            helper: l10n.onboardingVerifySubtitle,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: CounselorPayoutCard(
            provider: _payoutProvider,
            accountName: _accountName,
            accountNumber: _accountNumber,
            onProviderChanged: (v) => setState(() => _payoutProvider = v),
          ),
        ),
      ],
    );
  }

  // ── Step 5: Submit ─────────────────────────────────────────────────────

  Widget _submitStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = double.tryParse(_rate.text.trim()) ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StepReveal(
          child: StepSectionLabel(
            icon: FontAwesomeIcons.paperPlane,
            label: l10n.onboardingStepSubmit,
            helper: l10n.underReviewBody,
          ),
        ),
        const SizedBox(height: 18),
        StepReveal(
          delay: const Duration(milliseconds: 60),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? AppTheme.brandCard : Colors.white,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.brandLightOutline,
              ),
            ),
            child: Column(
              children: [
                _checkRow(l10n, _name.text.trim().isNotEmpty, _name.text.trim()),
                _checkRow(l10n, _legalName.text.trim().isNotEmpty, l10n.legalNameLabel),
                _checkRow(l10n, _idDocumentUrl != null, l10n.idUploadTitle),
                _checkRow(l10n, _credentialsUrl != null, l10n.credentialsVerified),
                _checkRow(
                  l10n,
                  int.tryParse(_yearsExperience.text.trim()) != null,
                  l10n.yearsExperienceLabel,
                ),
                _checkRow(l10n, rate > 0, '$_currency $rate ${l10n.perSession}'),
                _checkRow(l10n, _availability.isNotEmpty, l10n.availabilityLabel),
                _checkRow(
                  l10n,
                  _accountNumber.text.trim().isNotEmpty,
                  l10n.onboardingStepPayout,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StepReveal(
          delay: const Duration(milliseconds: 100),
          child: Text(
            l10n.underReviewBody,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppTheme.brandInk.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkRow(AppLocalizations l10n, bool ok, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          FaIcon(
            ok ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circle,
            size: 14,
            color: ok ? AppTheme.success : (isDark ? Colors.white.withValues(alpha: 0.3) : AppTheme.brandInk.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: ok ? FontWeight.w600 : FontWeight.w500,
                color: ok
                    ? (isDark ? Colors.white : AppTheme.brandInk)
                    : (isDark ? Colors.white.withValues(alpha: 0.45) : AppTheme.brandInk.withValues(alpha: 0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────

  /// Adds a specialty from either the free-text input or a tapped preset.
  void _addSpecialtyValue(String value) {
    final v = value.trim();
    if (v.isEmpty || _specialties.contains(v)) return;
    setState(() {
      _specialties.add(v);
      _specialtyInput.clear();
    });
  }

  /// Adds a language from either the free-text input or a tapped preset.
  void _addLanguageValue(String value) {
    final v = value.trim();
    if (v.isEmpty || _languages.contains(v)) return;
    setState(() {
      _languages.add(v);
      _languageInput.clear();
    });
  }

  String _initials(String name) {
    final raw = name.trim();
    if (raw.isEmpty) return 'O';
    final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'O' : letters;
  }
}
