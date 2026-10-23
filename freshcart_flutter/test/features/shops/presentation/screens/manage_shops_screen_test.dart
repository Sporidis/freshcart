import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/presentation/screens/manage_shops_screen.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/dashed_add_row.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  final listId = ListId('00000000-0000-4000-8000-000000000001');
  const blue = 0xFF2456A6;
  const orange = 0xFFE8791A;

  late FakeShopRepository shops;

  Shop shop(String id, String name, int argb) => Shop(
    id: ShopId(id),
    listId: listId,
    name: name,
    color: HexColor.fromArgb(argb),
  );

  setUp(() => shops = FakeShopRepository());

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [shopRepositoryProvider.overrideWithValue(shops)],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppTheme.brandSeed),
          home: ManageShopsScreen(listId: listId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('adding a shop', () {
    testWidgets('the empty state offers to add one', (tester) async {
      shops.byListResult = const Ok([]);
      await pump(tester);

      expect(find.text('No shop'), findsOneWidget);
      // The empty state's own action, not a FAB — same rule as ListsScreen.
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Add shop'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<ShopSheet>(find.byType(ShopSheet));
      expect(sheet.shop, isNull, reason: 'create mode, not editing anything');
      expect(find.text('Add shop'), findsWidgets);
    });

    testWidgets('the dashed row at the end opens the same sheet', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      await pump(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.byType(DashedAddRow));
      await tester.pumpAndSettle();

      final sheet = tester.widget<ShopSheet>(find.byType(ShopSheet));
      expect(sheet.shop, isNull);
      // The existing shop is still a sibling, for the clash warning.
      expect(sheet.siblings, hasLength(1));
    });

    testWidgets('saving commits through create and refreshes the list', (
      tester,
    ) async {
      shops.byListResult = const Ok([]);
      shops.createResult = Ok(shop('s1', 'Aldi', orange));
      await pump(tester);

      await tester.tap(find.text('Add shop'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Aldi');
      final callsBefore = shops.byListCallCount;
      // Two "Add shop" texts once the sheet is open: the header and the
      // button, so target the button specifically.
      await tester.tap(
        find.descendant(
          of: find.byType(ShopSheet),
          matching: find.widgetWithText(ElevatedButton, 'Add shop'),
        ),
      );
      await tester.pumpAndSettle();

      expect(shops.createCalls.single.name, 'Aldi');
      expect(shops.createCalls.single.listId, listId);
      expect(find.byType(ShopSheet), findsNothing);
      expect(
        shops.byListCallCount,
        greaterThan(callsBefore),
        reason: 'a successful create must refresh the collection',
      );
    });

    testWidgets('a rejected name keeps the sheet open', (tester) async {
      shops.byListResult = const Ok([]);
      shops.createResult = const Err(
        Failure.validation(ValidationIssue.missing(ValidatedInput.shopName)),
      );
      await pump(tester);

      await tester.tap(find.text('Add shop'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ShopSheet),
          matching: find.widgetWithText(ElevatedButton, 'Add shop'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShopSheet), findsOneWidget);
      expect(find.text('Give the shop a name'), findsOneWidget);
    });
  });

  testWidgets('lists the shops on the list', (tester) async {
    shops.byListResult = Ok([
      shop('s1', 'Albert Heijn', blue),
      shop('s2', 'Colruyt', orange),
    ]);

    await pump(tester);

    expect(find.text('Albert Heijn'), findsOneWidget);
    expect(find.text('Colruyt'), findsOneWidget);
  });

  // The design's "best part of the flow": the consequence is visible before
  // it is committed.
  testWidgets('picking a swatch previews before anything is saved', (
    tester,
  ) async {
    shops.byListResult = Ok([shop('s1', 'Albert Heijn', blue)]);
    final container = await pump(tester);

    await tester.tap(find.text('Albert Heijn'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopSheet), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('swatch-$orange')));
    await tester.pumpAndSettle();

    final preview = container.read(shopColorPreviewControllerProvider);
    expect(preview?.color.argb, isNot(blue));
    // Nothing committed yet — the preview is not a write.
    expect(shops.savedShops, isEmpty);
  });

  testWidgets('the row being edited takes the previewed colour as its border', (
    tester,
  ) async {
    shops.byListResult = Ok([shop('s1', 'Albert Heijn', blue)]);
    await pump(tester);

    await tester.tap(find.text('Albert Heijn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swatch-$orange')));
    await tester.pumpAndSettle();

    // The row behind the sheet, not the sheet's own name field.
    final row = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.descendant(
              of: find.byType(ManageShopsScreen),
              matching: find.text('Albert Heijn'),
            ),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final border = (row.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, const Color(orange));
  });

  testWidgets('a colour another shop already uses is marked, not blocked', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    shops.byListResult = Ok([
      shop('s1', 'Albert Heijn', blue),
      shop('s2', 'Colruyt', orange),
    ]);
    await pump(tester);

    await tester.tap(find.text('Colruyt'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Used by Albert Heijn')),
      findsOneWidget,
    );
    // Still pickable.
    await tester.tap(find.byKey(const ValueKey('swatch-$blue')));
    await tester.pumpAndSettle();
    expect(find.text('Close to Albert Heijn'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an abandoned preview does not outlive the sheet', (
    tester,
  ) async {
    shops.byListResult = Ok([shop('s1', 'Albert Heijn', blue)]);
    final container = await pump(tester);

    await tester.tap(find.text('Albert Heijn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swatch-$orange')));
    await tester.pumpAndSettle();
    expect(container.read(shopColorPreviewControllerProvider), isNotNull);

    // Dismiss without saving.
    Navigator.of(tester.element(find.byType(ShopSheet))).pop();
    await tester.pumpAndSettle();

    expect(
      container.read(shopColorPreviewControllerProvider),
      isNull,
      reason: 'a colour left tinting the app would lie about what is stored',
    );
    expect(shops.savedShops, isEmpty);
  });

  testWidgets('warns, but does not block, on a confusable colour', (
    tester,
  ) async {
    shops.byListResult = Ok([
      shop('s1', 'Albert Heijn', blue),
      // Near-identical blue: distinguishable in a picker, not in an aisle.
      shop('s2', 'Delhaize', 0xFF2A5AAA),
    ]);
    await pump(tester);

    await tester.tap(find.text('Delhaize'));
    await tester.pumpAndSettle();

    expect(find.text('Close to Albert Heijn'), findsOneWidget);
    // A warning, never a block.
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  group('deleting a shop', () {
    /// Delete is a swipe now, right-to-left past the 40% threshold -- never
    /// a trash icon one tap away on every row.
    Future<void> swipeToDelete(WidgetTester tester, String name) async {
      await tester.drag(find.text(name), const Offset(-600, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('rows carry no trash icon -- delete is a deliberate swipe', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      await pump(tester);

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('a short swipe springs back without asking anything', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 6;
      await pump(tester);

      // Well under 40% of an 800 px-wide test surface.
      await tester.drag(find.text('Colruyt'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete Colruyt?'), findsNothing);
      expect(find.text('Colruyt'), findsOneWidget);
    });

    testWidgets('a full swipe asks first, and the row survives a cancel', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 6;
      await pump(tester);

      await swipeToDelete(tester, 'Colruyt');
      expect(find.text('Delete Colruyt?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(shops.removeCalls, isEmpty);
      expect(find.text('Colruyt'), findsOneWidget);
    });
    testWidgets('a shop holding products offers real alternatives', (
      tester,
    ) async {
      shops.byListResult = Ok([
        shop('s1', 'Colruyt', orange),
        shop('s2', 'Albert Heijn', blue),
      ]);
      shops.itemCountResult = 6;

      await pump(tester);
      await swipeToDelete(tester, 'Colruyt');
      await tester.pumpAndSettle();

      // The count leads, because it is the question.
      expect(
        find.text('Colruyt has 6 products. Choose what happens to them.'),
        findsOneWidget,
      );
      // Three real options, not OK/Cancel.
      expect(find.text('Move them to Albert Heijn'), findsOneWidget);
      expect(find.text('Leave them without a shop'), findsOneWidget);
      expect(find.text('Delete products too'), findsOneWidget);
      // Nothing has happened yet.
      expect(shops.removeCalls, isEmpty);
    });

    testWidgets('choosing a destination moves the products', (tester) async {
      shops.byListResult = Ok([
        shop('s1', 'Colruyt', orange),
        shop('s2', 'Albert Heijn', blue),
      ]);
      shops.itemCountResult = 6;

      await pump(tester);
      await swipeToDelete(tester, 'Colruyt');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move them to Albert Heijn'));
      await tester.pumpAndSettle();

      final call = shops.removeCalls.single;
      expect(call.disposition, ShopItemDisposition.moveToShop);
      expect(call.moveTo, ShopId('s2'));
    });

    testWidgets('deleting the products too is asked for explicitly', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 6;

      await pump(tester);
      await swipeToDelete(tester, 'Colruyt');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete products too'));
      await tester.pumpAndSettle();

      expect(
        shops.removeCalls.single.disposition,
        ShopItemDisposition.deleteItems,
      );
    });

    testWidgets('an empty shop is not asked about its products', (
      tester,
    ) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 0;

      await pump(tester);
      await swipeToDelete(tester, 'Colruyt');
      await tester.pumpAndSettle();

      expect(find.text('This shop has no products.'), findsOneWidget);
      expect(find.text('Delete products too'), findsNothing);

      // The confirm is the destructive red, named for what it deletes --
      // not the ink primary every safe action uses.
      final confirm = find.widgetWithText(ElevatedButton, 'Delete Colruyt');
      expect(confirm, findsOneWidget);
      final style = tester.widget<ElevatedButton>(confirm).style!;
      expect(
        style.backgroundColor?.resolve({}),
        AppColors.destructive,
      );
    });

    testWidgets('dismissing the sheet deletes nothing', (tester) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 6;

      await pump(tester);
      await swipeToDelete(tester, 'Colruyt');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(shops.removeCalls, isEmpty);
    });
  });
}
