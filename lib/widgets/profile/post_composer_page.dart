import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';
import '../student_onboarding/step_ui.dart';
import 'media_service.dart';
import 'profile_service.dart';

/// Composes a new post: optional text + optional image. The image is
/// compressed client-side and uploaded to Firebase Storage before the post
/// document is written, so the post always references a live URL.
class PostComposerPage extends StatefulWidget {
  const PostComposerPage({super.key});

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final TextEditingController _text = TextEditingController();
  final MediaService _media = MediaService();
  final ProfileService _service = ProfileService();

  File? _image;
  bool _uploading = false;
  bool _publishing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _busy => _uploading || _publishing;

  Future<void> _pickImage() async {
    try {
      final file = await _media.pickImage();
      if (file != null && mounted) setState(() => _image = file);
    } catch (e) {
      if (mounted) {
        _toast(AppLocalizations.of(context).uploadFailed(e.toString()));
      }
    }
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _busy) return;
    final content = _text.text.trim();
    if (content.isEmpty && _image == null) {
      _toast(l10n.writeSomethingFirst);
      return;
    }

    setState(() {
      _publishing = true;
      _uploading = _image != null;
    });

    String? imageUrl;
    try {
      if (_image != null) {
        imageUrl = await _media.uploadPostImage(
          uid: user.uid,
          file: _image!,
        );
      }
      if (mounted) setState(() => _uploading = false);

      // Author info for the post card header.
      String authorName = user.displayName ?? '';
      String? authorPhotoUrl;
      if (authorName.isEmpty) {
        try {
          final snap = await _service.fetchUser(user.uid);
          final data = snap.data() ?? const <String, dynamic>{};
          authorName = (data['displayName'] as String?) ?? '';
          authorPhotoUrl = data['photoUrl'] as String?;
        } catch (_) {}
      }

      await _service.createPost(
        uid: user.uid,
        authorName: authorName.isEmpty
            ? (user.email?.split('@').first ?? 'Orientaa explorer')
            : authorName,
        authorPhotoUrl: authorPhotoUrl,
        content: content,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postPublished)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // Clean up an uploaded image that never made it into a post.
      if (imageUrl != null) {
        await _media.deleteIfStored(imageUrl);
      }
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _uploading = false;
      });
      _toast(l10n.couldNotPublishPost(e.toString()));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.newPost,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.brandBlue.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _text,
                        autofocus: true,
                        maxLines: 6,
                        maxLength: 500,
                        enabled: !_busy,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.45,
                          color: isDark ? Colors.white : AppTheme.brandInk,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.postHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterStyle: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : AppTheme.brandInk.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      if (_image != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              Image.file(
                                _image!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: l10n.removeImage,
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() => _image = null),
                                    icon: const FaIcon(
                                      FontAwesomeIcons.xmark,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (_uploading)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brandBlue,
                        side: BorderSide(
                          color: AppTheme.brandBlue.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const FaIcon(
                        FontAwesomeIcons.image,
                        size: 14,
                      ),
                      label: Text(
                        l10n.addPhoto,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10131D) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.brandBlue.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: PrimaryButton(
              label: _publishing ? l10n.posting : l10n.publishPost,
              onPressed: _busy ? null : _publish,
              loading: _publishing,
              icon: FontAwesomeIcons.paperPlane,
            ),
          ),
        ],
      ),
    );
  }
}
