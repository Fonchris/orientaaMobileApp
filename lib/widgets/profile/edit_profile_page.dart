import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import '../student_onboarding/step2_location_page.dart'
    show showCountryPickerDialog;
import '../student_onboarding/step_ui.dart';
import 'profile_models.dart';
import 'profile_service.dart';

/// Education-level and degree options mirror the onboarding step 1 lists so
/// the Edit Profile experience stays consistent with onboarding.
const List<String> _educationLevels = [
  'Secondary school student',
  'Secondary school graduate',
  "Bachelor's in progress",
  "Bachelor's graduate",
  "Master's in progress",
  "Master's graduate",
  'Dropout',
  'Other',
];

const List<String> _degreeLevels = [
  "Bachelor's",
  "Master's",
  'PhD',
  'Diploma / Vocational',
];

const List<String> _fieldsOfInterest = [
  'Arts & Design',
  'Biology',
  'Business',
  'Chemistry',
  'Computer Science',
  'Economics',
  'Engineering',
  'Environmental Science',
  'Liberal Arts & Social Sciences',
  'Mathematics',
  'Medicine',
  'Physics',
  'Psychology',
  'Other',
];

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileService _service = ProfileService();
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profileFuture;

  // Controllers / state populated once the profile loads.
  final TextEditingController _name = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  String? _country;
  String? _countryCode;
  String? _educationLevel;
  String? _degreeGoal;
  final List<String> _fields = [];
  String? _customField;

  bool _saving = false;
  bool _loaded = false;
  String? _nameError;
  String? _bioError;

  @override
  void initState() {
    super.initState();
    _profileFuture = _load();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';
    final snap = await _service.fetchUser(uid);
    return snap;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _seedFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final p = ProfileData.fromSnapshot(snap, email: email);
    final o = p.onboardingData;
    _name.text = p.displayName;
    _city.text = p.city ?? '';
    _bio.text = p.bio ?? '';
    _country = p.country;
    final fields = o['fieldsOfInterest'];
    if (fields is List) {
      for (final f in fields) {
        final s = f.toString();
        if (s == 'Other') {
          _customField = o['customField'] as String?;
        } else {
          _fields.add(s);
        }
      }
    }
    _educationLevel = o['educationLevel'] as String?;
    _degreeGoal = o['desiredDegreeLevel'] as String?;
    _loaded = true;
  }

  Future<void> _pickCountry() async {
    final country = await showCountryPickerDialog(context);
    if (country == null) return;
    setState(() {
      _country = country.name;
      _countryCode = country.code;
    });
  }

  void _toggleField(String field) {
    setState(() {
      if (_fields.contains(field)) {
        _fields.remove(field);
      } else {
        _fields.add(field);
      }
    });
  }

  bool _validate() {
    final nameError =
        _name.text.trim().isEmpty ? 'Full name is required' : null;
    final bioError = _bio.text.length > 250
        ? 'Bio must be 250 characters or fewer'
        : null;
    setState(() {
      _nameError = nameError;
      _bioError = bioError;
    });
    return nameError == null && bioError == null;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'displayName': _name.text.trim(),
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'country': _country,
      'countryCode': _countryCode,
      'bio': FieldValue.delete(), // replaced below when non-empty
      'onboardingData.educationLevel': _educationLevel,
      'onboardingData.desiredDegreeLevel': _degreeGoal,
      'onboardingData.fieldsOfInterest': _fields,
      'onboardingData.customField': _customField,
    };
    if (_bio.text.trim().isNotEmpty) {
      updates['bio'] = _bio.text.trim();
    }

    try {
      await _service.saveProfileFields(uid, updates);
      // Keep Firebase Auth display name in sync (best-effort).
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(
          _name.text.trim(),
        );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.brandBlue,
              ),
            );
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }
          final doc = snapshot.data;
          if (doc == null || doc.data() == null) {
            return _missingProfileState();
          }
          if (!_loaded) _seedFrom(doc);
          return _buildForm();
        },
      ),
    );
  }

  Widget _missingProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.userSlash,
              size: 44,
              color: AppTheme.brandGold,
            ),
            const SizedBox(height: 14),
            Text(
              'No profile found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete the onboarding first so you have a profile to edit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/student-onboarding',
                      (route) => false),
              icon: const FaIcon(FontAwesomeIcons.listCheck, size: 13),
              label: const Text('Complete my profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 44,
              color: AppTheme.brandGold,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load your profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _profileFuture = _load();
                _loaded = false;
              }),
              icon: const FaIcon(FontAwesomeIcons.rotate, size: 13),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _sectionLabel(
                icon: FontAwesomeIcons.userPen,
                label: 'Personal Information',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Full name',
                  hintText: 'e.g. Ada Lovelace',
                  errorText: _nameError,
                  prefixIcon: const FaIcon(
                    FontAwesomeIcons.user,
                    size: 15,
                    color: AppTheme.brandBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _countryField(),
              const SizedBox(height: 12),
              TextField(
                controller: _city,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Lagos',
                  prefixIcon: FaIcon(
                    FontAwesomeIcons.locationDot,
                    size: 15,
                    color: AppTheme.brandBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 4,
                maxLength: 250,
                onChanged: (_) {
                  if (_bioError != null) setState(() => _bioError = null);
                },
                style: GoogleFonts.inter(fontSize: 14.5),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText:
                      'e.g. Aspiring software engineer passionate about renewable energy',
                  errorText: _bioError,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: FaIcon(
                      FontAwesomeIcons.pen,
                      size: 15,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _sectionLabel(
                icon: FontAwesomeIcons.bookOpen,
                label: 'Academic Information',
              ),
              const SizedBox(height: 10),
              _dropdown(
                label: 'Education level',
                value: _educationLevel,
                items: _educationLevels,
                onChanged: (v) => setState(() => _educationLevel = v),
              ),
              const SizedBox(height: 12),
              _dropdown(
                label: 'Degree goal',
                value: _degreeGoal,
                items: _degreeLevels,
                onChanged: (v) => setState(() => _degreeGoal = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Field(s) of interest',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.brandBlue,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _fieldsOfInterest.map((field) {
                  final selected = _fields.contains(field);
                  return ChoiceChip(
                    label: Text(field),
                    selected: selected,
                    onSelected: (_) => _toggleField(field),
                  );
                }).toList(),
              ),
              if (_fields.contains('Other')) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(text: _customField ?? '')
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: _customField?.length ?? 0),
                    ),
                  onChanged: (v) => _customField = v,
                  style: GoogleFonts.inter(fontSize: 14.5),
                  decoration: const InputDecoration(
                    labelText: 'Your custom field',
                    hintText: 'Enter your field of interest...',
                    prefixIcon: FaIcon(
                      FontAwesomeIcons.pen,
                      size: 15,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF10131D)
                : Colors.white,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.brandBlue.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: PrimaryButton(
            label: 'Save changes',
            onPressed: _saving ? null : _save,
            loading: _saving,
            icon: FontAwesomeIcons.check,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel({
    required FaIconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.brandBlue.withValues(alpha: 0.08),
          ),
          child: FaIcon(icon, size: 13, color: AppTheme.brandBlue),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.9)
                : AppTheme.brandBlue,
          ),
        ),
      ],
    );
  }

  Widget _countryField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _pickCountry,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Country',
          prefixIcon: FaIcon(
            FontAwesomeIcons.globe,
            size: 15,
            color: AppTheme.brandBlue,
          ),
          suffixIcon: FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 13,
            color: AppTheme.brandBlue,
          ),
        ),
        child: Text(
          _country ?? 'Tap to select your country',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: _country != null ? FontWeight.w500 : FontWeight.w400,
            color: _country != null
                ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppTheme.brandBlue.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const FaIcon(
          FontAwesomeIcons.caretDown,
          size: 13,
          color: AppTheme.brandBlue,
        ),
      ),
      isExpanded: true,
      dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
