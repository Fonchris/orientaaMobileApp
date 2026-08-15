import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/l10n/app_localizations.dart';
import 'package:orientaa_mobile_app/widgets/counselors/models/counselor_models.dart';
import 'package:orientaa_mobile_app/widgets/counselors/widgets/counselor_form_widgets.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('CounselorChipEditor', () {
    testWidgets('preset chip reports its own value, not the empty field',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final added = <String>[];

      await tester.pumpWidget(wrap(CounselorChipEditor(
        items: const [],
        controller: controller,
        hint: 'Add…',
        presets: const ['STEM guidance', 'Scholarships'],
        onAddValue: added.add,
        onRemove: (_) {},
      )));

      await tester.tap(find.text('STEM guidance'));
      expect(added, ['STEM guidance']);
    });

    testWidgets('free-text add passes the controller text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final added = <String>[];

      await tester.pumpWidget(wrap(CounselorChipEditor(
        items: const [],
        controller: controller,
        hint: 'Add…',
        onAddValue: added.add,
        onRemove: (_) {},
      )));

      await tester.enterText(find.byType(TextField), 'French');
      await tester.tap(find.byType(IconButton));
      expect(added, ['French']);
    });

    testWidgets('presets already in items are not offered again',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(CounselorChipEditor(
        items: const ['STEM guidance'],
        controller: controller,
        hint: 'Add…',
        presets: const ['STEM guidance', 'Scholarships'],
        onAddValue: (_) {},
        onRemove: (_) {},
      )));

      // Only one InputChip (the selected item) and one ActionChip (the
      // preset that isn't already selected).
      expect(find.byType(InputChip), findsOneWidget);
      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('Scholarships'), findsOneWidget);
    });

    testWidgets('delete icon reports the removed item', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final removed = <String>[];

      await tester.pumpWidget(wrap(CounselorChipEditor(
        items: const ['English'],
        controller: controller,
        hint: 'Add…',
        onAddValue: (_) {},
        onRemove: removed.add,
      )));

      await tester.tap(
        find.descendant(
          of: find.byType(InputChip),
          matching: find.byType(Icon),
        ),
      );
      expect(removed, ['English']);
    });
  });

  group('AvailabilityListEditor', () {
    testWidgets('renders initial rules and reports add/remove',
        (tester) async {
      final changes = <List<AvailabilityRule>>[];

      await tester.pumpWidget(wrap(AvailabilityListEditor(
        initial: const [
          AvailabilityRule(dayOfWeek: 1, startTime: '09:00', endTime: '17:00'),
        ],
        onChanged: changes.add,
      )));

      // The selected weekday renders in its dropdown.
      expect(find.text('Monday'), findsOneWidget);

      // Add a rule -> reported with two entries.
      await tester.tap(find.text('Add availability'));
      await tester.pump();
      expect(changes.last.length, 2);

      // Remove the newly added rule -> back to one entry.
      await tester.tap(find.text('Remove').last);
      await tester.pump();
      expect(changes.last.length, 1);
    });

    testWidgets('empty editor shows a hint and reports the first rule',
        (tester) async {
      final changes = <List<AvailabilityRule>>[];

      await tester.pumpWidget(wrap(AvailabilityListEditor(
        initial: const [],
        onChanged: changes.add,
      )));

      expect(changes, isEmpty);
      await tester.tap(find.text('Add availability'));
      await tester.pump();
      expect(changes.last.single.dayOfWeek, 1);
      expect(changes.last.single.startTime, '09:00');
      expect(changes.last.single.endTime, '17:00');
    });
  });

  group('CounselorUploadCard', () {
    testWidgets('uploading state disables the button and shows a spinner',
        (tester) async {
      var picked = 0;
      await tester.pumpWidget(wrap(CounselorUploadCard(
        title: 'Government-issued ID',
        hint: 'Only our review team can see this.',
        uploaded: false,
        uploading: true,
        buttonLabel: 'Upload ID',
        reuploadLabel: 'Re-upload ID',
        onPick: () => picked += 1,
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Upload ID'));
      expect(picked, 0); // button disabled while uploading
    });

    testWidgets('uploaded state shows the re-upload label', (tester) async {
      var picked = 0;
      await tester.pumpWidget(wrap(CounselorUploadCard(
        title: 'Government-issued ID',
        hint: 'Only our review team can see this.',
        uploaded: true,
        uploading: false,
        buttonLabel: 'Upload ID',
        reuploadLabel: 'Re-upload ID',
        onPick: () => picked += 1,
      )));

      await tester.tap(find.text('Re-upload ID'));
      expect(picked, 1);
    });
  });

  group('SocialLinksEditor', () {
    testWidgets('shows the inline error when no link is filled', (tester) async {
      await tester.pumpWidget(wrap(SocialLinksEditor(
        error: true,
        onChanged: (_) {},
      )));
      expect(
        find.text('Add at least one social profile link to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('no error row unless error is true', (tester) async {
      await tester.pumpWidget(wrap(SocialLinksEditor(onChanged: (_) {})));
      expect(
        find.text('Add at least one social profile link to continue.'),
        findsNothing,
      );
    });

    testWidgets('typing a link reports it through onChanged', (tester) async {
      final links = <SocialLinks>[];
      await tester.pumpWidget(wrap(SocialLinksEditor(
        error: true,
        onChanged: links.add,
      )));

      await tester.enterText(
        find.byType(TextField).first,
        'https://www.linkedin.com/in/aminayusuf',
      );
      expect(links, hasLength(1));
      expect(links.last.linkedin, 'https://www.linkedin.com/in/aminayusuf');
      expect(links.last.hasAny, isTrue);
    });

    testWidgets('prefills the submitted links on re-entry', (tester) async {
      await tester.pumpWidget(wrap(SocialLinksEditor(
        initial: const SocialLinks(tiktok: 'https://tiktok.com/@aminayusuf'),
        onChanged: (_) {},
      )));
      expect(find.text('https://tiktok.com/@aminayusuf'), findsOneWidget);
    });
  });
}
