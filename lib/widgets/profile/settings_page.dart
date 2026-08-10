import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../auth_service.dart';
import '../google_fonts.dart';
import '../../main.dart' show localeProvider, themeProvider;
import '../locale_provider.dart';
import 'profile_models.dart';
import 'profile_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProfileService _service = ProfileService();
  final AuthService _auth = AuthService();

  ProfileSettings _settings = const ProfileSettings();
  bool _saving = false;
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).settingsTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.brandBlue,
              ),
            );
          }
          final data = snapshot.data?.data();
          if (data != null) {
            _settings = ProfileSettings.fromMap(
              (data['settings'] as Map<String, dynamic>?) ?? const {},
            );
          }
          return _buildList(context);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final providers = FirebaseAuth.instance.currentUser?.providerData
            .map((p) => p.providerId)
            .toList() ??
        const [];
    final linkedGoogle = providers.contains('google.com');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _sectionLabel(FontAwesomeIcons.userLock, l10n.accountSection),
        const SizedBox(height: 8),
        _card(
          children: [
            _row(
              icon: FontAwesomeIcons.envelope,
              title: l10n.labelEmail,
              subtitle: email.isEmpty ? l10n.notAvailable : email,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.key,
              title: l10n.changePassword,
              subtitle: l10n.passwordResetHint,
              onTap: _changePassword,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.google,
              title: l10n.linkedGoogle,
              subtitle: linkedGoogle ? l10n.linked : l10n.notLinked,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.palette, l10n.appearanceSection),
        const SizedBox(height: 8),
        _card(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.palette,
                        size: 14,
                        color: AppTheme.brandBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.themePreference,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                        icon: const FaIcon(
                          FontAwesomeIcons.display,
                          size: 13,
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                        icon: const FaIcon(
                          FontAwesomeIcons.sun,
                          size: 13,
                        ),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                        icon: const FaIcon(
                          FontAwesomeIcons.moon,
                          size: 13,
                        ),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        themeProvider.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.bell, l10n.notificationsSection),
        const SizedBox(height: 8),
        _card(
          children: [
            _switchTile(
              icon: FontAwesomeIcons.userPlus,
              title: l10n.settingNewFollowers,
              value: _settings.notifyNewFollowers,
              onChanged: (v) => _update((s) => s.copyWith(
                    notifyNewFollowers: v,
                  )),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.message,
              title: l10n.settingMessages,
              value: _settings.notifyMessages,
              onChanged: (v) =>
                  _update((s) => s.copyWith(notifyMessages: v)),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.chalkboardUser,
              title: l10n.settingClassroomActivity,
              value: _settings.notifyClassroomActivity,
              onChanged: (v) => _update(
                (s) => s.copyWith(notifyClassroomActivity: v),
              ),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.calendarCheck,
              title: l10n.settingBookingReminders,
              value: _settings.notifyBookingReminders,
              onChanged: (v) => _update(
                (s) => s.copyWith(notifyBookingReminders: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.globe, l10n.languageSection),
        const SizedBox(height: 8),
        _card(
          children: [
            _dropdownTile(
              icon: FontAwesomeIcons.language,
              title: l10n.languagePreference,
              value: localeProvider.languageName,
              options: const ['English', 'French', 'Arabic', 'Portuguese'],
              onChanged: (v) async {
                await localeProvider.setLocale(
                  Locale(LocaleProvider.codeForLanguage(v)),
                );
                _update((s) => s.copyWith(language: v));
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.shieldHalved, l10n.privacySection),
        const SizedBox(height: 8),
        _card(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.message,
                        size: 14,
                        color: AppTheme.brandBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.whoCanMessageYou,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RadioGroup<String>(
                    groupValue: _settings.messagePrivacy,
                    onChanged: (v) => _update(
                      (s) => s.copyWith(messagePrivacy: v ?? 'everyone'),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.everyone,
                              style: GoogleFonts.inter(fontSize: 13.5)),
                          value: 'everyone',
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(l10n.followersOnly,
                              style: GoogleFonts.inter(fontSize: 13.5)),
                          value: 'followers',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.eye,
              title: l10n.showSavedUniversities,
              value: _settings.showSavedUniversities,
              onChanged: (v) => _update(
                (s) => s.copyWith(showSavedUniversities: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(
          FontAwesomeIcons.triangleExclamation,
          l10n.accountActions,
        ),
        const SizedBox(height: 8),
        _card(
          children: [
            _row(
              icon: FontAwesomeIcons.rightFromBracket,
              title: l10n.logout,
              subtitle: l10n.logoutHint,
              iconColor: AppTheme.brandGold,
              onTap: _signingOut ? null : _confirmLogout,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.trash,
              title: l10n.deleteAccount,
              subtitle: l10n.deleteAccountHint,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: _deleteAccount,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.dataSafetyNote,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.4)
                : AppTheme.brandInk.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── Settings persistence ───────────────────────────────────────────────

  Future<void> _update(
    ProfileSettings Function(ProfileSettings) transform,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;
    setState(() {
      _saving = true;
      _settings = transform(_settings);
    });
    try {
      await _service.saveSettings(uid, _settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotSaveSetting(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Account actions ────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _toast(l10n.noEmailOnAccount);
      return;
    }
    final ok = await _confirm(
      title: l10n.resetPasswordTitle,
      message: l10n.resetPasswordMessage(email),
      confirmLabel: l10n.sendLink,
    );
    if (ok != true) return;
    try {
      await _auth.sendPasswordResetEmail(email);
      if (mounted) _toast(l10n.passwordResetSent(email));
    } catch (e) {
      if (mounted) _toast(l10n.couldNotSendReset(e.toString()));
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      title: l10n.logoutConfirmTitle,
      message: l10n.logoutConfirmMessage,
      confirmLabel: l10n.logOut,
    );
    if (ok != true) return;
    setState(() => _signingOut = true);
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(
            l10n.deleteAccountConfirmTitle,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              final matches = controller.text.trim() == email;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deleteAccountConfirmMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: email.isEmpty ? l10n.enterYourEmail : email,
                      errorText: controller.text.isNotEmpty && !matches
                          ? l10n.emailDoesNotMatch
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed:
                  email.isNotEmpty && controller.text.trim() == email
                      ? () => Navigator.pop(ctx, true)
                      : null,
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
      await FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        e.code == 'requires-recent-login'
            ? AppLocalizations.of(context).requiresRecentLogin
            : AppLocalizations.of(context)
                .couldNotDeleteAccount(e.message ?? e.code),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(AppLocalizations.of(context).couldNotDeleteAccount(e.toString()));
    }
  }

  // ── Reusable tiles ─────────────────────────────────────────────────────

  Widget _sectionLabel(FaIconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.brandBlue.withValues(alpha: 0.08),
            ),
            child: FaIcon(icon, size: 12, color: AppTheme.brandBlue),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppTheme.brandBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 52,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppTheme.brandBlue.withValues(alpha: 0.06),
    );
  }

  Widget _row({
    required FaIconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.brandBlue);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.1),
        ),
        child: FaIcon(icon, size: 14, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppTheme.brandInk,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
            ),
      trailing: onTap == null
          ? null
          : FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : AppTheme.brandInk.withValues(alpha: 0.35),
            ),
    );
  }

  Widget _switchTile({
    required FaIconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
        child: FaIcon(
          icon,
          size: 14,
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : AppTheme.brandBlue,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppTheme.brandInk,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _dropdownTile({
    required FaIconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
        child: FaIcon(
          icon,
          size: 14,
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : AppTheme.brandBlue,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppTheme.brandInk,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.brandBlue,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
