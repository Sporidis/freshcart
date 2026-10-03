import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);
  final t = translationsFor(AppLocale.en);
  final colruyt = buildShop(name: 'Colruyt', color: '#E8791A');
  final aldi = buildShop(
    id: '00000000-0000-4000-8000-0000000000c2',
    name: 'Aldi',
    color: '#2456A6',
  );

  Future<void> pumpSheet(WidgetTester tester, ItemSheet sheet) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: sheet)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the button names where the product is going', (tester) async {
    await pumpSheet(
      tester,
      ItemSheet.add(
        initialName: 'Pasta',
        listName: 'Groceries',
        shops: [colruyt, aldi],
        t: t,
      ),
    );

    expect(find.text('Add to list'), findsOneWidget);

    await tester.tap(find.text('Aldi'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Aldi'), findsOneWidget);
  });

  testWidgets(
    'adding from a shop tab offers no "No shop": you are adding to that shop',
    (tester) async {
      await pumpSheet(
        tester,
        ItemSheet.add(
          initialName: 'Pasta',
          listName: 'Groceries',
          shops: [colruyt, aldi],
          t: t,
          initialShopId: colruyt.id,
        ),
      );

      expect(find.text('No shop'), findsNothing);
      expect(find.text('Add to Colruyt'), findsOneWidget);
    },
  );

  testWidgets('the note hides behind Add note until asked for', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      ItemSheet.add(
        initialName: 'Pasta',
        listName: 'Groceries',
        shops: const [],
        t: t,
      ),
    );

    expect(find.byType(TextField), findsOneWidget, reason: 'just the name');

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
  });
}
