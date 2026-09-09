import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_list_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeItemRepository items;
  final me = UserId('user-1');

  setUp(() => items = FakeItemRepository());

  Future<void> pump(WidgetTester tester) async {
    final list = buildList(members: [buildMember(displayName: 'Nikolaos')]);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(items),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
    await container.read(currentUserIdProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: ItemsSection(list: list)),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('the seeded one'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    await pump(tester);
    expect(find.text('This list is empty.'), findsOneWidget);
  });

  testWidgets('ticking a box updates the row immediately', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('a conflict unticks the row and says why', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    items.saveResult = const Err(Failure.conflict());
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Rolled back...
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    // ...and explained, so the revert does not look like a bug.
    expect(
      find.text('Someone else just changed this. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('adding an item clears the field for the next one', (
    tester,
  ) async {
    items.addResult = Ok(buildItem(name: 'Bread'));
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
      reason: 'adding several things in a row is the common case',
    );
  });

  testWidgets('a rejected add keeps the text for a retry', (tester) async {
    items.addResult = const Err(Failure.network('offline'));
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Bread',
    );
    expect(find.text('Could not reach the server.'), findsOneWidget);
  });
}
