import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_item_repository.dart';
import '../../fakes/fake_list_repository.dart';
import '../../fakes/fake_shop_repository.dart';

/// "Getting in" end to end: Splash's redirect, Welcome's two exits, the
/// onboarding wizard's happy path, and the join-by-code flow's happy path.
///
/// Everything here drives the real [FreshCartApp] and its real router —
/// these are the paths that decide where a person lands the very first time
/// they open the app, so a test that only inspects the controller in
/// isolation would miss exactly the wiring that matters.
void main() {
  setUpAll(configurePluralResolvers);

  late FakeAuthRepository auth;
  late FakeListRepository lists;
  late FakeItemRepository items;
  late FakeShopRepository shops;

  setUp(() {
    auth = FakeAuthRepository();
    lists = FakeListRepository();
    items = FakeItemRepository();
    shops = FakeShopRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await lists.dispose();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required bool isNewIdentity,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        listRepositoryProvider.overrideWithValue(lists),
        itemRepositoryProvider.overrideWithValue(items),
        shopRepositoryProvider.overrideWithValue(shops),
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: true, isNewIdentity: isNewIdentity),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreshCartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Splash', () {
    testWidgets('a new identity lands on Welcome', (tester) async {
      await pump(tester, isNewIdentity: true);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('a restored identity lands on the lists screen', (
      tester,
    ) async {
      await pump(tester, isNewIdentity: false);
      expect(find.text('My lists'), findsOneWidget);
    });
  });

  group('Welcome', () {
    testWidgets('Get started opens onboarding', (tester) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);
    });

    testWidgets('the invite-code link opens the join flow', (tester) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('I have an invite code'));
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);
      // The join flow's own name step, not onboarding's — distinguished by
      // there being no step indicator above it.
      expect(find.text('Step 1 of 3'), findsNothing);
    });
  });

  group('Onboarding wizard', () {
    testWidgets(
      'walking all four steps creates the list and its shops, '
      'and Start my list opens the lists screen',
      (tester) async {
        lists.createResult = Ok(buildList(name: 'Weekly Groceries'));
        shops.createResult = Ok(buildShop());

        await pump(tester, isNewIdentity: true);
        await tester.tap(find.text('Get started'));
        await tester.pumpAndSettle();

        // Step 1: name.
        expect(find.text('Step 1 of 3'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'Alex');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2: list name.
        expect(find.text('Step 2 of 3'), findsOneWidget);
        await tester.enterText(
          find.byType(TextField).first,
          'Weekly Groceries',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 3: shops — the two presets start selected, so Continue
        // submits straight away.
        expect(find.text('Step 3 of 3'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Submitting created the list and both preset shops.
        expect(lists.createCalls, ['Weekly Groceries']);
        expect(shops.createCalls, hasLength(2));

        // Invite — shows the real list's join code. Unnumbered: it comes
        // after the list exists and is optional, so the rail is gone.
        expect(find.textContaining('Step '), findsNothing);
        expect(find.text('Shopping with someone?'), findsOneWidget);
        expect(find.text('ABC23'), findsOneWidget);

        await tester.tap(find.text('Start my list'));
        await tester.pumpAndSettle();

        expect(find.text('My lists'), findsOneWidget);
      },
    );

    testWidgets('going back from Invite to Shops and continuing again '
        'does not create a second list', (tester) async {
      lists.createResult = Ok(buildList());
      shops.createResult = Ok(buildShop());

      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Alex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Weekly Groceries');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(lists.createCalls, hasLength(1));

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 3'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(lists.createCalls, hasLength(1));
      expect(find.text('Shopping with someone?'), findsOneWidget);
    });

    testWidgets('Continue is there before anything is typed, and pressing it '
        'says what is missing instead of advancing', (tester) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Please enter your name to continue'), findsOneWidget);

      // The next keystroke clears it.
      await tester.enterText(find.byType(TextField).first, 'A');
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name to continue'), findsNothing);
    });

    testWidgets('Back on the first step returns to Welcome', (tester) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('I have an invite code'), findsOneWidget);
    });

    testWidgets('the list step arrives pre-filled, so Continue is one tap', (
      tester,
    ) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Alex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Weekly Groceries'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
    });

    testWidgets('picking a shop adds its pill to the tabs preview, and '
        'unpicking removes it', (tester) async {
      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Alex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Delhaize is offered but not preselected: only its option row.
      expect(find.text('Delhaize'), findsOneWidget);

      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();
      expect(find.text('Delhaize'), findsNWidgets(2));

      await tester.tap(find.text('Delhaize').first);
      await tester.pumpAndSettle();
      expect(find.text('Delhaize'), findsOneWidget);
    });
  });

  group('Join flow', () {
    testWidgets(
      'a name and a valid code join the list, then land on the lists screen',
      (tester) async {
        lists.joinResult = Ok(buildList(name: 'Shared Groceries'));

        await pump(tester, isNewIdentity: true);
        await tester.tap(find.text('I have an invite code'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Alex');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Join a list'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'ABC23');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Join list'));
        await tester.pumpAndSettle();

        expect(lists.joinCalls, [JoinCode.parse('ABC23').valueOrNull]);
        expect(find.text("You're in"), findsOneWidget);

        // The confirmation step routes on by itself.
        await tester.pumpAndSettle(const Duration(milliseconds: 1500));
        expect(find.text('My lists'), findsOneWidget);
      },
    );

    testWidgets('an unknown code shows an inline error, not a crash', (
      tester,
    ) async {
      lists.joinResult = const Err(Failure.notFound());

      await pump(tester, isNewIdentity: true);
      await tester.tap(find.text('I have an invite code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Alex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ZZZZZ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join list'));
      await tester.pumpAndSettle();

      expect(find.text('Join a list'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
