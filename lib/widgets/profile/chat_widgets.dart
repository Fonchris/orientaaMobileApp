import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'profile_models.dart';

/// A single chat message bubble, aligned by sender. Shared by the peer chat
/// (conversations) and the counselor session chat (bookings) so both keep an
/// identical look.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? sentAt;
  final double maxWidthFraction;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.sentAt,
    this.maxWidthFraction = 0.74,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * maxWidthFraction,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          color: isMine
              ? AppTheme.brandYellow
              : isDark
                  ? AppTheme.brandSurface
                  : const Color(0xFFF1F1EE),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                color: isMine
                    ? AppTheme.brandInk
                    : (isDark ? Colors.white : AppTheme.brandInk),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relativeTime(sentAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isMine
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
}

/// Bottom composer bar (input + send button). Disabling [enabled] greys the
/// input out — the counselor chat uses this for its session locking.
class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  final String hintText;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
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
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              enabled: enabled,
              onSubmitted: (_) {
                if (enabled) onSend();
              },
              style: GoogleFonts.inter(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: enabled ? 0.05 : 0.03)
                    : (enabled ? const Color(0xFFF2F2EF) : const Color(0xFFE9E9E5)),
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
          if (sending)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.brandYellow,
                ),
              ),
            )
          else
            Material(
              color: enabled ? AppTheme.brandYellow : AppTheme.brandLightOutline,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: enabled ? onSend : null,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FaIcon(
                    FontAwesomeIcons.paperPlane,
                    size: 15,
                    color: enabled
                        ? AppTheme.brandInk
                        : isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppTheme.brandInk.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
