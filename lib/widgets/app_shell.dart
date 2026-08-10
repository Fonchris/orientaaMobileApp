import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'home_dashboard.dart';
import 'profile/messaging_service.dart';
import 'profile/messages_page.dart';
import 'profile/profile_page.dart';
import 'search_page.dart';

/// Post-login app shell with bottom navigation:
/// Home (dashboard), Search, Messages and Profile.
///
/// The four tabs stay alive in an [IndexedStack] so streams (messages,
/// notifications, profile) keep updating in the background and switching tabs
/// is instant. The Messages tab shows a live unread badge.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'student';
    if (mounted && role != _role) setState(() => _role = role);
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1115),
                    AppTheme.brandNavySurface,
                    const Color(0xFF151A26),
                  ]
                : [
                    const Color(0xFFF7F9FC),
                    Colors.white,
                    const Color(0xFFF3F6FF),
                  ],
          ),
        ),
        child: IndexedStack(
          index: _index,
          children: [
            HomeDashboard(
              onOpenSearch: () => _goTo(1),
              onOpenProfile: () => _goTo(3),
            ),
            const SearchPage(),
            const MessagesPage(),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        height: 68,
        backgroundColor: isDark ? const Color(0xFF10131D) : Colors.white,
        indicatorColor: isDark
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : AppTheme.brandBlue.withValues(alpha: 0.12),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        destinations: [
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.house, size: 17),
            selectedIcon: FaIcon(
              FontAwesomeIcons.houseChimney,
              size: 17,
              color: isDark
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.brandBlue,
            ),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
            selectedIcon: const FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 16,
            ),
            label: l10n.tabSearch,
          ),
          NavigationDestination(
            icon: StreamBuilder<List<ConversationData>>(
              stream: MessagingService().watchConversations(uid),
              builder: (context, snapshot) {
                final conversations = snapshot.data ?? const [];
                final unread = conversations.fold<int>(
                  0,
                  (sum, c) => sum + c.unreadFor(uid),
                );
                return Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  backgroundColor: const Color(0xFFE0245E),
                  child: const FaIcon(FontAwesomeIcons.message, size: 16),
                );
              },
            ),
            label: l10n.tabMessages,
          ),
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.circleUser, size: 18),
            selectedIcon: const FaIcon(
              FontAwesomeIcons.circleUser,
              size: 18,
            ),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
