import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'chat_page.dart';
import 'messaging_service.dart';
import 'profile_avatar.dart';
import 'profile_models.dart';
import 'profile_service.dart';

/// Inbox: conversations sorted by most recent message, with unread indicators
/// and a "New message" flow that searches for a user to chat with.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final MessagingService _service = MessagingService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'missing';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Messages',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New message',
                    onPressed: () => _openNewMessage(),
                    icon: FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 16,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ConversationData>>(
                stream: _service.watchConversations(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.brandBlue,
                      ),
                    );
                  }
                  final conversations =
                      snapshot.data ?? const <ConversationData>[];
                  if (conversations.isEmpty) {
                    return _emptyState(isDark);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _conversationTile(conversations[i], uid),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationTile(ConversationData conversation, String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = conversation.unreadFor(uid);
    final lastFromMe = conversation.lastSenderId == uid;
    final preview = conversation.lastMessage.isEmpty
        ? 'No messages yet'
        : lastFromMe
            ? 'You: ${conversation.lastMessage}'
            : conversation.lastMessage;

    return Material(
      color: isDark
          ? (unread > 0
              ? AppTheme.brandBlue.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05))
          : (unread > 0
              ? const Color(0xFFEAF1FF)
              : Colors.white),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openConversation(conversation, uid),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ProfileAvatar(
                photoUrl: conversation.otherPhotoUrl(uid),
                initials: initialsFor(conversation.otherName(uid)),
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherName(uid),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.brandInk,
                            ),
                          ),
                        ),
                        Text(
                          relativeTime(conversation.lastMessageAt),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: unread > 0
                                ? AppTheme.brandGold
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : AppTheme.brandInk.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: unread > 0
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppTheme.brandInk)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : AppTheme.brandInk.withValues(
                                          alpha: 0.55,
                                        ),
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brandGold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unread',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConversation(
    ConversationData conversation,
    String uid,
  ) async {
    try {
      await _service.markRead(conversation.id, uid);
    } catch (_) {
      // Reading state is best-effort; never block opening the chat.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversation.id,
          currentUid: uid,
          otherUid: conversation.otherUid(uid) ?? '',
          otherName: conversation.otherName(uid),
          otherPhotoUrl: conversation.otherPhotoUrl(uid),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.brandGold, AppTheme.brandBlue],
                ),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.comments,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a conversation with a student or counsellor.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openNewMessage,
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 13),
              label: const Text('New message'),
            ),
          ],
        ),
      ),
    );
  }

  // ── New message flow ───────────────────────────────────────────────────

  Future<void> _openNewMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF10131D)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UserPickerSheet(),
    );
    if (selected == null || !mounted) return;

    final otherUid = selected['uid'] as String;
    if (otherUid == uid) return;

    final myDoc = await ProfileService().fetchUser(uid);
    final myData = myDoc.data() ?? const <String, dynamic>{};

    // Respect the recipient's message privacy setting.
    final allowed = await MessagingService().canMessage(uid, otherUid);
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This user only accepts messages from people they follow.',
            ),
          ),
        );
      }
      return;
    }

    final conversationId = await MessagingService().ensureConversation(
      myUid: uid,
      otherUid: otherUid,
      myProfile: {
        'displayName': myData['displayName'] ?? '',
        'photoUrl': myData['photoUrl'],
      },
      otherProfile: {
        'displayName': selected['displayName'],
        'photoUrl': selected['photoUrl'],
      },
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          currentUid: uid,
          otherUid: otherUid,
          otherName: selected['displayName'] as String,
          otherPhotoUrl: selected['photoUrl'] as String?,
          otherRole: selected['role'] as String?,
        ),
      ),
    );
  }
}

/// Bottom sheet used to search for a user and start a 1:1 conversation.
class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet();

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  Stream<List<ConnectionUser>>? _results;
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _results = query.trim().isEmpty
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .where('displayName', isGreaterThanOrEqualTo: query.trim())
                .where('displayName', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
                .limit(25)
                .snapshots()
                .map((snap) => snap.docs
                    .where((d) => d.id != _me)
                    .map(ConnectionUser.fromSnapshot)
                    .toList());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'New message',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: 'Search students and counsellors...',
                  prefixIcon: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 15,
                    color: AppTheme.brandBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results == null
                  ? _prompt(isDark)
                  : StreamBuilder<List<ConnectionUser>>(
                      stream: _results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.brandBlue,
                            ),
                          );
                        }
                        final users = snapshot.data ?? const [];
                        if (users.isEmpty) {
                          return Center(
                            child: Text(
                              'No users found',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppTheme.brandInk.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            final u = users[i];
                            return ListTile(
                              leading: ProfileAvatar(
                                photoUrl: u.photoUrl,
                                initials: initialsFor(u.displayName),
                                size: 42,
                              ),
                              title: Text(
                                u.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const FaIcon(
                                FontAwesomeIcons.solidMessage,
                                size: 14,
                                color: AppTheme.brandBlue,
                              ),
                              onTap: () => Navigator.pop(context, {
                                'uid': u.uid,
                                'displayName': u.displayName,
                                'photoUrl': u.photoUrl,
                                'role': u.role,
                              }),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prompt(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 30,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Search by name to start a conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
