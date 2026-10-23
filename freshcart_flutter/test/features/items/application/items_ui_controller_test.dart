import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_ui/items_ui_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_ui/items_ui_state.dart';

void main() {
  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final otherList = ListId('00000000-0000-4000-8000-000000000002');
  final a = ItemId('a');
  final b = ItemId('b');

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  ItemsUiController ui(ListId id) =>
      container.read(itemsUiControllerProvider(id).notifier);
  ItemsUiState read(ListId id) => container.read(itemsUiControllerProvider(id));

  test('selection toggles in and out; emptying it is leaving the mode', () {
    final sub = container.listen(itemsUiControllerProvider(listId), (_, _) {});
    addTearDown(sub.close);

    ui(listId)
      ..toggleSelection(a)
      ..toggleSelection(b)
      ..toggleSelection(a);
    expect(read(listId).selection, {b});

    ui(listId).toggleSelection(b);
    expect(read(listId).selection, isEmpty);
  });

  test('search stays open with an empty query until closed', () {
    final sub = container.listen(itemsUiControllerProvider(listId), (_, _) {});
    addTearDown(sub.close);

    ui(listId).openSearch();
    expect(read(listId).searchActive, isTrue);
    expect(read(listId).searchQuery, '');

    ui(listId).updateQuery('milk');
    ui(listId).closeSearch();
    expect(read(listId).searchActive, isFalse);
    expect(read(listId).searchQuery, '', reason: 'closing forgets the query');
  });

  test('a celebration dismissal is undone by reset', () {
    final sub = container.listen(itemsUiControllerProvider(listId), (_, _) {});
    addTearDown(sub.close);

    ui(listId).dismissCelebration();
    expect(read(listId).celebrationDismissed, isTrue);
    ui(listId).resetCelebration();
    expect(read(listId).celebrationDismissed, isFalse);
  });

  test('state is per list', () {
    final s1 = container.listen(itemsUiControllerProvider(listId), (_, _) {});
    final s2 = container.listen(
      itemsUiControllerProvider(otherList),
      (_, _) {},
    );
    addTearDown(s1.close);
    addTearDown(s2.close);

    ui(listId)
      ..toggleDoneCollapsed()
      ..startRearrange();

    expect(read(listId).doneCollapsed, isTrue);
    expect(read(listId).rearranging, isTrue);
    expect(read(otherList).doneCollapsed, isFalse);
    expect(read(otherList).rearranging, isFalse);
  });
}
