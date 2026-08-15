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

/// Counselor profile setup / editor.
///
/// Public fields (photo, bio, specialties, languages, rate, availability) are
/// written via `saveCounselorProfile`; credentials upload to Storage and the
/// verification submission go through `submitVerification`. `verificationStatus`
/// can only move to `pending` by the owner — the server never lets a client
/// self-approve. The credentials URL and Flutterwave payout target are stored
/// on the owner-only `counselorPrivate/{uid}` document — never on the public
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
  bool _loaded = false;
  bool _saving = false;
  bool _uploadingCredential = false;

  static const List<String> _payoutProviders = [
    'mobile_money',
    'bank_transfer',
    'card',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  Future<void> _loadProfile() async {
    // Public fields come from the marketplace profile; the credentials URL
    // and payout target come from the owner-only `counselorPrivate/{uid}`
    // document (students never see those fields on the public profile).
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

  void _addAvailability() {
    setState(() => _availability.add(const AvailabilityRule(
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '17:00',
        )));
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
          _fieldLabel(context, l10n.enterYourFullName),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(hintText: 'Dr. Amina Yusuf'),
          ),
          const SizedBox(height: 16),
          _fieldLabel(context, l10n.bioLabel),
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
          const SizedBox(height: 16),
          _fieldLabel(context, l10n.filterSpecialtyLabel),
          const SizedBox(height: 6),
          _chipEditor(
            context,
            items: _specialties,
            controller: _specialtyInput,
            hint: l10n.specialtiesHint,
            onAdd: _addSpecialty,
            onRemove: (s) => setState(() => _specialties.remove(s)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: counselorSpecialtyPresets
                .where((s) => !_specialties.contains(s))
                .take(6)
                .map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _specialties.add(s)),
                      backgroundColor: isDark ? AppTheme.brandCard : AppTheme.brandLight,
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          _fieldLabel(context, l10n.filterLanguageLabel),
          const SizedBox(height: 6),
          _chipEditor(
            context,
            items: _languages,
            controller: _languageInput,
            hint: l10n.languagesHint,
            onAdd: _addLanguage,
            onRemove: (s) => setState(() => _languages.remove(s)),
          ),
          const SizedBox(height: 16),
          _fieldLabel(context, l10n.hourlyRateLabel(_currency)),
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
          Row(
            children: [
              Expanded(
                child: _fieldLabel(context, l10n.availabilityLabel),
              ),
              TextButton.icon(
                onPressed: _addAvailability,
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
          if (_availability.isEmpty)
            _emptyAvailability(context)
          else
            ..._availability.asMap().entries.map((e) => _availabilityRow(context, e.key)),
          const SizedBox(height: 20),
          _fieldLabel(context, l10n.statusLabel),
          const SizedBox(height: 6),
          _payoutCard(context),
          const SizedBox(height: 20),
          _credentialsCard(context),
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

  Widget _chipEditor(
    BuildContext context, {
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                  items: [
                    for (var d = 1; d <= 7; d++)
                      DropdownMenuItem(value: d, child: Text(_dayName(l10n, d))),
                  ],
                  onChanged: (v) => setState(() => _availability[index] = _copyRule(rule, dayOfWeek: v ?? 1)),
                ),
              ),
              const SizedBox(width: 8),
              _timeDropdown(
                context,
                value: rule.startTime,
                onChanged: (v) => setState(() => _availability[index] = _copyRule(rule, startTime: v)),
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
                onChanged: (v) => setState(() => _availability[index] = _copyRule(rule, endTime: v)),
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

  AvailabilityRule _copyRule(AvailabilityRule r, {int? dayOfWeek, String? startTime, String? endTime}) =>
      AvailabilityRule(
        dayOfWeek: dayOfWeek ?? r.dayOfWeek,
        startTime: startTime ?? r.startTime,
        endTime: endTime ?? r.endTime,
      );

  Widget _timeDropdown(BuildContext context, {required String value, required ValueChanged<String> onChanged}) {
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

  static const List<String> _timeOptions = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00',
  ];

  String _dayName(AppLocalizations l10n, int day) {
    switch (day) {
      case 1: return l10n.dayMonday;
      case 2: return l10n.dayTuesday;
      case 3: return l10n.dayWednesday;
      case 4: return l10n.dayThursday;
      case 5: return l10n.dayFriday;
      case 6: return l10n.daySaturday;
      default: return l10n.daySunday;
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
            color: isDark ? AppTheme.brandGold : AppTheme.brandInk.withValues(alpha: 0.4),
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
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
            items: _payoutProviders
                .map((p) => DropdownMenuItem(value: p, child: Text(p.replaceAll('_', ' '))))
                .toList(),
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
                    uploaded ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.upload,
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

  Widget _fieldLabel(BuildContext context, String label) {
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

  String _initials(String name) {
    final raw = name.trim();
    if (raw.isEmpty) return 'O';
    final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'O' : letters;
  }
}
