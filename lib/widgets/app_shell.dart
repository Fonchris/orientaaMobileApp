import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'discovery/screens/saved_universities_page.dart';
import 'discovery/screens/university_list_page.dart';
import 'home_dashboard.dart';
import 'profile/messaging_service.dart';
import 'profile/messages_page.dart';
import 'profile/profile_page.dart';
import 'search_page.dart';

/// Post-login app shell with bottom navigation:
/// Home (dashboard), Search, Saved, Messages and Profile.
///
/// The tabs stay alive in an [IndexedStack] so streams (messages,
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

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        color: isDark ? AppTheme.brandDark : AppTheme.brandLight,
        child: IndexedStack(
          index: _index,
          children: [
            HomeDashboard(
              onOpenSearch: () => _goTo(1),
              onOpenDiscover: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UniversityListPage(),
                ),
              ),
              onOpenProfile: () => _goTo(4),
            ),
            const SearchPage(),
            const SavedUniversitiesPage(),
            const MessagesPage(),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        height: 68,
        backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.25),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        destinations: [
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.house, size: 17),
            selectedIcon: FaIcon(
              FontAwesomeIcons.houseChimney,
              size: 17,
              color: scheme.primary,
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
            icon: FaIcon(
              FontAwesomeIcons.bookmark,
              size: 17,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.brandInk.withValues(alpha: 0.65),
            ),
            selectedIcon: FaIcon(
              FontAwesomeIcons.solidBookmark,
              size: 17,
              color: scheme.primary,
            ),
            label: l10n.tabSaved,
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
