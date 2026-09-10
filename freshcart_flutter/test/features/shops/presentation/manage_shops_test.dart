import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:freshcart_flutter/features/shops/presentation/manage_shops_screen.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_shop_repository.dart';

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
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
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
    expect(find.byType(EditShopSheet), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('swatch-$orange')));
    await tester.pumpAndSettle();

    final preview = container.read(shopColorPreviewProvider);
    expect(preview?.color.argb, isNot(blue));
    // Nothing committed yet — the preview is not a write.
    expect(shops.savedShops, isEmpty);
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
    expect(container.read(shopColorPreviewProvider), isNotNull);

    // Dismiss without saving.
    Navigator.of(tester.element(find.byType(EditShopSheet))).pop();
    await tester.pumpAndSettle();

    expect(
      container.read(shopColorPreviewProvider),
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
    testWidgets('a shop holding products offers real alternatives', (
      tester,
    ) async {
      shops.byListResult = Ok([
        shop('s1', 'Colruyt', orange),
        shop('s2', 'Albert Heijn', blue),
      ]);
      shops.itemCountResult = 6;

      await pump(tester);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
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
      await tester.tap(find.byIcon(Icons.delete_outline).first);
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
      await tester.tap(find.byIcon(Icons.delete_outline).first);
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
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('This shop has no products.'), findsOneWidget);
      expect(find.text('Delete products too'), findsNothing);
    });

    testWidgets('dismissing the sheet deletes nothing', (tester) async {
      shops.byListResult = Ok([shop('s1', 'Colruyt', orange)]);
      shops.itemCountResult = 6;

      await pump(tester);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(shops.removeCalls, isEmpty);
    });
  });
}
