import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/done_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
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
    expect(find.text('Nothing on the list yet'), findsOneWidget);
    expect(find.text('Add your first product below.'), findsOneWidget);
  });

  testWidgets('ticking a box updates the row immediately', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    // Let the 600 ms hold expire so no timer outlives the test.
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

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    // Still holding its place: no divider yet.
    expect(find.byType(DoneDivider), findsNothing);

    await tester.pump(RecentlyChecked.holdDuration);
    await tester.pumpAndSettle();

    expect(find.byType(DoneDivider), findsOneWidget);
    expect(find.text('DONE · 1'), findsOneWidget);
  });

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
      matching: find.byType(CheckboxListTile),
    );
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: milkTile, matching: find.byType(Checkbox)),
          )
          .value,
      isTrue,
    );
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

  testWidgets('a conflict unticks the row and says why', (tester) async {
    items.byListResult = Ok([buildItem(name: 'Milk')]);
    items.saveResult = const Err(Failure.conflict());
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pump(RecentlyChecked.holdDuration);
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
