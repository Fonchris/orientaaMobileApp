import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/tier_policy.dart';
import '../models/university_models.dart';
import '../providers/user_tier_provider.dart';
import '../services/saved_universities_service.dart';
import '../widgets/country_flag.dart';
import 'university_detail_page.dart';
import 'university_list_page.dart';

/// Saved tab: all saved universities, reverse-chronological by save date.
///
/// - All tiers: saving is unlimited and ungated.
/// - Pro/Premium: named folders ("Safety schools", "Dream schools") with
///   assign/move support.
/// - Free: flat unsorted list.
class SavedUniversitiesPage extends StatefulWidget {
  const SavedUniversitiesPage({super.key});

  @override
  State<SavedUniversitiesPage> createState() => _SavedUniversitiesPageState();
}

class _SavedUniversitiesPageState extends State<SavedUniversitiesPage> {
  final SavedUniversitiesService _service = SavedUniversitiesService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _folderFilter; // null = All
  bool _isFolderSheetOpen = false;

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid.isNotEmpty) userTierProvider.watch(uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Text(
                    l10n.savedTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.brandInk,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: userTierProvider,
                    builder: (context, _) {
                      if (!TierPolicy.canUseFolders(userTierProvider.tier)) {
                        return const SizedBox.shrink();
                      }
                      return TextButton.icon(
                        onPressed: _isFolderSheetOpen
                            ? null
                            : () => _createFolder(context),
                        icon: const FaIcon(
                          FontAwesomeIcons.folderPlus,
                          size: 13,
                          color: AppTheme.brandAmber,
                        ),
                        label: Text(
                          l10n.newFolder,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandAmber,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: userTierProvider,
                builder: (context, _) => _body(context, userTierProvider.tier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, UserTier tier) {
    final uid = _uid;
    if (uid.isEmpty) return const SizedBox.shrink();
    final useFolders = TierPolicy.canUseFolders(tier);

    return StreamBuilder<List<SavedUniversity>>(
      stream: _service.watchSaved(uid),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? const <SavedUniversity>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            saved.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }
        if (saved.isEmpty) {
          return _emptyState(context);
        }
        final visible = _folderFilter == null
            ? saved
            : saved.where((s) => s.folderId == _folderFilter).toList();
        if (visible.isEmpty) {
          return _folderEmptyState(context);
        }
        return Column(
          children: [
            if (useFolders)
              _folderChips(context, saved),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _savedCard(context, visible[i], tier),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Folder chips (Pro/Premium) ─────────────────────────────────────────

  Widget _folderChips(BuildContext context, List<SavedUniversity> saved) {
    final folderIds = saved.map((s) => s.folderId).whereType<String>().toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: StreamBuilder<List<SavedFolder>>(
        stream: _service.watchFolders(_uid),
        builder: (context, snapshot) {
          final folders = snapshot.data ?? const <SavedFolder>[];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _folderChip(
                  context,
                  label: 'All',
                  active: _folderFilter == null,
                  onTap: () => setState(() => _folderFilter = null),
                ),
                for (final folder in folders)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _folderChip(
                      context,
                      label: folder.name,
                      active: _folderFilter == folder.id,
                      onTap: () =>
                          setState(() => _folderFilter = folder.id),
                      onDelete: folderIds.contains(folder.id)
                          ? null
                          : () => _deleteFolder(folder.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _folderChip(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: onDelete != null ? 6 : 12,
          top: 7,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? AppTheme.brandYellow
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white),
          border: Border.all(
            color: active
                ? AppTheme.brandYellow
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.brandLightOutline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppTheme.brandInk
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.brandInk.withValues(alpha: 0.7)),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 10,
                    color: active
                        ? AppTheme.brandInk.withValues(alpha: 0.6)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.brandInk.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Saved card ──────────────────────────────────────────────────────────

  Widget _savedCard(
    BuildContext context,
    SavedUniversity item,
    UserTier tier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useFolders = TierPolicy.canUseFolders(tier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UniversityDetailPage(
                universityId: item.universityId,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: AppTheme.brandYellow,
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.graduationCap,
                      size: 16,
                      color: AppTheme.brandInk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.universityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.brandInk,
                        ),
                      ),
                      if (item.programName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.programName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.55)
                                : AppTheme.brandInk.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          CountryFlag(
                            countryCode: item.countryCode,
                            countryName: item.country,
                            flagSize: 11,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            relativeSavedTime(item.savedAt),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : AppTheme.brandInk.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from saved',
                  onPressed: () => _service.removeSave(
                    uid: _uid,
                    programId: item.programId,
                  ),
                  icon: FaIcon(
                    FontAwesomeIcons.solidBookmark,
                    size: 14,
                    color: AppTheme.brandYellow,
                  ),
                ),
                if (useFolders)
                  IconButton(
                    tooltip: 'Move to folder',
                    onPressed: () => _assignFolder(item),
                    icon: FaIcon(
                      FontAwesomeIcons.folderOpen,
                      size: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.brandInk.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _assignFolder(SavedUniversity item) async {
    // Fetch current folders to build the picker.
    final folders = await _service.watchFolders(_uid).first;
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'Move to folder',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.inbox,
                size: 14,
                color: AppTheme.brandAmber,
              ),
              title: Text(
                'Unsorted',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...folders.map(
              (f) => ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.folder,
                  size: 14,
                  color: AppTheme.brandAmber,
                ),
                title: Text(
                  f.name,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                trailing: item.folderId == f.id
                    ? const FaIcon(
                        FontAwesomeIcons.check,
                        size: 13,
                        color: AppTheme.brandYellow,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, f.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      await _service.assignFolder(
        uid: _uid,
        programId: item.programId,
        folderId: chosen.isEmpty ? null : chosen,
      );
    }
  }

  // ── Folder create/delete ────────────────────────────────────────────────

  Future<void> _createFolder(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    _isFolderSheetOpen = true;
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New folder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandInk,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) => Navigator.pop(ctx, v),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dream schools',
                    prefixIcon: FaIcon(
                      FontAwesomeIcons.folder,
                      size: 14,
                      color: AppTheme.brandAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _isFolderSheetOpen = false;
    if (name != null && name.trim().isNotEmpty && mounted) {
      await _service.createFolder(uid: _uid, name: name.trim());
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    // Detach saved items first so none keep a dangling folder reference.
    await _service.clearItemsInFolder(uid: _uid, folderId: folderId);
    await _service.deleteFolder(uid: _uid, folderId: folderId);
    if (mounted && _folderFilter == folderId) {
      setState(() => _folderFilter = null);
    }
  }

  // ── Empty states ────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandYellow.withValues(alpha: 0.14),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.bookmark,
                  size: 22,
                  color: AppTheme.brandAmber,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.savedEmptyTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.savedEmptyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.brandInk.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UniversityListPage(),
                ),
              ),
              icon: const FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                size: 13,
              ),
              label: Text(l10n.exploreUniversities),
            ),
          ],
        ),
      ),
    );
  }

  Widget _folderEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            size: 30,
            color: isDark
                ? AppTheme.brandGold
                : AppTheme.brandAmber.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.folderEmptyTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
        ],
      ),
    );
  }
}

String relativeSavedTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inDays >= 1) return 'Saved ${diff.inDays}d ago';
  if (diff.inHours >= 1) return 'Saved ${diff.inHours}h ago';
  return 'Saved just now';
}
