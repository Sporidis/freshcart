import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/di/is_new_identity_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_list_repository.dart';
import '../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  late FakeItemRepository itemRepository;
  late FakeShopRepository shopRepository;

  setUp(() {
    repository = FakeListRepository();
    // The detail screen renders the items section, so navigating there needs an
    // item repository even when the test is about the lists screen.
    itemRepository = FakeItemRepository();
    // The detail screen also renders the shop filter bar.
    shopRepository = FakeShopRepository();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        shopRepositoryProvider.overrideWithValue(shopRepository),
        // These tests are about ListsScreen itself, not the onboarding gate —
        // a restored (non-new) identity so the router starts on /lists.
        isNewIdentityProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreshCartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('ListsScreen rendering', () {
    testWidgets('shows the empty state when there are no lists', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.text('No lists yet. Create one to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('lists the user\'s lists with a member count', (tester) async {
      repository.myListsResult = Ok([
        buildList(name: 'Groceries', members: [buildMember()]),
        buildList(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Hardware',
          members: [
            buildMember(),
            buildMember(userId: 'user-2'),
          ],
        ),
      ]);

      await pump(tester);

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('1 member'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);
    });

    testWidgets('shows a localized message when the fetch fails', (
      tester,
    ) async {
      repository.myListsResult = const Err(Failure.network('offline'));

      await pump(tester);

      expect(find.text('Could not reach the server.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('creating a list', () {
    testWidgets('sends the name and refreshes the collection', (tester) async {
      repository.createResult = Ok(buildList(name: 'Weekend'));
      await pump(tester);
      final callsBefore = repository.myListsCallCount;

      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Weekend');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.createCalls.single, 'Weekend');
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        repository.myListsCallCount,
        greaterThan(callsBefore),
        reason: 'a successful create must refresh the list',
      );
    });

    testWidgets(
      'keeps the dialog open and shows the message when the name is blank',
      (tester) async {
        await pump(tester);

        await tester.tap(find.text('New list'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // The domain rejected it before any network call.
        expect(repository.createCalls, isEmpty);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Give the list a name'), findsOneWidget);
      },
    );
  });

  group('joining by code', () {
    testWidgets('accepts a valid code, normalising case', (tester) async {
      repository.joinResult = Ok(buildList(name: 'Shared'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abc234');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.joinCalls.single.value, 'ABC234');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('rejects a malformed code without a round trip', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        repository.joinCalls,
        isEmpty,
        reason: 'JoinList parses the code before spending a request',
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('A join code is 6 characters'), findsOneWidget);
    });

    testWidgets('surfaces a code that matches no list', (tester) async {
      repository.joinResult = const Err(Failure.notFound());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ZZZ999');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.joinCalls.single.value, 'ZZZ999');
      expect(find.text('Not found.'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping a list opens its detail screen', (tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);

      await pump(tester);
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // The detail screen shows the join code and the member count, with the
      // members themselves behind an expander.
      expect(find.textContaining('ABC234'), findsOneWidget);
      expect(find.text('1 member'), findsOneWidget);

      await tester.tap(find.text('1 member'));
      await tester.pumpAndSettle();
      expect(find.text('Nikolaos'), findsOneWidget);
    });

    testWidgets('a list the user cannot see reports no access', (tester) async {
      final list = buildList(name: 'Groceries');
      repository.myListsResult = Ok([list]);
      repository.byIdResult = const Err(Failure.unauthorized());

      await pump(tester);
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('You do not have access to this.'), findsOneWidget);
    });

    testWidgets(
      'a collaborator joining while the screen is open updates it live',
      (tester) async {
        final list = buildList(name: 'Groceries', members: [buildMember()]);
        repository.myListsResult = Ok([list]);
        repository.byIdResult = Ok(list);
        addTearDown(repository.dispose);

        await pump(tester);
        await tester.tap(find.text('Groceries'));
        await tester.pumpAndSettle();
        expect(find.text('1 member'), findsOneWidget);

        // Someone else joins the list on another device — no user action here,
        // just the server pushing the updated state down the live stream.
        repository.live.add(
          Ok(
            buildList(
              name: 'Groceries',
              members: [
                buildMember(),
                buildMember(userId: 'user-2', displayName: 'Mom'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 members'), findsOneWidget);
      },
    );
  });
}
