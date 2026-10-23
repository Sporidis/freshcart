import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_filter_bar.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

/// `Icons.add` also appears on the quick-add bar's glyph, pumped alongside
/// `ShopFilterBar` in every test here -- scope to the bar so the finder
/// stays unambiguous.
final Finder _addPillIcon = find.descendant(
  of: find.byType(ShopFilterBar),
  matching: find.byIcon(Icons.add),
);

/// A tab pill by its label, scoped to the bar: on All, rows also show their
/// shop's name in the subtitle.
Finder pill(String label) => find.descendant(
  of: find.byType(ShopFilterBar),
  matching: find.textContaining(label),
);

void main() {
  setUpAll(configurePluralResolvers);

  late FakeItemRepository items;
  late FakeShopRepository shops;
  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final colruyt = buildShop(name: 'Colruyt', color: '#4CAF50');
  final bakery = buildShop(
    id: '00000000-0000-4000-8000-0000000000c2',
    name: 'Bakery',
    color: '#C62828',
  );

  setUp(() {
    items = FakeItemRepository();
    shops = FakeShopRepository();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final list = buildList(members: [buildMember()]);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(items),
        shopRepositoryProvider.overrideWithValue(shops),
        currentUserIdProvider.overrideWith((ref) async => Ok(UserId('user-1'))),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShopFilterBar(
                  listId: listId,
                  revealKey: GlobalKey<ShopThemeRevealState>(),
                ),
                Expanded(child: ItemsSection(list: list)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('ShopFilterBar', () {
    testWidgets(
      'still shows "All" and the add pill when the list has no shops',
      (tester) async {
        // Component Library §02: "All" and the dashed "+" are permanent
        // furniture on every list, not conditional on having shops yet --
        // the strip no longer disappears the way the old FilterChip row did.
        await pump(tester);
        expect(find.text('All shops'), findsOneWidget);
        expect(_addPillIcon, findsOneWidget);
      },
    );

    testWidgets('offers every shop plus an "all shops" chip', (tester) async {
      shops.byListResult = Ok([colruyt, bakery]);
      await pump(tester);

      expect(find.text('All shops'), findsOneWidget);
      expect(find.text('Colruyt'), findsOneWidget);
      expect(find.text('Bakery'), findsOneWidget);
    });

    testWidgets('the dashed + pill opens the create-shop sheet', (
      tester,
    ) async {
      shops.byListResult = Ok([colruyt]);
      final container = await pump(tester);

      await tester.tap(_addPillIcon);
      await tester.pumpAndSettle();

      // The sheet itself, not just the tooltip -- "Shop name" only exists
      // once ShopSheet is actually open.
      expect(
        find.text(container.read(translationsProvider).shops.nameLabel),
        findsOneWidget,
      );
    });

    testWidgets('a leftward flick steps to the next tab, same as a tap', (
      tester,
    ) async {
      shops.byListResult = Ok([colruyt, bakery]);
      items.byListResult = Ok([
        buildItem(name: 'Milk').copyWith(shopId: colruyt.id),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000b3',
          name: 'Cake',
        ).copyWith(shopId: bakery.id),
      ]);
      final container = await pump(tester);
      expect(container.read(shopFilterControllerProvider(listId)), isNull);

      // All -> Colruyt.
      await tester.fling(
        find.byType(ShopFilterBar),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(container.read(shopFilterControllerProvider(listId)), colruyt.id);
      expect(find.text('Cake'), findsNothing);

      // Colruyt -> Bakery.
      await tester.fling(
        find.byType(ShopFilterBar),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(container.read(shopFilterControllerProvider(listId)), bakery.id);

      // A rightward flick steps back.
      await tester.fling(
        find.byType(ShopFilterBar),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(container.read(shopFilterControllerProvider(listId)), colruyt.id);
    });
  });

  group('filtering', () {
    testWidgets('selecting a shop narrows the visible items', (tester) async {
      shops.byListResult = Ok([colruyt, bakery]);
      // Milk is tagged to Colruyt, Cake to the bakery, Bread left untagged.
      items.byListResult = Ok([
        buildItem(name: 'Milk').copyWith(shopId: colruyt.id),
        buildItem(id: '00000000-0000-4000-8000-0000000000b2', name: 'Bread'),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000b3',
          name: 'Cake',
        ).copyWith(shopId: bakery.id),
      ]);

      final container = await pump(tester);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cake'), findsOneWidget);

      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(colruyt.id);
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cake'), findsNothing);
      // An untagged item stays visible under every filter, so a forgotten tag
      // never hides someone's shopping.
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('tapping a chip actually filters -- not just setting the '
        'provider directly', (tester) async {
      shops.byListResult = Ok([colruyt, bakery]);
      items.byListResult = Ok([
        buildItem(name: 'Milk').copyWith(shopId: colruyt.id),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000b3',
          name: 'Cake',
        ).copyWith(shopId: bakery.id),
      ]);

      await pump(tester);
      expect(find.text('Cake'), findsOneWidget);

      // Chip labels carry a remaining count ("Colruyt · 1"), so match the
      // shop name as a substring rather than the bare name.
      await tester.tap(pill('Colruyt'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cake'), findsNothing);

      // ShopTabPill is a tab, not a toggle chip: tapping the already-active
      // tab again is a no-op, not a deselect -- "All" is the one way back,
      // matching how a real TabBar behaves.
      await tester.tap(pill('Colruyt'));
      await tester.pumpAndSettle();
      expect(find.text('Cake'), findsNothing);

      // "All shops" is the way back, from any shop's tab.
      await tester.tap(pill('Bakery'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsNothing);

      await tester.tap(pill('All shops'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cake'), findsOneWidget);
    });

    testWidgets(
      'one highlight slides under whichever tab is selected',
      (tester) async {
        shops.byListResult = Ok([colruyt, bakery]);
        items.byListResult = Ok([buildItem(name: 'Milk')]);

        await pump(tester);

        final highlight = find.descendant(
          of: find.byType(ShopFilterBar),
          matching: find.byType(AnimatedPositioned),
        );
        double centreOf(Finder f) => tester.getCenter(f).dx;
        final tab = find.ancestor(
          of: pill('Bakery'),
          matching: find.byType(ShopTabPill),
        );

        expect(highlight, findsOneWidget);
        expect(
          centreOf(highlight),
          closeTo(
            centreOf(
              find.ancestor(
                of: pill('All shops'),
                matching: find.byType(ShopTabPill),
              ),
            ),
            1,
          ),
        );

        await tester.tap(pill('Bakery'));
        await tester.pumpAndSettle();

        expect(centreOf(highlight), closeTo(centreOf(tab), 1));
      },
    );

    testWidgets('clearing the filter shows everything again', (tester) async {
      shops.byListResult = Ok([colruyt, bakery]);
      items.byListResult = Ok([
        buildItem(name: 'Milk').copyWith(shopId: colruyt.id),
        buildItem(
          id: '00000000-0000-4000-8000-0000000000b3',
          name: 'Cake',
        ).copyWith(shopId: bakery.id),
      ]);

      final container = await pump(tester);
      final filter = container.read(
        shopFilterControllerProvider(listId).notifier,
      );

      filter.select(colruyt.id);
      await tester.pumpAndSettle();
      expect(find.text('Cake'), findsNothing);

      filter.select(null);
      await tester.pumpAndSettle();
      expect(find.text('Cake'), findsOneWidget);
    });
  });

  group('activeShopColor', () {
    testWidgets('is null with no filter, and the shop colour with one', (
      tester,
    ) async {
      shops.byListResult = Ok([colruyt, bakery]);
      final container = await pump(tester);

      expect(container.read(activeShopColorProvider(listId)), isNull);

      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(bakery.id);
      await tester.pumpAndSettle();

      expect(
        container.read(activeShopColorProvider(listId))?.toHex(),
        '#C62828',
      );
    });

    testWidgets('is null for a shop that is no longer in the list', (
      tester,
    ) async {
      shops.byListResult = Ok([colruyt]);
      final container = await pump(tester);

      // A stale filter — the shop was deleted by someone else.
      container
          .read(shopFilterControllerProvider(listId).notifier)
          .select(bakery.id);
      await tester.pumpAndSettle();

      expect(container.read(activeShopColorProvider(listId)), isNull);
    });
  });
}
