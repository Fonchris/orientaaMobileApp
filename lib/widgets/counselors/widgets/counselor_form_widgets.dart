import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/counselor_models.dart';

/// Shared form pieces for the counselor onboarding wizard and the profile
/// editor/setup page. Both screens used to duplicate these widgets inline;
/// they now live here so a fix or polish lands in one place.

/// Half-hour slots offered in the availability time pickers.
const List<String> counselorTimeOptions = [
  '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
  '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
  '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
  '20:00',
];

/// Localized weekday name for `dayOfWeek` (1 = Monday … 7 = Sunday).
String counselorDayName(AppLocalizations l10n, int day) {
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

/// Small section label used above form editors.
class CounselorFieldLabel extends StatelessWidget {
  final String label;

  const CounselorFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Chip editor for tag lists (specialties, languages): selected chips, a
/// free-text input with an add button, and optional preset chips to tap.
class CounselorChipEditor extends StatelessWidget {
  final List<String> items;
  final TextEditingController controller;
  final String hint;
  final String? label;
  final List<String> presets;
  /// Receives the value to add — from the free-text row (the controller's
  /// text) OR from a tapped preset chip. The parent decides how to store it.
  final ValueChanged<String> onAddValue;
  final ValueChanged<String> onRemove;

  const CounselorChipEditor({
    super.key,
    required this.items,
    required this.controller,
    required this.hint,
    required this.onAddValue,
    required this.onRemove,
    this.label,
    this.presets = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          CounselorFieldLabel(label!),
          const SizedBox(height: 8),
        ],
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
                onSubmitted: (_) => onAddValue(controller.text),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(hintText: hint),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => onAddValue(controller.text),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
              style: IconButton.styleFrom(backgroundColor: AppTheme.brandYellow),
              color: AppTheme.brandInk,
            ),
          ],
        ),
        if (presets.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets
                .where((s) => !items.contains(s))
                .take(6)
                .map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () => onAddValue(s),
                      backgroundColor: isDark ? AppTheme.brandCard : AppTheme.brandLight,
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Recurring weekly availability editor: add/remove day + time-range rows.
///
/// Owns the list internally and reports every change through [onChanged], so
/// both the wizard and the editor page stay in sync without duplicating the
/// row UI.
class AvailabilityListEditor extends StatefulWidget {
  final List<AvailabilityRule> initial;
  final ValueChanged<List<AvailabilityRule>> onChanged;

  const AvailabilityListEditor({
    super.key,
    this.initial = const [],
    required this.onChanged,
  });

  @override
  State<AvailabilityListEditor> createState() => _AvailabilityListEditorState();
}

class _AvailabilityListEditorState extends State<AvailabilityListEditor> {
  late final List<AvailabilityRule> _rules = [...widget.initial];

  void _mutate() => widget.onChanged(List.unmodifiable(_rules));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: CounselorFieldLabel(l10n.availabilityLabel)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _rules.add(const AvailabilityRule(
                    dayOfWeek: 1,
                    startTime: '09:00',
                    endTime: '17:00',
                  ));
                });
                _mutate();
              },
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
        if (_rules.isEmpty)
          Container(
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
          )
        else
          ..._rules.asMap().entries.map((e) => _row(context, e.key)),
      ],
    );
  }

  Widget _row(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = _rules[index];

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
                      DropdownMenuItem(value: d, child: Text(counselorDayName(l10n, d))),
                  ],
                  onChanged: (v) {
                    setState(() => _rules[index] = _copyRule(rule, dayOfWeek: v ?? 1));
                    _mutate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              _timeDropdown(
                context,
                value: rule.startTime,
                onChanged: (v) {
                  setState(() => _rules[index] = _copyRule(rule, startTime: v));
                  _mutate();
                },
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
                onChanged: (v) {
                  setState(() => _rules[index] = _copyRule(rule, endTime: v));
                  _mutate();
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _rules.removeAt(index));
                _mutate();
              },
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

  Widget _timeDropdown(
    BuildContext context, {
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      dropdownColor: isDark ? AppTheme.brandCard : Colors.white,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
      items: counselorTimeOptions
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Flutterwave payout target editor (mobile money / bank / card).
class CounselorPayoutCard extends StatelessWidget {
  final String provider;
  final TextEditingController accountName;
  final TextEditingController accountNumber;
  final ValueChanged<String> onProviderChanged;

  const CounselorPayoutCard({
    super.key,
    required this.provider,
    required this.accountName,
    required this.accountNumber,
    required this.onProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            initialValue: provider,
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
            onChanged: (v) {
              if (v != null) onProviderChanged(v);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: accountName,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Account name',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: accountNumber,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Account / wallet number',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Upload card for sensitive documents (government ID, professional
/// credentials). Uploaded state renders a success tint + re-upload action.
class CounselorUploadCard extends StatelessWidget {
  final String title;
  final String hint;
  final bool uploaded;
  final bool uploading;
  final String buttonLabel;
  final String reuploadLabel;
  final VoidCallback onPick;

  const CounselorUploadCard({
    super.key,
    required this.title,
    required this.hint,
    required this.uploaded,
    required this.uploading,
    required this.buttonLabel,
    required this.reuploadLabel,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
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
            onPressed: uploading ? null : onPick,
            icon: uploading
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
              uploaded ? reuploadLabel : buttonLabel,
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
}
