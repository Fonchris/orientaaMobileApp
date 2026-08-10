import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';
import 'messaging_service.dart';
import 'profile_avatar.dart';
import 'profile_models.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String currentUid;
  final String otherUid;
  final String otherName;
  final String? otherPhotoUrl;
  final String? otherRole;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.currentUid,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl,
    this.otherRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _service = MessagingService();
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  bool get _isCounsellor => widget.otherRole == 'counsellor';

  @override
  void initState() {
    super.initState();
    _service.markRead(widget.conversationId, widget.currentUid);
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _composer.clear();
    try {
      await _service.sendMessage(
        conversationId: widget.conversationId,
        senderId: widget.currentUid,
        recipientId: widget.otherUid,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        _composer.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotSendMessage(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              photoUrl: widget.otherPhotoUrl,
              initials: initialsFor(widget.otherName),
              size: 36,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_isCounsellor) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppTheme.brandYellow.withValues(alpha: 0.14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.userTie,
                          size: 8,
                          color: AppTheme.brandAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.counsellorSessionChip,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.watchMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.brandBlue,
                    ),
                  );
                }
                final messages = snapshot.data ?? const <ChatMessage>[];
                if (messages.isEmpty) {
                  return _emptyState(isDark);
                }
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[messages.length - 1 - i];
                    return _bubble(msg);
                  },
                );
              },
            ),
          ),
          _composerBar(),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.comments,
              size: 40,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sayHello(widget.otherName.split(' ').first),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.conversationStart,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mine = msg.senderId == widget.currentUid;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          color: mine
              ? AppTheme.brandYellow
              : isDark
                  ? AppTheme.brandSurface
                  : const Color(0xFFF1F1EE),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                color: mine
                    ? AppTheme.brandInk
                    : (isDark ? Colors.white : AppTheme.brandInk),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relativeTime(msg.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: mine
                    ? AppTheme.brandInk.withValues(alpha: 0.6)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppTheme.brandInk.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.brandDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.brandInk.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.inter(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).writeMessage,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF2F2EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                )
              : Material(
                  color: AppTheme.brandYellow,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _send,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 15,
                        color: AppTheme.brandInk,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
