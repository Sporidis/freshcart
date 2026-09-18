import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/session/session_resume_observer.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';

/// Counts how many times each provider's build function runs, standing in
/// for the real repository stack -- this test is about SessionResumeObserver
/// invalidating the right providers on resume, not about what the providers
/// fetch. The real fetch behaviour has its own tests.
class _BuildCounts {
  int lists = 0;
  int listById = 0;
  int items = 0;
}

class _FakeListsController extends ListsController {
  _FakeListsController(this.counts);
  final _BuildCounts counts;

  @override
  Future<Result<List<ShoppingList>>> build() async {
    counts.lists++;
    return const Ok([]);
  }
}

class _FakeItemsController extends ItemsController {
  _FakeItemsController(this.counts);
  final _BuildCounts counts;

  @override
  Future<Result<List<ShoppingItem>>> build(ListId listId) async {
    counts.items++;
    return const Ok([]);
  }
}

void main() {
  final listId = ListId('00000000-0000-4000-8000-000000000001');

  ({ProviderContainer container, _BuildCounts counts}) buildContainer() {
    final counts = _BuildCounts();
    final container = ProviderContainer(
      overrides: [
        listsControllerProvider.overrideWith(
          () => _FakeListsController(counts),
        ),
        listByIdProvider.overrideWith((ref, id) {
          counts.listById++;
          return const Stream.empty();
        }),
        itemsControllerProvider.overrideWith2(
          (listId) => _FakeItemsController(counts),
        ),
      ],
    );
    return (container: container, counts: counts);
  }

  Future<void> pumpObserver(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SessionResumeObserver(child: SizedBox.shrink()),
      ),
    );
  }

  testWidgets(
    'resuming from the background reopens the lists and realtime providers',
    (tester) async {
      final (:container, :counts) = buildContainer();
      addTearDown(container.dispose);

      // Keep each provider alive (autoDispose would tear it down the instant
      // nothing is listening, which is exactly the state this fix has to
      // recover from, not the state a test starts in).
      container
        ..listen(listsControllerProvider, (_, _) {})
        ..listen(listByIdProvider(listId), (_, _) {})
        ..listen(itemsControllerProvider(listId), (_, _) {});

      await pumpObserver(tester, container);
      await tester.pump();

      expect(counts.lists, 1);
      expect(counts.listById, 1);
      expect(counts.items, 1);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      // One fresh build each -- the same "brand-new open" recovery the
      // manual Retry button already performs, now automatic.
      expect(counts.lists, 2);
      expect(counts.listById, 2);
      expect(counts.items, 2);
    },
  );

  testWidgets('other lifecycle states do not reopen anything', (
    tester,
  ) async {
    final (:container, :counts) = buildContainer();
    addTearDown(container.dispose);
    container
      ..listen(listsControllerProvider, (_, _) {})
      ..listen(listByIdProvider(listId), (_, _) {})
      ..listen(itemsControllerProvider(listId), (_, _) {});

    await pumpObserver(tester, container);
    await tester.pump();

    final listsBefore = counts.lists;
    final listByIdBefore = counts.listById;
    final itemsBefore = counts.items;

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
      AppLifecycleState.hidden,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }

    expect(counts.lists, listsBefore);
    expect(counts.listById, listByIdBefore);
    expect(counts.items, itemsBefore);
  });
}
