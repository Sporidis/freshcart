import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_bootstrap_provider.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_list_repository.dart';
import '../../../fakes/fake_shop_repository.dart';

/// Reached only through the real journey (drawer -> Settings -> tapping the
/// list's own row under "Your lists"), not by constructing the screen
/// directly -- the point of this screen is that door, and a widget test
/// that skips it could not catch the door going missing.
///
/// There is deliberately no single "Manage lists" row to tap: the
/// `Flow Screens v2.dc.html` re-export replaced it with one row per list,
/// each opening straight into that list's own settings ("Shops and
/// household belong to a list. Pick one to manage it.") -- so the door this
/// suite exercises is a specific list's row, by name.
void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  late FakeItemRepository itemRepository;
  late FakeShopRepository shopRepository;

  setUp(() {
    repository = FakeListRepository();
    itemRepository = FakeItemRepository();
    shopRepository = FakeShopRepository();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required ShoppingList list,
    String? currentUserId,
  }) async {
    repository.myListsResult = Ok([list]);
    repository.byIdResult = Ok(list);
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        shopRepositoryProvider.overrideWithValue(shopRepository),
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: true, isNewIdentity: false),
        ),
        if (currentUserId != null)
          currentUserIdProvider.overrideWith(
            (ref) async => Ok(UserId(currentUserId)),
          ),
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

    // The real journey: drawer -> Settings -> the list's own row.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(list.name));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('opens pre-filled with the list\'s own name', (tester) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    expect(find.widgetWithText(AppBar, 'List settings'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Groceries',
    );
  });

  testWidgets('saving a new name calls through to rename', (tester) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    repository.renameResult = Ok(list.copyWith(name: 'Weekly Groceries'));
    await pump(tester, list: list);

    await tester.enterText(find.byType(TextField), 'Weekly Groceries');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.renameCalls.single.name, 'Weekly Groceries');
  });

  testWidgets('a rejected rename shows the error beneath the field', (
    tester,
  ) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    repository.renameResult = const Err(
      Failure.validation('name', 'That name is too long'),
    );
    await pump(tester, list: list);

    await tester.enterText(find.byType(TextField), 'x' * 61);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('That name is too long'), findsOneWidget);
  });

  testWidgets('the Household row opens the household screen', (tester) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    await tester.tap(find.text('Household'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ABC23'), findsOneWidget);
  });

  testWidgets('the Manage shops row opens shop management', (tester) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    await tester.tap(find.text('Manage shops'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Manage shops'), findsOneWidget);
  });

  testWidgets('an owner sees Delete list, not Leave list', (tester) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
      currentUserId: 'user-1',
    );

    expect(find.text('Delete list'), findsOneWidget);
    expect(find.text('Leave list'), findsNothing);
  });

  testWidgets('a member sees Leave list, not Delete list', (tester) async {
    await pump(
      tester,
      list: buildList(
        name: 'Groceries',
        members: [
          buildMember(),
          buildMember(userId: 'user-2'),
        ],
      ),
      currentUserId: 'user-2',
    );

    expect(find.text('Leave list'), findsOneWidget);
    expect(find.text('Delete list'), findsNothing);
  });
}
