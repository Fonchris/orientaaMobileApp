import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/l10n/app_localizations.dart';
import 'package:orientaa_mobile_app/widgets/counselors/models/counselor_models.dart';
import 'package:orientaa_mobile_app/widgets/counselors/widgets/booking_status_badge.dart';
import 'package:orientaa_mobile_app/widgets/profile/chat_widgets.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('BookingStatusBadge', () {
    testWidgets('renders a label for every status', (tester) async {
      for (final status in BookingStatus.values) {
        await tester.pumpWidget(wrap(BookingStatusBadge(status: status)));
        expect(find.byType(BookingStatusBadge), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('shows a localized label', (tester) async {
      await tester.pumpWidget(
        wrap(const BookingStatusBadge(status: BookingStatus.confirmed)),
      );
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('compact variant still renders', (tester) async {
      await tester.pumpWidget(
        wrap(const BookingStatusBadge(
          status: BookingStatus.paidOut,
          compact: true,
        )),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ChatComposer', () {
    testWidgets('disabled composer blocks send', (tester) async {
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);
      var sent = 0;

      await tester.pumpWidget(
        wrap(ChatComposer(
          controller: controller,
          sending: false,
          enabled: false,
          onSend: () => sent += 1,
          hintText: 'Type…',
        )),
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(sent, 0);
    });

    testWidgets('enabled composer sends', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sent = 0;

      await tester.pumpWidget(
        wrap(ChatComposer(
          controller: controller,
          sending: false,
          enabled: true,
          onSend: () => sent += 1,
          hintText: 'Type…',
        )),
      );
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(sent, 1);
    });
  });

  group('ChatBubble', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        wrap(const ChatBubble(text: 'See you then!', isMine: true)),
      );
      expect(find.text('See you then!'), findsOneWidget);
    });
  });
}
