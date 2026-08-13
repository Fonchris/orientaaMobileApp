import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../models/university_models.dart';
import '../services/saved_universities_service.dart';
import '../services/user_interactions_service.dart';

/// Bookmark toggle shown on discovery cards and the detail page.
///
/// Saving is available to ALL tiers and unlimited — this is deliberately NOT
/// gated. The button streams the saved state from
/// `saved_universities/{uid}/items/{programId}`, toggles optimistically and
/// logs `save`/`unsave` interaction events (fire-and-forget).
class SaveButton extends StatefulWidget {
  final RecommendedProgram program;
  final String? folderId;
  final double iconSize;
  final bool useAppBarStyle; // larger, more visible on the detail page

  const SaveButton({
    super.key,
    required this.program,
    this.folderId,
    this.iconSize = 15,
    this.useAppBarStyle = false,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  final SavedUniversitiesService _service = SavedUniversitiesService();
  final UserInteractionsService _interactions = const UserInteractionsService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _toggle(bool currentlySaved) async {
    if (_uid.isEmpty) return;
    try {
      final nowSaved = await _service.toggleSave(
        uid: _uid,
        program: widget.program,
        folderId: widget.folderId,
      );
      // Fire-and-forget: the event log must never surface errors to the user.
      unawaited(
        _interactions.log(
          uid: _uid,
          type: nowSaved ? 'save' : 'unsave',
          programId: widget.program.programId,
          universityId: widget.program.universityId,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotUpdateSaved(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: _service.watchSavedStatus(uid, widget.program.programId),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? false;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor = saved
            ? AppTheme.brandYellow
            : (isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.brandInk.withValues(alpha: 0.55));

        final icon = saved
            ? FontAwesomeIcons.solidBookmark
            : FontAwesomeIcons.bookmark;

        return IconButton(
          tooltip: saved ? 'Remove from saved' : 'Save university',
          onPressed: () => _toggle(saved),
          icon: FaIcon(icon, size: widget.iconSize, color: iconColor),
          style: widget.useAppBarStyle
              ? IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(9),
                )
              : null,
        );
      },
    );
  }
}
