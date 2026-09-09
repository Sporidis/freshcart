import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.dispose());

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: UpgradeNudge())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('prompts an anonymous user to secure their lists', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Secure your lists'), findsOneWidget);
    expect(find.text('Link email'), findsOneWidget);
  });

  testWidgets('says nothing once an account is linked', (tester) async {
    auth.user = Ok(
      AuthUser(
        id: UserId('user-1'),
        displayName: 'Nikolaos',
        isAnonymous: false,
        email: 'n@example.com',
      ),
    );

    await pump(tester);

    expect(find.text('Secure your lists'), findsNothing);
  });

  testWidgets('linking an email sends the credentials and dismisses', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Link email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'me@example.com');
    await tester.enterText(find.byType(TextField).last, 'a good passphrase');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(auth.linkCalls.single.email, 'me@example.com');
    expect(find.byType(AlertDialog), findsNothing);
    // The nudge disappears because the account is no longer anonymous.
    expect(find.text('Secure your lists'), findsNothing);
  });

  testWidgets('a taken email keeps the dialog open with the reason', (
    tester,
  ) async {
    auth.linkResult = const Err(
      Failure.validation('email', 'That email is already in use'),
    );

    await pump(tester);
    await tester.tap(find.text('Link email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'taken@example.com');
    await tester.enterText(find.byType(TextField).last, 'a good passphrase');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('That email is already in use'), findsOneWidget);
  });

  testWidgets('Google linking reports that it is not configured', (
    tester,
  ) async {
    // Deliberately not faked as working — see decisions #39.
    final result = await auth.linkGoogle();
    expect(result.failureOrNull, isA<ValidationFailure>());
  });
}
