import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../auth_service.dart';
import '../google_fonts.dart';
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
          'Settings',
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
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final providers = FirebaseAuth.instance.currentUser?.providerData
            .map((p) => p.providerId)
            .toList() ??
        const [];
    final linkedGoogle = providers.contains('google.com');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _sectionLabel(FontAwesomeIcons.userLock, 'Account'),
        const SizedBox(height: 8),
        _card(
          children: [
            _row(
              icon: FontAwesomeIcons.envelope,
              title: 'Email',
              subtitle: email.isEmpty ? 'Not available' : email,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.key,
              title: 'Change password',
              subtitle: 'We will email you a reset link',
              onTap: _changePassword,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.google,
              title: 'Linked Google account',
              subtitle: linkedGoogle ? 'Linked' : 'Not linked',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.bell, 'Notifications'),
        const SizedBox(height: 8),
        _card(
          children: [
            _switchTile(
              icon: FontAwesomeIcons.userPlus,
              title: 'New followers',
              value: _settings.notifyNewFollowers,
              onChanged: (v) => _update((s) => s.copyWith(
                    notifyNewFollowers: v,
                  )),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.message,
              title: 'Messages',
              value: _settings.notifyMessages,
              onChanged: (v) =>
                  _update((s) => s.copyWith(notifyMessages: v)),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.chalkboardUser,
              title: 'Classroom activity',
              value: _settings.notifyClassroomActivity,
              onChanged: (v) => _update(
                (s) => s.copyWith(notifyClassroomActivity: v),
              ),
            ),
            _divider(),
            _switchTile(
              icon: FontAwesomeIcons.calendarCheck,
              title: 'Booking reminders',
              value: _settings.notifyBookingReminders,
              onChanged: (v) => _update(
                (s) => s.copyWith(notifyBookingReminders: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.globe, 'Language'),
        const SizedBox(height: 8),
        _card(
          children: [
            _dropdownTile(
              icon: FontAwesomeIcons.language,
              title: 'Language preference',
              value: _settings.language,
              options: const ['English', 'French', 'Arabic', 'Portuguese'],
              onChanged: (v) => _update((s) => s.copyWith(language: v)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.shieldHalved, 'Privacy'),
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
                        'Who can message you',
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
                          title: Text('Everyone',
                              style: GoogleFonts.inter(fontSize: 13.5)),
                          value: 'everyone',
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('Followers only',
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
              title: 'Show my saved universities',
              value: _settings.showSavedUniversities,
              onChanged: (v) => _update(
                (s) => s.copyWith(showSavedUniversities: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(FontAwesomeIcons.triangleExclamation, 'Account actions'),
        const SizedBox(height: 8),
        _card(
          children: [
            _row(
              icon: FontAwesomeIcons.rightFromBracket,
              title: 'Logout',
              subtitle: 'Sign out of this device',
              iconColor: AppTheme.brandGold,
              onTap: _signingOut ? null : _confirmLogout,
            ),
            _divider(),
            _row(
              icon: FontAwesomeIcons.trash,
              title: 'Delete account',
              subtitle: 'Permanently remove your profile and data',
              iconColor: Theme.of(context).colorScheme.error,
              onTap: _deleteAccount,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Orientaa keeps your data safe. Deleting your account is permanent.',
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
          SnackBar(content: Text('Could not save setting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Account actions ────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _toast('No email address on this account');
      return;
    }
    final ok = await _confirm(
      title: 'Reset your password?',
      message: 'We will send a password reset link to $email.',
      confirmLabel: 'Send link',
    );
    if (ok != true) return;
    try {
      await _auth.sendPasswordResetEmail(email);
      if (mounted) _toast('Password reset link sent to $email');
    } catch (e) {
      if (mounted) _toast('Could not send reset link: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await _confirm(
      title: 'Log out?',
      message: 'You will need to sign in again to access your profile.',
      confirmLabel: 'Log out',
    );
    if (ok != true) return;
    setState(() => _signingOut = true);
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(
            'Delete account?',
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
                    'This permanently removes your profile, posts and settings. '
                    'Type your email to confirm:',
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
                      hintText: email.isEmpty ? 'Enter your email' : email,
                      errorText: controller.text.isNotEmpty && !matches
                          ? 'Email does not match'
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed:
                  email.isNotEmpty && controller.text.trim() == email
                      ? () => Navigator.pop(ctx, true)
                      : null,
              child: const Text('Delete'),
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
            ? 'Please sign in again, then try deleting your account.'
            : 'Could not delete account: ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not delete account: $e');
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
