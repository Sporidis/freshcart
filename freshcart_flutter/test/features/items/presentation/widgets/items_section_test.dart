import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/offline/status/sync_providers.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/member_avatar_stack.dart';
import 'package:freshcart_flutter/core/ui/mode_bar.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/arrival_flash.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_empty_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

/// Taps a row to (un)check it, then waits out the v3 batch settle, which a
/// plain pumpAndSettle doesn't: a waiting Timer schedules no frames.
Future<void> tick(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pump(AppMotion.checkSettle);
  await tester.pumpAndSettle();
}

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
    "the header shows the Basket eyebrow, the list's own name, and the "
    "household's avatars",
    (tester) async {
      items.byListResult = const Ok(<ShoppingItem>[]);

      await pump(tester);

      expect(find.text('Basket'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.byType(MemberAvatarStack), findsOneWidget);
    },
  );

  testWidgets('an empty list (no shop filter) shows the generic empty state', (
    tester,
  ) async {
    items.byListResult = const Ok(<ShoppingItem>[]);

    await pump(tester);

    expect(find.byType(ItemsEmptyState), findsOneWidget);
    expect(find.text('Your list is empty'), findsOneWidget);
    // Design v3: the empty list starts adding too, not only a shop tab.
    expect(find.text('Add a product'), findsOneWidget);
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
      expect(find.text('Nothing for Colruyt yet'), findsOneWidget);
      // The button names where the product will go.
      expect(find.text('Add to Colruyt'), findsOneWidget);
    },
  );

  testWidgets(
    'switching between two empty tabs plays the empty state in again',
    (tester) async {
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c2',
        name: 'Bakery',
        color: '#4CAF50',
      );
      shops.byListResult = Ok([colruyt, bakery]);
      items.byListResult = const Ok(<ShoppingItem>[]);

      final container = await pump(tester);
      final filter = container.read(
        shopFilterControllerProvider(listId).notifier,
      );
      filter.select(colruyt.id);
      await tester.pumpAndSettle();

      // The opacity of the part holding [text]: its own entrance fade.
      double opacityOf(String text) => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      filter.select(bakery.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // A fresh empty state, still arriving -- not the old one reused with
      // its entrance already over.
      expect(opacityOf('Nothing for Bakery yet'), lessThan(1));

      await tester.pumpAndSettle();
      expect(opacityOf('Nothing for Bakery yet'), 1);
    },
  );

  testWidgets(
    'a checked item collects under Done, collapsible, with a Clear action',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread', isChecked: true),
      ]);

      await pump(tester);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('DONE · 1'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Folding the Done section away hides the checked row without
      // removing it -- toggle, don't clear.
      await tester.tap(find.text('DONE · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsNothing);

      await tester.tap(find.text('DONE · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Gone at once, but the server only hears once Undo has had its
      // chance -- and by id, so a later tick can't be swept up with it.
      expect(find.text('Bread'), findsNothing);
      expect(items.removeManyCalls, isEmpty);
      await tester.pump(ItemsController.swipeUndoWindow);
      expect(items.removeManyCalls.single, [ItemId('b')]);
      expect(items.clearCheckedCallCount, 0);
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
    'typing in the open add bar, with suggestions coming in, lays out '
    'cleanly',
    (tester) async {
      items.byListResult = Ok([buildItem(id: 'a', name: 'Milk')]);
      items.suggestNamesResult = const Ok(['Mint', 'Milk powder']);

      await pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(QuickAddBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      for (final text in ['M', 'Mi', 'Min', 'Milk']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opening the add bar focuses its field, so typing goes straight in',
    (tester) async {
      items.byListResult = Ok([buildItem(id: 'a', name: 'Milk')]);

      await pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(QuickAddBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();

      // Through the keyboard connection, not tester.enterText (which would
      // focus the field itself): this only lands if the field has focus.
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.enterText('Bread');
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(QuickAddBar),
          matching: find.text('Bread'),
        ),
        findsOneWidget,
      );
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
    'checking off the last item brings up the celebration -- the moment '
    'itself, not only a list that opens already done',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk')]);

      await pump(tester);
      expect(find.byType(CompletionCelebrationCard), findsNothing);

      await tick(tester, 'Milk');

      expect(find.byType(CompletionCelebrationCard), findsOneWidget);
    },
  );

  testWidgets(
    'after Keep list, unchecking and re-completing the list celebrates again',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);

      await pump(tester);
      expect(find.byType(CompletionCelebrationCard), findsOneWidget);

      await tester.tap(find.text('Keep list'));
      await tester.pumpAndSettle();
      expect(find.byType(CompletionCelebrationCard), findsNothing);

      // Uncheck, then check again: a fresh completion.
      await tick(tester, 'Milk');
      await tick(tester, 'Milk');

      expect(find.byType(CompletionCelebrationCard), findsOneWidget);
    },
  );

  testWidgets(
    'with Clear checked after shopping on, finishing the list clears it '
    'instead of celebrating',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk')]);
      items.clearCheckedResult = const Ok(1);

      await pump(tester, list: buildList(clearCheckedAfterShopping: true));
      await tick(tester, 'Milk');

      expect(items.clearCheckedCallCount, 1);
      expect(find.byType(CompletionCelebrationCard), findsNothing);
    },
  );

  testWidgets(
    'a list that opens already finished does not clear itself on arrival',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);

      await pump(tester, list: buildList(clearCheckedAfterShopping: true));

      expect(items.clearCheckedCallCount, 0);
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

      await tester.tap(
        find.descendant(
          of: find.byType(ModeBar),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(items.removeManyCalls, isEmpty, reason: 'Undo still can');
      await tester.pump(ItemsController.swipeUndoWindow);
      expect(items.removeManyCalls.single.toSet(), {
        ItemId('a'),
        ItemId('b'),
      });
      // Cleared back out of selection mode on success.
      expect(find.byType(ModeBar), findsNothing);
      expect(find.text('Basket'), findsOneWidget);
    },
  );

  testWidgets(
    "the hold menu's stepper shows each tap at once and saves the total "
    'once -- not one racing save per tap',
    (tester) async {
      items.byListResult = Ok([buildItem(id: 'a', name: 'Milk')]);

      await pump(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Milk')),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      final plus = find
          .descendant(
            of: find.byType(QuantityStepper),
            matching: find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_StepperButton',
            ),
          )
          .last;
      for (var i = 0; i < 3; i++) {
        await tester.tap(plus);
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The menu kept up with every tap, before anything was saved.
      expect(
        find.descendant(
          of: find.byType(QuantityStepper),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(items.savedItems, isEmpty);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(items.savedItems, hasLength(1));
      expect(items.savedItems.single.quantity, 4);
    },
  );

  testWidgets(
    'ticks close together stay put, then land in Done as one batch with one '
    'toast, and Undo unchecks the whole batch',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
        buildItem(id: 'c', name: 'Eggs'),
      ]);

      await pump(tester);

      await tester.tap(find.text('Milk'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Bread'));
      await tester.pump(const Duration(milliseconds: 300));

      // 600ms in, but only 300ms since the last tick: still held in place.
      expect(find.textContaining('DONE'), findsNothing);

      await tester.pump(AppMotion.checkSettle);
      await tester.pumpAndSettle();

      expect(find.text('DONE · 2'), findsOneWidget);
      expect(find.text('2 items checked off'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('DONE'), findsNothing);
    },
  );

  testWidgets(
    'a settled row glides from where it was ticked down into Done, instead '
    'of jumping there',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
        buildItem(id: 'c', name: 'Eggs'),
      ]);

      await pump(tester);
      final before = tester.getTopLeft(find.text('Milk')).dy;

      await tester.tap(find.text('Milk'));
      await tester.pump(AppMotion.checkSettle);
      // The settle lands; the glide starts on the next frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final during = tester.getTopLeft(find.text('Milk')).dy;

      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.text('Milk')).dy;

      expect(after, greaterThan(before), reason: 'it went down to Done');
      expect(during, greaterThan(before));
      expect(during, lessThan(after), reason: 'mid-glide, not teleported');
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
    'a checked item shows who checked it off, with their avatar',
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

  testWidgets(
    'who checked it off shows on the All tab too, ahead of the shop',
    (tester) async {
      // The bug: the shop name took the subtitle, so on All (where nearly
      // every row names its shop) "Checked off by" never appeared.
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      shops.byListResult = Ok([colruyt]);
      items.byListResult = Ok([
        buildItem(
          name: 'Milk',
          isChecked: true,
          checkedBy: 'user-2',
          shopId: colruyt.id,
        ),
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

      expect(find.text('Checked off by Sam · Colruyt'), findsOneWidget);
      // Sam's avatar, with the initial, sits in front of it.
      expect(
        find.descendant(
          of: find.byType(ItemTile),
          matching: find.byType(UserAvatar),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a row changed offline carries a dashed edge until it has synced',
    (tester) async {
      addTearDown(items.dispose);
      final milk = buildItem(name: 'Milk');
      items.byListResult = Ok([milk.copyWith(pending: true)]);

      await pump(tester);

      double edgeOpacity() => tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('pending-edge')))
          .opacity;
      expect(edgeOpacity(), 1);

      // The queue drained: the same row arrives, no longer pending.
      items.live.add(Ok([milk]));
      await tester.pump();
      // Past the row's stagger and the fade.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(edgeOpacity(), 0);
    },
  );

  testWidgets(
    'a newly arrived item drops in with a flash; rows already there do not',
    (tester) async {
      addTearDown(items.dispose);
      final milk = buildItem(id: 'milk', name: 'Milk');
      items.byListResult = Ok([milk]);

      await pump(tester);

      // The opacity the row's arrival gives it (1 when at rest).
      double arrivalOpacity(String name) => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text(name),
                  matching: find.descendant(
                    of: find.byType(ArrivalFlash),
                    matching: find.byType(Opacity),
                  ),
                )
                .last,
          )
          .opacity;

      // The first load brings nothing "new".
      expect(arrivalOpacity('Milk'), 1);

      // Someone adds Bread.
      items.live.add(Ok([milk, buildItem(id: 'bread', name: 'Bread')]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(arrivalOpacity('Bread'), lessThan(1));
      expect(arrivalOpacity('Milk'), 1);

      await tester.pumpAndSettle();
      expect(arrivalOpacity('Bread'), 1);
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
