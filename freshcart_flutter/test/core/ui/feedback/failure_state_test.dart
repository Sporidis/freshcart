import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

void main() {
  setUpAll(configurePluralResolvers);

  final t = translationsFor(AppLocale.en);

  Future<void> pump(
    WidgetTester tester,
    Failure failure, {
    VoidCallback? onRetry,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FailureState(
          failure: failure,
          t: t,
          action: ElevatedButton(
            onPressed: onRetry ?? () {},
            child: Text(t.common.retry),
          ),
        ),
      ),
    ),
  );

  testWidgets('the failure type picks icon and wording', (tester) async {
    await pump(tester, const Failure.network());
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.text(t.errors.network), findsOneWidget);

    await pump(tester, const Failure.unauthorized());
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text(t.errors.unauthorized), findsOneWidget);
  });

  testWidgets('not reaching the server says offline, not "something went '
      'wrong"', (tester) async {
    // Offline is a state the app handles (the sync banner says the same),
    // not something that broke.
    await pump(tester, const Failure.network());

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text(t.errors.unexpectedTitle), findsNothing);
  });

  // Core knows nothing about lists: "This list was deleted" is the
  // caller's wording, not a default.
  testWidgets('the screen can say what was lost', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FailureState(
            failure: const Failure.notFound(),
            t: t,
            notFound: (title: 'Gone', body: 'It was removed.'),
            action: const SizedBox(),
          ),
        ),
      ),
    );
    expect(find.text('Gone'), findsOneWidget);
    expect(find.text('It was removed.'), findsOneWidget);
  });

  testWidgets('never shows the raw cause of an unexpected failure', (
    tester,
  ) async {
    await pump(tester, const Failure.unexpected('SocketException: secret'));
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text(t.errors.unexpectedBody), findsOneWidget);
  });

  testWidgets('offers its one action', (tester) async {
    var retried = false;
    await pump(tester, const Failure.network(), onRetry: () => retried = true);
    await tester.tap(find.text(t.common.retry));
    expect(retried, isTrue);
  });
}
