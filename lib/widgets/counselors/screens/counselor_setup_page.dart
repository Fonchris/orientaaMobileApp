import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../../profile/media_service.dart';
import '../../profile/profile_avatar.dart';
import '../counselor_constants.dart';
import '../models/counselor_models.dart';
import '../services/counselor_functions.dart';
import '../services/counselor_service.dart';
import '../widgets/counselor_form_widgets.dart';

/// Counselor profile setup / editor.
///
/// Public fields (photo, legal/display name, bio, specialties, languages,
/// rate, availability) are written via `saveCounselorProfile`; credentials
/// upload to Storage and the verification submission go through
/// `submitVerification`. `verificationStatus` can only move to `pending` by
/// the owner — the server never lets a client self-approve. The government
/// ID, credentials URL and Flutterwave payout target are stored on the
/// owner-only `counselorPrivate/{uid}` document — never on the public
/// profile that students read.
///
/// Note: credentials must be an image for now (PDF upload needs `file_picker`).
class CounselorSetupPage extends StatefulWidget {
  final String counselorUid;

  const CounselorSetupPage({super.key, required this.counselorUid});

  @override
  State<CounselorSetupPage> createState() => _CounselorSetupPageState();
}

class _CounselorSetupPageState extends State<CounselorSetupPage> {
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

  String _verificationStatus = 'pending';
  String? _credentialsUrl;
  String? _idDocumentUrl;
  bool _loaded = false;
  bool _saving = false;
  bool _uploadingCredential = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  Future<void> _loadProfile() async {
    // Public fields come from the marketplace profile; the credentials URL,
    // government ID and payout target come from the owner-only
    // `counselorPrivate/{uid}` document (students never see those fields).
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
        _rate.text = profile.hourlyRate == 0
            ? ''
            : (profile.hourlyRate == profile.hourlyRate.roundToDouble()
                ? profile.hourlyRate.toStringAsFixed(0)
                : profile.hourlyRate.toStringAsFixed(2));
        _currency = profile.currency;
        _availability.addAll(profile.availability);
        _verificationStatus = profile.verificationStatus;
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
      await _functions.submitVerification(credentialUrl: url);
      if (!mounted) return;
      setState(() => _verificationStatus = 'pending');
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

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaved)),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookingCreationError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.counselorSetupTitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.counselorSetupTitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _verificationBanner(context),
          const SizedBox(height: 16),
          Center(
            child: ProfileAvatar(
              photoUrl: _photoUrl,
              initials: _initials(_name.text),
              size: 92,
              showEditBadge: true,
              onTap: _pickPhoto,
            ),
          ),
          const SizedBox(height: 18),
          CounselorFieldLabel(l10n.enterYourFullName),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(hintText: 'Dr. Amina Yusuf'),
          ),
          const SizedBox(height: 14),
          CounselorFieldLabel(l10n.legalNameLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _legalName,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(hintText: l10n.legalNameHint),
          ),
          const SizedBox(height: 14),
          CounselorFieldLabel(l10n.institutionLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _institution,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(hintText: l10n.institutionHint),
          ),
          const SizedBox(height: 14),
          CounselorFieldLabel(l10n.yearsExperienceLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _yearsExperience,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(hintText: '5'),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          CounselorChipEditor(
            items: _specialties,
            controller: _specialtyInput,
            hint: l10n.specialtiesHint,
            label: l10n.filterSpecialtyLabel,
            presets: counselorSpecialtyPresets,
            onAddValue: _addSpecialtyValue,
            onRemove: (s) => setState(() => _specialties.remove(s)),
          ),
          const SizedBox(height: 16),
          CounselorChipEditor(
            items: _languages,
            controller: _languageInput,
            hint: l10n.languagesHint,
            label: l10n.filterLanguageLabel,
            onAddValue: _addLanguageValue,
            onRemove: (s) => setState(() => _languages.remove(s)),
          ),
          const SizedBox(height: 16),
          CounselorFieldLabel(l10n.hourlyRateLabel(_currency)),
          const SizedBox(height: 6),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const FaIcon(FontAwesomeIcons.wallet, size: 13),
              hintText: '50',
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(),
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
          const SizedBox(height: 20),
          AvailabilityListEditor(
            initial: _availability,
            onChanged: (rules) => setState(() => _availability
              ..clear()
              ..addAll(rules)),
          ),
          const SizedBox(height: 20),
          CounselorFieldLabel(l10n.statusLabel),
          const SizedBox(height: 6),
          CounselorPayoutCard(
            provider: _payoutProvider,
            accountName: _accountName,
            accountNumber: _accountNumber,
            onProviderChanged: (v) => setState(() => _payoutProvider = v),
          ),
          const SizedBox(height: 20),
          CounselorUploadCard(
            title: l10n.credentialsVerified,
            hint: l10n.credentialsUploadHint,
            uploaded: _credentialsUrl != null,
            uploading: _uploadingCredential,
            buttonLabel: l10n.uploadCredentials,
            reuploadLabel: l10n.reuploadCredentials,
            onPick: _pickCredential,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(l10n.saveProfile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_verificationStatus == 'approved') return const SizedBox.shrink();

    final rejected = _verificationStatus == 'rejected';
    final message = rejected ? l10n.verificationRejectedNote : l10n.verificationPendingNote;
    final color = rejected ? AppTheme.danger : AppTheme.brandAmber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          FaIcon(
            rejected ? FontAwesomeIcons.triangleExclamation : FontAwesomeIcons.hourglassHalf,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? Colors.white : AppTheme.brandInk,
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
