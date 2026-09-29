import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_providers.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeItemRepository items;
  late FakeShopRepository shops;
  final me = UserId('user-1');
  // Matches buildList()'s default id -- there is only ever the one list on
  // screen in this file's pump().
  final listId = ListId('00000000-0000-4000-8000-000000000001');

  setUp(() {
    items = FakeItemRepository();
    shops = FakeShopRepository();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ShoppingList? list,
  }) async {
    final effectiveList =
        list ?? buildList(members: [buildMember(displayName: 'Nikolaos')]);
    // The header lives in ListDetailScreen, not ItemsSection -- so these
    // pump the real screen, fed the list through a fake repository.
    final lists = FakeListRepository()..byIdResult = Ok(effectiveList);
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(lists),
        syncProvider.overrideWith((ref) => Stream.value(SyncStatus.online)),
        itemRepositoryProvider.overrideWithValue(items),
        shopRepositoryProvider.overrideWithValue(shops),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await container.read(currentUserIdProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ListDetailScreen(listId: effectiveList.id)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders items via ItemTile with name and quantity', (
    tester,
  ) async {
    items.byListResult = Ok([buildItem(name: 'Milk', quantity: 2)]);

    await pump(tester);

    expect(find.byType(ItemTile), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets(
    "the header shows the app name kicker, the list's own name, and the "
    "signed-in member's avatar",
    (tester) async {
      items.byListResult = const Ok(<ShoppingItem>[]);

      await pump(tester);

      expect(find.text('FreshCart'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
    },
  );

  testWidgets('an empty list (no shop filter) shows the generic empty state', (
    tester,
  ) async {
    items.byListResult = const Ok(<ShoppingItem>[]);

    await pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nothing on the list yet'), findsOneWidget);
  });

  testWidgets(
    'an empty shop tab names the shop and shows the shop-scoped empty copy',
    (tester) async {
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c2',
        name: 'Bakery',
        color: '#4CAF50',
      );
      shops.byListResult = Ok([colruyt, bakery]);
      // Tagged to a *different* shop, not untagged -- an untagged item
      // matches every filter by design, so it wouldn't actually exercise
      // "this tab has nothing in it".
      items.byListResult = Ok([buildItem(name: 'Bread', shopId: bakery.id)]);

      final container = await pump(tester);
      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(colruyt.id);
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsNothing);
      expect(find.text('Nothing for Colruyt'), findsOneWidget);
    },
  );

  testWidgets(
    'a checked item collects under Done, collapsible, with a Clear checked '
    'action',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread', isChecked: true),
      ]);

      await pump(tester);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('DONE · 1'), findsOneWidget);
      expect(find.text('Clear checked'), findsOneWidget);

      // Folding the Done section away hides the checked row without
      // removing it -- toggle, don't clear.
      await tester.tap(find.text('DONE · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsNothing);

      await tester.tap(find.text('DONE · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);

      await tester.tap(find.text('Clear checked'));
      await tester.pumpAndSettle();

      expect(items.clearCheckedCallCount, 1);
    },
  );

  testWidgets(
    'the quick-add FAB adds an item and stays open for the next one',
    (tester) async {
      items.byListResult = const Ok(<ShoppingItem>[]);
      items.addResult = Ok(buildItem(name: 'Bread'));

      await pump(tester);

      // Scoped to QuickAddBar specifically -- ListsDrawer, built eagerly
      // as part of the Scaffold even while closed, has its own "+" for
      // creating a list.
      await tester.tap(
        find.descendant(
          of: find.byType(QuickAddBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'the completion celebration shows once every item is checked, and '
    'Clear checked resolves it',
    (tester) async {
      items.byListResult = Ok([
        buildItem(name: 'Milk', isChecked: true),
      ]);
      items.clearCheckedResult = const Ok(1);

      await pump(tester);

      expect(find.byType(CompletionCelebrationCard), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear checked'));
      await tester.pumpAndSettle();

      expect(items.clearCheckedCallCount, 1);
    },
  );

  testWidgets(
    'holding a row opens its menu; Select more… enters multi-select seeded '
    'with it, and the contextual bar can Move or Delete the selection',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
      ]);
      items.removeManyResult = const Ok(2);

      await pump(tester);

      // Held in small increments, not one 500ms pump -- the hold's own
      // 450ms threshold timer only fires reliably against the fake clock
      // when it elapses in several steps.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Milk')),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select more…'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      // Selection mode is now active for every open row -- tapping another
      // one (a plain tap, not a hold) adds it to the selection instead of
      // checking it or opening its own menu.
      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(items.removeManyCalls.single.toSet(), {
        ItemId('a'),
        ItemId('b'),
      });
      // Cleared back out of selection mode on success.
      expect(find.text('FreshCart'), findsOneWidget);
    },
  );

  testWidgets(
    'search bypasses the shop filter and Cancel closes it back to the '
    'normal list',
    (tester) async {
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c2',
        name: 'Bakery',
        color: '#4CAF50',
      );
      shops.byListResult = Ok([colruyt, bakery]);
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk', shopId: colruyt.id),
        buildItem(id: 'b', name: 'Bread', shopId: bakery.id),
      ]);

      final container = await pump(tester);
      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(colruyt.id);
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsNothing);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bread');
      await tester.pumpAndSettle();

      // Found even though "Colruyt" is still the active shop tab -- search
      // spans every shop, per §16.
      expect(find.text('Bread'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
    },
  );

  testWidgets(
    'Rearrange list enters drag mode with handles; dragging one saves a '
    'new position; Done exits back to the normal header',
    (tester) async {
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      shops.byListResult = Ok([colruyt]);
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk', shopId: colruyt.id, sortOrder: 10),
        buildItem(id: 'b', name: 'Bread', shopId: colruyt.id, sortOrder: 20),
        buildItem(id: 'c', name: 'Eggs', shopId: colruyt.id, sortOrder: 30),
      ]);

      final container = await pump(tester);
      // Reorder is scoped to one shop tab, same as ItemsSection's own rule.
      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(colruyt.id);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Milk')),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rearrange list'));
      await tester.pumpAndSettle();

      expect(find.text('Drag to reorder'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

      // Drag Eggs' handle (the last row) up past the first two.
      await tester.drag(
        find.byIcon(Icons.drag_handle).last,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      final saved = items.savedItems.where((i) => i.id == ItemId('c'));
      expect(saved, isNotEmpty, reason: 'the drag should have saved Eggs');
      expect(
        saved.first.sortOrder,
        lessThan(10),
        reason: 'dropped above Milk, the row that was previously first',
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Drag to reorder'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    },
  );

  testWidgets(
    'a checked item shows who checked it off, once there is no note',
    (tester) async {
      items.byListResult = Ok([
        buildItem(name: 'Milk', isChecked: true, checkedBy: 'user-2'),
      ]);

      await pump(
        tester,
        list: buildList(
          members: [
            buildMember(displayName: 'Nikolaos'),
            buildMember(userId: 'user-2', displayName: 'Sam'),
          ],
        ),
      );

      expect(find.text('Checked off by Sam'), findsOneWidget);
    },
  );

  testWidgets("the row menu's options are translated, not hardcoded English", (
    tester,
  ) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);

    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Milk')),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Edit details'), findsOneWidget);
    expect(find.text('Move to shop'), findsOneWidget);
    expect(find.text('Rearrange list'), findsOneWidget);
    expect(find.text('Select more…'), findsOneWidget);
  });

  testWidgets('switching shop tabs filters which items show', (tester) async {
    final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
    final bakery = buildShop(
      id: '00000000-0000-4000-8000-0000000000c2',
      name: 'Bakery',
      color: '#4CAF50',
    );
    shops.byListResult = Ok([colruyt, bakery]);
    items.byListResult = Ok([
      buildItem(id: 'a', name: 'Milk', shopId: colruyt.id),
      buildItem(id: 'b', name: 'Bread', shopId: bakery.id),
    ]);

    final container = await pump(tester);
    container
        .read(shopFilterControllerProvider(listId).notifier)
        .select(colruyt.id);
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsNothing);
  });
}
