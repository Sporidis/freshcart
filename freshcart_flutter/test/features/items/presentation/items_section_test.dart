import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/done_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/recently_added_provider.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add_bar.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_list_repository.dart';
import '../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeItemRepository items;
  late FakeShopRepository shops;
  final me = UserId('user-1');

  setUp(() {
    items = FakeItemRepository();
    shops = FakeShopRepository();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ShoppingList? list,
    bool reducedMotion = false,
  }) async {
    final effectiveList =
        list ?? buildList(members: [buildMember(displayName: 'Nikolaos')]);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(items),
        shopRepositoryProvider.overrideWithValue(shops),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
    await container.read(currentUserIdProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: MaterialApp(
            home: Scaffold(body: ItemsSection(list: effectiveList)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the items with quantity and note', (tester) async {
    items.byListResult = Ok([
      buildItem(name: 'Milk', quantity: 2),
      buildItem(
        id: '00000000-0000-4000-8000-0000000000bb',
        name: 'Bread',
        note: Note(
          text: 'the seeded one',
          authorId: me,
          updatedAt: DateTime.utc(2026, 9, 9),
        ),
      ),
    ]);

    await pump(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('the seeded one'), findsOneWidget);
  });

  group('the add control\'s first-run pulse (§11)', () {
    testWidgets('is armed for a brand-new, still-empty list', (tester) async {
      items.byListResult = const Ok(<ShoppingItem>[]);

      await pump(tester);

      expect(
        tester.widget<QuickAddBar>(find.byType(QuickAddBar)).firstRun,
        isTrue,
      );
    });

    testWidgets('is not armed once the list has items', (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk')]);

      await pump(tester);

      expect(
        tester.widget<QuickAddBar>(find.byType(QuickAddBar)).firstRun,
        isFalse,
      );
    });
  });

  testWidgets('a checked item shows who checked it, avatar included', (
    tester,
  ) async {
    items.byListResult = Ok([
      buildItem(name: 'Milk', isChecked: true, checkedBy: 'user-1'),
      buildItem(id: '00000000-0000-4000-8000-0000000000bb', name: 'Bread'),
    ]);

    await pump(
      tester,
      list: buildList(members: [buildMember(displayName: 'Nikolaos')]),
    );

    final milkRow = find.ancestor(
      of: find.text('Milk'),
      matching: find.byType(ItemTile),
    );
    expect(
      find.descendant(of: milkRow, matching: find.byType(UserAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: milkRow,
        matching: find.textContaining('Nikolaos'),
      ),
      findsOneWidget,
    );

    final breadRow = find.ancestor(
      of: find.text('Bread'),
      matching: find.byType(ItemTile),
    );
    expect(
      find.descendant(of: breadRow, matching: find.byType(UserAvatar)),
      findsNothing,
    );
  });

  testWidgets('a tagged item shows its shop as a coloured dot', (
    tester,
  ) async {
    final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
    shops.byListResult = Ok([colruyt]);
    items.byListResult = Ok([
      buildItem(name: 'Milk', shopId: colruyt.id),
      buildItem(id: '00000000-0000-4000-8000-0000000000bb', name: 'Bread'),
    ]);

    await pump(tester);

    final milkRow = find.ancestor(
      of: find.text('Milk'),
      matching: find.byType(ItemTile),
    );
    final milkDot = tester.widget<Container>(
      find.descendant(
        of: milkRow,
        matching: find.byKey(const ValueKey('shop-dot')),
      ),
    );
    expect(
      (milkDot.decoration! as BoxDecoration).color,
      Color(colruyt.color.argb),
    );

    // Untagged: no dot, nothing to disambiguate.
    final breadRow = find.ancestor(
      of: find.text('Bread'),
      matching: find.byType(ItemTile),
    );
    expect(
      find.descendant(
        of: breadRow,
        matching: find.byKey(const ValueKey('shop-dot')),
      ),
      findsNothing,
    );
  });

  testWidgets('shows the empty state', (tester) async {
    await pump(tester);
    expect(find.text('Nothing on the list yet'), findsOneWidget);
    expect(find.text('Add your first product below.'), findsOneWidget);
  });

  testWidgets('ticking a box updates the row immediately', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    expect(
      tester.widget<ItemTile>(find.byType(ItemTile)).item.isChecked,
      isFalse,
    );

    await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
    await tester.pump();

    expect(
      tester.widget<ItemTile>(find.byType(ItemTile)).item.isChecked,
      isTrue,
    );

    // Let the 600 ms hold expire so no timer outlives the test.
    await tester.pump(RecentlyChecked.holdDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the row itself also toggles checked (decisions #82)', (
    tester,
  ) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    expect(
      tester.widget<ItemTile>(find.byType(ItemTile)).item.isChecked,
      isFalse,
    );

    await tester.tap(find.text('Milk'));
    await tester.pump();

    expect(
      tester.widget<ItemTile>(find.byType(ItemTile)).item.isChecked,
      isTrue,
    );

    await tester.pump(RecentlyChecked.holdDuration);
    await tester.pumpAndSettle();
  });

  // The design's rule: a ticked row keeps its place briefly, because
  // reordering under the finger reads as a mis-tap.
  testWidgets('a ticked row waits before dropping under Done', (tester) async {
    items.byListResult = Ok([
      buildItem(id: 'a', name: 'Milk'),
      buildItem(id: 'b', name: 'Bread'),
    ]);
    await pump(tester);

    await tester.tap(find.byKey(ItemTile.checkKey).first, warnIfMissed: false);
    await tester.pump();

    // Still holding its place: no divider yet.
    expect(find.byType(DoneDivider), findsNothing);

    await tester.pump(RecentlyChecked.holdDuration);
    await tester.pumpAndSettle();

    expect(find.byType(DoneDivider), findsOneWidget);
    expect(find.text('DONE · 1'), findsOneWidget);
  });

  testWidgets(
    'checking plays its exit from Open and entrance into Done concurrently',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk')]);
      await pump(tester);

      await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
      await tester.pump();
      await tester.pump(RecentlyChecked.holdDuration);
      // Mid-transition: the exiting Open copy and the entering Done copy
      // are both on screen at once.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Milk'), findsNWidgets(2));

      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.byType(DoneDivider), findsOneWidget);
    },
  );

  testWidgets(
    'checking rows in quick succession resets the shared debounce, then '
    'cascades them into Done one at a time',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
        buildItem(id: 'c', name: 'Eggs'),
      ]);
      await pump(tester);

      await tester.tap(
        find.byKey(ItemTile.checkKey).at(0),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Bread resets the debounce -- Milk must NOT settle on its own,
      // original 600ms-after-its-own-tap schedule.
      await tester.tap(
        find.byKey(ItemTile.checkKey).at(1),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DoneDivider), findsNothing);

      // Eggs resets it again.
      await tester.tap(
        find.byKey(ItemTile.checkKey).at(2),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DoneDivider), findsNothing);

      // 600ms after the *last* check, the held batch starts moving -- but
      // as a cascade, not all at once: Milk (checked first) starts right
      // away, Bread and Eggs are still just sitting there, unanimated.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Milk'), findsNWidgets(2));
      expect(find.text('Bread'), findsNWidgets(1));
      expect(find.text('Eggs'), findsNWidgets(1));

      // A third of the standard move duration later, Bread's turn starts.
      await tester.pump(const Duration(milliseconds: 87));
      expect(find.text('Bread'), findsNWidgets(2));
      expect(find.text('Eggs'), findsNWidgets(1));

      // ...and then Eggs'.
      await tester.pump(const Duration(milliseconds: 87));
      expect(find.text('Eggs'), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.byType(DoneDivider), findsOneWidget);
      expect(find.text('DONE · 3'), findsOneWidget);
    },
  );

  testWidgets(
    'unchecking starts its move back to Open immediately, no 600 ms wait',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
      await pump(tester);
      expect(find.byType(DoneDivider), findsOneWidget);

      await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
      // Nowhere near RecentlyChecked.holdDuration -- unchecking must not
      // need to wait it out the way checking does.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Milk'), findsNWidgets(2));

      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.byType(DoneDivider), findsNothing);
    },
  );

  testWidgets(
    'unchecking a row mid-cascade re-arms its return to Open instead of '
    'leaving it stuck invisible',
    (tester) async {
      // Regression for the bug where the item stays in the data but stops
      // rendering after being marked done: `RecentlyChecked.release` leaves
      // an already-`transitioning` row (not still `holding`) in
      // `transitioning` rather than dropping it, so the SAME, already-
      // mounted Open-side `ItemTile` element gets `checkMoveEntering`
      // flipped false->true again -- and only `didUpdateWidget`, not the
      // mount-only `didChangeDependencies`, can react to that on an
      // existing element.
      items.byListResult = Ok([buildItem(name: 'Milk')]);
      await pump(tester);

      await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
      await tester.pump();
      await tester.pump(RecentlyChecked.holdDuration);
      // Mid-cascade: moved into `transitioning`, exit under way but not
      // finished -- both the exiting Open copy and entering Done copy are
      // mounted at once (same window the "plays its exit ... concurrently"
      // test above exercises).
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Milk'), findsNWidgets(2));

      // Uncheck while still transitioning.
      await tester.tap(
        find.byKey(ItemTile.checkKey).first,
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Back to a single, fully-settled Open row -- not stuck collapsed.
      expect(find.text('Milk'), findsOneWidget);
      expect(find.byType(DoneDivider), findsNothing);
      final sizeTransition = tester.widget<SizeTransition>(
        find.ancestor(
          of: find.text('Milk'),
          matching: find.byType(SizeTransition),
        ),
      );
      expect(sizeTransition.sizeFactor.value, 1);
    },
  );

  testWidgets(
    'reduced motion collapses the open<->Done move to (near) instant',
    (tester) async {
      items.byListResult = Ok([buildItem(name: 'Milk')]);
      await pump(tester, reducedMotion: true);

      await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
      await tester.pump();
      await tester.pump(RecentlyChecked.holdDuration);
      // AppMotion.micro (120ms), not standard (260ms) -- settled well
      // before the ordinary, full-motion duration would have finished.
      await tester.pump(AppMotion.micro);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.byType(DoneDivider), findsOneWidget);
    },
  );

  testWidgets('the Done section folds away when tapped', (tester) async {
    items.byListResult = Ok([
      buildItem(id: 'a', name: 'Milk', isChecked: true),
      buildItem(id: 'b', name: 'Bread'),
    ]);
    await pump(tester);

    expect(find.text('Milk'), findsOneWidget);

    await tester.tap(find.byType(DoneDivider));
    await tester.pumpAndSettle();

    // Folded, not deleted -- the divider still reports what is in there.
    expect(find.text('DONE · 1'), findsOneWidget);
    expect(find.text('Milk'), findsNothing);
  });

  testWidgets('Clear checked removes the checked rows, leaves the rest', (
    tester,
  ) async {
    items.byListResult = Ok([
      buildItem(id: 'a', name: 'Milk', isChecked: true),
      buildItem(id: 'b', name: 'Bread', isChecked: true),
      buildItem(id: 'c', name: 'Eggs'),
    ]);
    await pump(tester);

    await tester.tap(find.text('Clear checked'));
    await tester.pumpAndSettle();

    expect(items.clearCheckedCallCount, 1);
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Bread'), findsNothing);
    expect(find.text('Eggs'), findsOneWidget);
  });

  testWidgets('a rejected clear puts the checked rows back', (tester) async {
    items.byListResult = Ok([
      buildItem(id: 'a', name: 'Milk', isChecked: true),
      buildItem(id: 'b', name: 'Eggs'),
    ]);
    items.clearCheckedResult = const Err(Failure.network('offline'));
    await pump(tester);

    await tester.tap(find.text('Clear checked'));
    await tester.pumpAndSettle();

    // The optimistic removal rolled back, and the row is still checked, not
    // reinserted unchecked.
    expect(find.text('Milk'), findsOneWidget);
    final milkTile = find.ancestor(
      of: find.text('Milk'),
      matching: find.byType(ItemTile),
    );
    expect(tester.widget<ItemTile>(milkTile).item.isChecked, isTrue);
  });

  testWidgets('nothing checked means no clear action to tap', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    expect(find.text('Clear checked'), findsNothing);
  });

  testWidgets(
    'swiping a row away removes it once the undo window passes',
    (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
      ]);
      await pump(tester);

      await tester.drag(
        find.widgetWithText(Dismissible, 'Milk'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Hidden the instant the swipe commits -- the server has not been
      // told yet.
      expect(find.text('Milk'), findsNothing);
      expect(find.text('Bread'), findsOneWidget);
      expect(items.removedIds, isEmpty);

      await tester.pump(ItemsController.swipeUndoWindow);
      await tester.pumpAndSettle();

      expect(items.removedIds.single, ItemId('a'));
    },
  );

  testWidgets('the undo snackbar action restores a swiped-away row', (
    tester,
  ) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);

    // Undone means the server is never told, even once the window that
    // would otherwise have committed the delete has passed.
    await tester.pump(ItemsController.swipeUndoWindow);
    await tester.pumpAndSettle();
    expect(items.removedIds, isEmpty);
  });

  group('drag to reorder', () {
    final colruyt = ShopId('shop-colruyt');
    // Matches buildList()'s default id -- there is only ever the one list on
    // screen in this file's pump().
    final listId = ListId('00000000-0000-4000-8000-000000000001');

    testWidgets(
      'no drag handle on the "All" tab -- reordering is scoped to one shop',
      (
        tester,
      ) async {
        items.byListResult = Ok([
          buildItem(id: 'a', name: 'Milk', shopId: colruyt),
          buildItem(id: 'b', name: 'Bread', shopId: colruyt),
        ]);
        await pump(tester);

        expect(find.byIcon(Icons.drag_handle), findsNothing);
      },
    );

    testWidgets('a handle appears once a shop tab is active', (tester) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk', shopId: colruyt),
        buildItem(id: 'b', name: 'Bread', shopId: colruyt),
      ]);
      final container = await pump(tester);

      container.read(shopFilterProvider(listId).notifier).select(colruyt);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
    });

    testWidgets('checked rows never show a drag handle, even on a shop tab', (
      tester,
    ) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk', shopId: colruyt),
        buildItem(id: 'b', name: 'Bread', shopId: colruyt, isChecked: true),
      ]);
      final container = await pump(tester);

      container.read(shopFilterProvider(listId).notifier).select(colruyt);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('dragging the handle to the top saves a lower sortOrder', (
      tester,
    ) async {
      items.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk', shopId: colruyt, sortOrder: 10),
        buildItem(id: 'b', name: 'Bread', shopId: colruyt, sortOrder: 20),
        buildItem(id: 'c', name: 'Eggs', shopId: colruyt, sortOrder: 30),
      ]);
      final container = await pump(tester);
      container.read(shopFilterProvider(listId).notifier).select(colruyt);
      await tester.pumpAndSettle();

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
    });

    testWidgets(
      'a checked-and-transitioning row does not corrupt reorder index math',
      (tester) async {
        items.byListResult = Ok([
          buildItem(id: 'a', name: 'Milk', shopId: colruyt, sortOrder: 10),
          buildItem(id: 'b', name: 'Bread', shopId: colruyt, sortOrder: 20),
          buildItem(id: 'c', name: 'Eggs', shopId: colruyt, sortOrder: 30),
        ]);
        final container = await pump(tester);
        container.read(shopFilterProvider(listId).notifier).select(colruyt);
        await tester.pumpAndSettle();

        // Check Milk, then immediately -- still held/transitioning, exactly
        // as an unchecked row would be -- drag Eggs up past it and Bread.
        // Milk stays a member of the open rows the whole time (the existing
        // hold mechanic), so the drag's index math must still land right.
        await tester.tap(
          find.byKey(ItemTile.checkKey).first,
          warnIfMissed: false,
        );
        await tester.pump();

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

        // Let Milk's own hold/transition finish so its RecentlyChecked
        // timers don't outlive the test.
        await tester.pump(RecentlyChecked.holdDuration);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('a conflict unticks the row and says why', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    items.saveResult = const Err(Failure.conflict());
    await pump(tester);

    await tester.tap(find.byKey(ItemTile.checkKey), warnIfMissed: false);
    await tester.pump(RecentlyChecked.holdDuration);
    await tester.pumpAndSettle();

    // Rolled back...
    expect(
      tester.widget<ItemTile>(find.byType(ItemTile)).item.isChecked,
      isFalse,
    );
    // ...and explained, so the revert does not look like a bug.
    expect(
      find.text('Someone else just changed this. Try again.'),
      findsOneWidget,
    );
  });

  group('editing an item (the same sheet adding uses)', () {
    final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
    final bakery = buildShop(
      id: '00000000-0000-4000-8000-0000000000c2',
      name: 'Bakery',
      color: '#C62828',
    );

    testWidgets('opens pre-filled, titled Edit product, with a Save button '
        '-- not the add sheet\'s own title and button', (tester) async {
      shops.byListResult = Ok([colruyt]);
      items.byListResult = Ok([
        buildItem(name: 'Milk', quantity: 3, shopId: colruyt.id),
      ]);
      await pump(tester);

      // Tapping the row toggles checked now (decisions #82); editing has its
      // own trailing icon button.
      await tester.tap(find.byKey(ItemTile.editKey));
      await tester.pumpAndSettle();

      expect(find.text('Edit product'), findsOneWidget);
      expect(find.text('New product'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      final nameField = tester
          .widgetList<TextField>(find.byType(TextField))
          .firstWhere((f) => f.controller?.text == 'Milk');
      expect(nameField.controller?.text, 'Milk');
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('saving can change the shop, not just the name/quantity/note', (
      tester,
    ) async {
      shops.byListResult = Ok([colruyt, bakery]);
      final item = buildItem(name: 'Milk', shopId: colruyt.id);
      items.byListResult = Ok([item]);
      await pump(tester);

      await tester.tap(find.byKey(ItemTile.editKey));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Bakery'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(items.savedItems.single.shopId, bakery.id);
    });

    testWidgets('Remove takes the item off the list', (tester) async {
      final item = buildItem(name: 'Milk');
      items.byListResult = Ok([item]);
      items.removeResult = const Ok(null);
      await pump(tester);

      await tester.tap(find.byKey(ItemTile.editKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsNothing);
    });

    testWidgets('the add sheet has no Remove action -- there is nothing '
        'to remove yet', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('New product'), findsOneWidget);
      expect(find.text('Remove'), findsNothing);
    });
  });

  group('suggestion chips', () {
    testWidgets('appear once two characters settle, and fill the field '
        'when tapped', (tester) async {
      items.suggestNamesResult = const Ok(['Olive oil', 'Olives']);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ol');
      // Explicit, past the 300 ms debounce -- pumpAndSettle alone only
      // advances time for as long as something else keeps a frame
      // scheduled, which nothing does once the FAB's own open animation has
      // already settled.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Olive oil'), findsOneWidget);
      expect(find.text('Olives'), findsOneWidget);

      await tester.tap(find.text('Olives'));
      await tester.pumpAndSettle();

      final barField = tester
          .widgetList<TextField>(find.byType(TextField))
          .firstWhere((f) => f.controller?.text == 'Olives');
      expect(barField.controller?.text, 'Olives');
    });

    testWidgets('nothing under two characters -- no request, no chips', (
      tester,
    ) async {
      items.suggestNamesResult = const Ok(['Olive oil']);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'o');
      await tester.pumpAndSettle();

      expect(items.suggestNamesCalls, isEmpty);
      expect(find.text('Olive oil'), findsNothing);
    });

    testWidgets('the request waits out the debounce, not fired immediately '
        'on the keystroke that reaches two characters', (tester) async {
      items.suggestNamesResult = const Ok(['Olive oil']);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'oli');

      // A single frame, no time advanced: still inside the debounce window.
      await tester.pump();
      expect(items.suggestNamesCalls, isEmpty);

      await tester.pump(const Duration(milliseconds: 350));
      expect(items.suggestNamesCalls, hasLength(1));
      expect(items.suggestNamesCalls.single.query, 'oli');
    });
  });

  group('the quick-add bar follows the active shop tab', () {
    final listId = ListId('00000000-0000-4000-8000-000000000001');
    final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');

    testWidgets('placeholder and leading dot only appear once a shop tab '
        'is active', (tester) async {
      shops.byListResult = Ok([colruyt]);
      final container = await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // "All" tab: the generic placeholder, no dot.
      expect(find.text('What do you need?'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-add-dot')), findsNothing);

      container.read(shopFilterProvider(listId).notifier).select(colruyt.id);
      await tester.pumpAndSettle();

      expect(find.text('Add to Colruyt'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-add-dot')), findsOneWidget);
    });

    testWidgets(
      'the icon button greys out while empty, and colours in once there '
      'is text',
      (tester) async {
        await pump(tester);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        Color bgOf() =>
            (tester
                        .widget<AnimatedContainer>(
                          find.byKey(const ValueKey('quick-add-icon-bg')),
                        )
                        .decoration!
                    as BoxDecoration)
                .color!;

        final emptyBg = bgOf();
        await tester.enterText(find.byType(TextField), 'Bread');
        await tester.pumpAndSettle();
        final typedBg = bgOf();

        expect(emptyBg, isNot(typedBg));
      },
    );

    testWidgets(
      'the Enter fast path tags the new item to the active shop tab, '
      'the same as the details sheet does',
      (tester) async {
        shops.byListResult = Ok([colruyt]);
        items.addResult = Ok(buildItem(name: 'Pasta'));
        final container = await pump(tester);

        container.read(shopFilterProvider(listId).notifier).select(colruyt.id);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Pasta');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(items.addCalls.single.shopId, colruyt.id);
      },
    );
  });

  testWidgets(
    "a newly added row's entrance flash is gone well after 900 ms, so "
    'switching shop tabs later does not replay it',
    (tester) async {
      final listId = ListId('00000000-0000-4000-8000-000000000001');
      // Non-empty from the start, so _ItemList (and its watch of
      // recentlyAddedProvider) is already mounted before the add lands --
      // an empty list renders the empty state instead, which watches
      // nothing here.
      items.byListResult = Ok([buildItem(id: 'existing', name: 'Milk')]);
      items.addResult = Ok(buildItem(name: 'Bread'));
      final container = await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Flushes the add's own await chain (bar -> onQuickAdd -> controller
      // -> repository) without advancing the clock -- a single bare pump()
      // is not enough for every hop of it, and pumpAndSettle() would also
      // drive the 900 ms flash timer to completion before this can check it
      // was ever set.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(
        container.read(recentlyAddedProvider(listId)),
        isNotNull,
        reason: 'the row should be flagged the instant the add lands',
      );

      await tester.pump(const Duration(milliseconds: 1000));
      expect(container.read(recentlyAddedProvider(listId)), isNull);
    },
  );

  testWidgets('the quick-add button rolls a field out, then back in', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    // Empty: the same glyph has rotated into an "x" -- tapping it again
    // cancels, rolling the field back in.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'the same + glyph rotates into an x, then back into a + once typed',
    (tester) async {
      await pump(tester);

      double turnsOf() =>
          tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

      // Collapsed: a plain +.
      expect(turnsOf(), 0);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      // Expanded, empty: rotated 1/8 turn into an x.
      expect(turnsOf(), 0.125);

      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pumpAndSettle();
      // Text typed: rotated back to a +, now meaning "open the details sheet".
      expect(turnsOf(), 0);
    },
  );

  testWidgets('adding an item clears the field for the next one', (
    tester,
  ) async {
    items.addResult = Ok(buildItem(name: 'Bread'));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
      reason: 'adding several things in a row is the common case',
    );
    // Still rolled out and focused, not collapsed back to a bare button --
    // that is what makes adding several things in a row actually fast.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a rejected add keeps the text for a retry', (tester) async {
    items.addResult = const Err(Failure.network('offline'));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Bread',
    );
    expect(find.text('Could not reach the server.'), findsOneWidget);
  });

  testWidgets(
    'the details sheet pre-selects whichever shop tab is active, '
    'but it can still be changed',
    (tester) async {
      final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c2',
        name: 'Bakery',
        color: '#C62828',
      );
      shops.byListResult = Ok([colruyt, bakery]);
      items.addResult = Ok(buildItem(name: 'Bread'));
      final container = await pump(tester);

      container
          .read(
            shopFilterProvider(
              ListId('00000000-0000-4000-8000-000000000001'),
            ).notifier,
          )
          .select(colruyt.id);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Colruyt's chip starts selected -- the active tab when the sheet
      // was opened -- without needing to tap it.
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Colruyt'))
            .selected,
        isTrue,
      );

      // Still just a starting point: switching to Bakery before saving
      // tags the item to Bakery, not the tab it was opened from.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Bakery'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
      await tester.pumpAndSettle();

      expect(items.addCalls.single.shopId, bakery.id);
    },
  );

  testWidgets(
    'typing rotates the button to a plus that opens the details sheet',
    (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pump();

      // The name typed in the bar carries straight over.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // The sheet has two fields now (name, note) -- the name one is the
      // one that should carry "Bread" over from the bar.
      final sheetFields = tester.widgetList<TextField>(
        find.descendant(
          of: find.byType(ItemSheet),
          matching: find.byType(TextField),
        ),
      );
      expect(
        sheetFields.map((f) => f.controller?.text),
        contains('Bread'),
      );
    },
  );

  testWidgets(
    'the details sheet adds with the chosen quantity, shop and note, '
    'then clears and collapses the bar',
    (tester) async {
      items.addResult = Ok(buildItem(name: 'Bread'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Bump the quantity to 2, jot a note, then save from the sheet.
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Note (optional)'),
        'the seeded loaf',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
      await tester.pumpAndSettle();

      expect(items.addCalls.single.quantity, 2);
      expect(items.addCalls.single.name, 'Bread');
      expect(items.addCalls.single.noteText, 'the seeded loaf');

      // Back to a bare button: the bar does not sit there half-full once
      // the sheet has actually added the item.
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'a cancelled details sheet leaves the typed name in the bar',
    (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Dismiss the sheet without saving (drag handle / tap the scrim).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(items.addCalls, isEmpty);
      final barField = tester
          .widgetList<TextField>(find.byType(TextField))
          .single;
      expect(barField.controller?.text, 'Bread');
    },
  );

  group('completion celebration', () {
    testWidgets('shows once every item on the list is checked', (
      tester,
    ) async {
      items.byListResult = Ok([
        buildItem(name: 'Milk', isChecked: true),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000bb',
          name: 'Bread',
          isChecked: true,
        ),
      ]);

      await pump(tester);

      expect(find.text('All done — 2 items'), findsOneWidget);
      expect(find.text('Keep list'), findsOneWidget);
    });

    testWidgets('does not show while anything is still open', (
      tester,
    ) async {
      items.byListResult = Ok([
        buildItem(name: 'Milk', isChecked: true),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000bb',
          name: 'Bread',
        ),
      ]);

      await pump(tester);

      expect(find.text('Keep list'), findsNothing);
    });

    testWidgets('Keep list dismisses it without touching any items', (
      tester,
    ) async {
      items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
      await pump(tester);

      await tester.tap(find.text('Keep list'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Keep list'), findsNothing);
      expect(items.clearCheckedCallCount, 0);
    });

    testWidgets(
      'Clear checked calls through to the same action as the Done '
      'divider button',
      (tester) async {
        items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
        items.clearCheckedResult = const Ok(1);
        await pump(tester);

        // "Clear checked" appears twice once the list is fully done -- once
        // on the Done divider, once on the celebration card itself.
        await tester.tap(
          find.descendant(
            of: find.byType(CompletionCelebrationCard),
            matching: find.text('Clear checked'),
          ),
        );
        await tester.pumpAndSettle();

        expect(items.clearCheckedCallCount, 1);
      },
    );

    testWidgets(
      'a dismissal does not carry over once the list is no longer '
      'fully checked, so it can show again the next time it is',
      (tester) async {
        items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
        await pump(tester);

        await tester.tap(find.text('Keep list'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Keep list'), findsNothing);

        // Someone adds a fresh, unchecked item -- the list is no longer
        // fully done, so the dismissal should stop applying.
        items.live.add(
          Ok([
            buildItem(name: 'Milk', isChecked: true),
            buildItem(
              id: '00000000-0000-4000-8000-0000000000bb',
              name: 'Bread',
            ),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text('Keep list'), findsNothing); // still one item open.

        // Checking it off completes the list again -- the celebration
        // should show once more, not stay silenced by the earlier dismissal.
        items.live.add(
          Ok([
            buildItem(name: 'Milk', isChecked: true),
            buildItem(
              id: '00000000-0000-4000-8000-0000000000bb',
              name: 'Bread',
              isChecked: true,
            ),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text('Keep list'), findsOneWidget);
      },
    );
  });

  group('clear checked after shopping (decisions #79)', () {
    testWidgets(
      'auto-clears silently, with no celebration card, once the list '
      'finishes',
      (tester) async {
        final list = buildList(
          members: [buildMember(displayName: 'Nikolaos')],
          clearCheckedAfterShopping: true,
        );
        items.byListResult = Ok([
          buildItem(name: 'Milk', isChecked: true),
          buildItem(
            id: '00000000-0000-4000-8000-0000000000bb',
            name: 'Bread',
          ),
        ]);
        items.clearCheckedResult = const Ok(1);
        await pump(tester, list: list);
        expect(find.text('Keep list'), findsNothing);

        // The last open item gets checked -- the list finishes.
        items.live.add(
          Ok([
            buildItem(name: 'Milk', isChecked: true),
            buildItem(
              id: '00000000-0000-4000-8000-0000000000bb',
              name: 'Bread',
              isChecked: true,
            ),
          ]),
        );
        await tester.pumpAndSettle();

        expect(items.clearCheckedCallCount, 1);
        expect(find.byType(CompletionCelebrationCard), findsNothing);
        expect(find.text('Keep list'), findsNothing);
      },
    );

    testWidgets(
      'does not fire again once already fully checked with nothing new',
      (tester) async {
        final list = buildList(
          members: [buildMember(displayName: 'Nikolaos')],
          clearCheckedAfterShopping: true,
        );
        // Starts already fully checked -- there is no open-to-done
        // *transition* to react to, so nothing should auto-clear on load.
        items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
        await pump(tester, list: list);

        expect(items.clearCheckedCallCount, 0);
      },
    );

    testWidgets(
      'the celebration card still shows when the preference is off',
      (tester) async {
        final list = buildList(
          members: [buildMember(displayName: 'Nikolaos')],
        );
        items.byListResult = Ok([buildItem(name: 'Milk', isChecked: true)]);
        await pump(tester, list: list);

        expect(find.byType(CompletionCelebrationCard), findsOneWidget);
        expect(items.clearCheckedCallCount, 0);
      },
    );
  });
}
