import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/counselor_models.dart';
import '../services/counselor_service.dart';
import '../widgets/session_card.dart';
import 'counselor_directory_page.dart';
import 'session_detail_page.dart';

/// "My Sessions" — every booking for the signed-in user (student view shows
/// counselors, counselor view shows students), grouped into Upcoming and
/// Past. Tapping a session opens the detail/confirm/chat page.
class MySessionsPage extends StatefulWidget {
  const MySessionsPage({super.key});

  @override
  State<MySessionsPage> createState() => _MySessionsPageState();
}

class _MySessionsPageState extends State<MySessionsPage> {
  final CounselorService _service = CounselorService();
  final Map<String, ({String name, String? photo})> _people = {};
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

  Future<void> _resolveNames(List<Booking> bookings) async {
    final db = FirebaseFirestore.instance;
    for (final b in bookings) {
      final otherUid = _role == 'counsellor' ? b.studentUid : b.counselorUid;
      if (otherUid.isEmpty || _people.containsKey(otherUid)) continue;
      try {
        final ref = _role == 'counsellor'
            ? db.collection('users').doc(otherUid)
            : db.collection(CounselorService.profilesCollection).doc(otherUid);
        final snap = await ref.get();
        final d = snap.data() ?? const <String, dynamic>{};
        final name = (d['displayName'] as String?)?.trim().isNotEmpty == true
            ? d['displayName'] as String
            : (_role == 'counsellor' ? 'Student' : 'Counselor');
        _people[otherUid] = (
          name: name,
          photo: d['photoUrl'] as String?,
        );
      } catch (_) {
        _people[otherUid] = (name: _role == 'counsellor' ? 'Student' : 'Counselor', photo: null);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.mySessions,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _service.watchMyBookings(uid, counselor: _role == 'counsellor'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
          }
          final bookings = snapshot.data ?? const <Booking>[];
          _resolveNames(bookings);

          if (bookings.isEmpty) {
            return _emptyState(context);
          }

          final now = DateTime.now();
          final upcoming = bookings
              .where((b) => b.status.isActive && b.scheduledEnd.isAfter(now))
              .toList()
            ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
          final past = bookings
              .where((b) => !upcoming.contains(b))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionLabel(context, l10n.sessionUpcomingBadge),
                const SizedBox(height: 10),
                ...upcoming.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _card(context, b),
                    )),
                const SizedBox(height: 8),
              ],
              if (past.isNotEmpty) ...[
                _sectionLabel(context, l10n.sessionEndedBadge),
                const SizedBox(height: 10),
                ...past.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _card(context, b),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Booking b) {
    final otherUid = _role == 'counsellor' ? b.studentUid : b.counselorUid;
    final person = _people[otherUid] ?? (name: _role == 'counsellor' ? 'Student' : 'Counselor', photo: null);
    return SessionCard(
      booking: b,
      otherName: person.name,
      otherPhotoUrl: person.photo,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(
            bookingId: b.id,
            otherName: person.name,
            otherPhotoUrl: person.photo,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.calendarCheck,
              size: 36,
              color: isDark
                  ? AppTheme.brandGold
                  : AppTheme.brandInk.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              _role == 'counsellor'
                  ? l10n.emptySessionsCounselor
                  : l10n.emptySessions,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.brandInk.withValues(alpha: 0.6),
              ),
            ),
            if (_role != 'counsellor') ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CounselorDirectoryPage(),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.userTie, size: 13),
                label: Text(l10n.browseCounselors),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
