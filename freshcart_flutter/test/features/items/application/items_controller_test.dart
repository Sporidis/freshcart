import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';

import '../../../fakes/fake_item_repository.dart';

void main() {
  late FakeItemRepository repository;
  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final me = UserId('user-me');

  setUp(() => repository = FakeItemRepository());
  tearDown(() => repository.dispose());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    // Hold a listener so the auto-dispose provider stays alive between reads,
    // as an open screen would. Without it each read rebuilds and the live
    // subscription is torn down in between.
    final subscription = container.listen(
      itemsControllerProvider(listId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container;
  }

  Future<List<ShoppingItem>> itemsOf(ProviderContainer c) async {
    final result = await c.read(itemsControllerProvider(listId).future);
    return (result as Ok<List<ShoppingItem>>).value;
  }

  /// Reads whatever is on screen right now.
  ///
  /// `provider.future` completes once, with the first snapshot, so live updates
  /// have to be observed through the current state instead.
  List<ShoppingItem> currentItems(ProviderContainer c) =>
      (c.read(itemsControllerProvider(listId)).requireValue
              as Ok<List<ShoppingItem>>)
          .value;

  group('toggle', () {
    test('applies the change locally before the server answers', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);
      final pause = Completer<void>();
      repository.savePause = pause.future;

      final container = makeContainer();
      await itemsOf(container);
      // Warm the identity, as app startup does, so the tick is synchronous.
      await container.read(currentUserIdProvider.future);
      final notifier = container.read(itemsControllerProvider(listId).notifier);

      final pending = notifier.toggle(item);

      // Read synchronously: the row must already be ticked on the very next
      // line, while the request is still in flight. That is the whole point.
      final optimistic =
          (container.read(itemsControllerProvider(listId)).requireValue
                  as Ok<List<ShoppingItem>>)
              .value;
      expect(optimistic.single.isChecked, isTrue);
      expect(optimistic.single.checkedBy, me);

      pause.complete();
      expect(await pending, isNull);
    });

    test('reconciles with what the server actually stored', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);
      // The server owns updatedAt — the token the *next* write depends on.
      final serverTruth = item.copyWith(
        isChecked: true,
        checkedBy: me,
        checkedAt: DateTime.utc(2026, 9, 10),
        updatedAt: DateTime.utc(2026, 9, 10),
      );
      repository.saveResult = Ok(serverTruth);

      final container = makeContainer();
      await itemsOf(container);

      await container
          .read(itemsControllerProvider(listId).notifier)
          .toggle(item);

      final after = await itemsOf(container);
      expect(after.single.updatedAt, DateTime.utc(2026, 9, 10));
      expect(after.single.checkedAt, DateTime.utc(2026, 9, 10));
    });

    test('rolls back and reports the failure on a conflict', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);
      repository.saveResult = const Err(Failure.conflict());

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .toggle(item);

      expect(failure, const Failure.conflict());
      final after = await itemsOf(container);
      expect(
        after.single.isChecked,
        isFalse,
        reason: 'a refused write must leave the row as it was',
      );
      expect(after.single.checkedBy, isNull);
    });

    test('returns the failure when the caller cannot be identified', () async {
      repository.byListResult = Ok([buildItem()]);
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWith(
            (ref) async => const Err<UserId>(Failure.unauthorized()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .toggle(buildItem());

      expect(failure, const Failure.unauthorized());
      expect(repository.savedItems, isEmpty);
    });
  });

  group('add', () {
    test('appends the item the server returned', () async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Bread'));

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .add(name: 'Bread');

      expect(failure, isNull);
      expect((await itemsOf(container)).single.name, 'Bread');
    });

    test('reports a validation failure and adds nothing', () async {
      repository.byListResult = const Ok(<ShoppingItem>[]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .add(name: '   ');

      expect(failure, isA<ValidationFailure>());
      expect(await itemsOf(container), isEmpty);
    });

    test(
      'replaces the existing row in place when the server merged into it',
      () async {
        // The server merges a repeat add into an already-open row (see
        // ItemService.add) and returns that row's id, bumped. The controller
        // must not treat this as a fresh insert.
        final existing = buildItem(name: 'Milk');
        repository.byListResult = Ok([existing]);
        repository.addResult = Ok(existing.copyWith(quantity: 3));

        final container = makeContainer();
        await itemsOf(container);

        final failure = await container
            .read(itemsControllerProvider(listId).notifier)
            .add(name: 'Milk');

        expect(failure, isNull);
        final items = await itemsOf(container);
        expect(items, hasLength(1));
        expect(items.single.quantity, 3);
      },
    );
  });

  group('remove', () {
    test('takes the row off screen immediately', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .remove(item);

      expect(failure, isNull);
      expect(await itemsOf(container), isEmpty);
      expect(repository.removedIds.single, item.id);
    });

    test('puts the row back when the server refuses', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);
      repository.removeResult = const Err(Failure.unauthorized());

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .remove(item);

      expect(failure, const Failure.unauthorized());
      expect((await itemsOf(container)).single.id, item.id);
    });
  });

  group('removeSelected', () {
    test('takes exactly the selected rows off screen immediately', () async {
      final milk = buildItem(id: 'a', name: 'Milk');
      final bread = buildItem(id: 'b', name: 'Bread');
      final eggs = buildItem(id: 'c', name: 'Eggs');
      repository.byListResult = Ok([milk, bread, eggs]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .removeSelected({milk.id, bread.id});

      expect(failure, isNull);
      expect((await itemsOf(container)).single.id, eggs.id);
      expect(
        repository.removeManyCalls.single,
        unorderedEquals([milk.id, bread.id]),
      );
    });

    test('puts every selected row back when the server refuses', () async {
      final milk = buildItem(id: 'a', name: 'Milk');
      final bread = buildItem(id: 'b', name: 'Bread');
      repository.byListResult = Ok([milk, bread]);
      repository.removeManyResult = const Err(Failure.network('offline'));

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .removeSelected({milk.id, bread.id});

      expect(failure, isA<NetworkFailure>());
      expect((await itemsOf(container)).map((i) => i.id), [milk.id, bread.id]);
    });

    test('does nothing given an empty selection', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .removeSelected(const {});

      expect(failure, isNull);
      expect(repository.removeManyCalls, isEmpty);
    });
  });

  group('moveSelected', () {
    final bakery = ShopId('shop-bakery');

    test('re-tags exactly the selected rows immediately', () async {
      final milk = buildItem(id: 'a', name: 'Milk');
      final bread = buildItem(id: 'b', name: 'Bread');
      final eggs = buildItem(id: 'c', name: 'Eggs');
      repository.byListResult = Ok([milk, bread, eggs]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .moveSelected({milk.id, bread.id}, bakery);

      expect(failure, isNull);
      final items = await itemsOf(container);
      expect(
        items.where((i) => i.id == milk.id || i.id == bread.id),
        everyElement(predicate<ShoppingItem>((i) => i.shopId == bakery)),
      );
      expect(
        items.singleWhere((i) => i.id == eggs.id).shopId,
        isNull,
        reason: 'the row not in the selection is untouched',
      );
      expect(
        repository.moveManyCalls.single.ids,
        unorderedEquals([milk.id, bread.id]),
      );
      expect(repository.moveManyCalls.single.shopId, bakery);
    });

    test('a null shopId untags the selected rows', () async {
      final milk = buildItem(id: 'a', name: 'Milk', shopId: bakery);
      repository.byListResult = Ok([milk]);

      final container = makeContainer();
      await itemsOf(container);

      await container
          .read(itemsControllerProvider(listId).notifier)
          .moveSelected({milk.id}, null);

      expect((await itemsOf(container)).single.shopId, isNull);
    });

    test('puts every selected row back on its own shop when the server '
        'refuses', () async {
      final milk = buildItem(id: 'a', name: 'Milk');
      repository.byListResult = Ok([milk]);
      repository.moveManyResult = const Err(Failure.network('offline'));

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .moveSelected({milk.id}, bakery);

      expect(failure, isA<NetworkFailure>());
      expect((await itemsOf(container)).single.shopId, isNull);
    });

    test('does nothing given an empty selection', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .moveSelected(const {}, bakery);

      expect(failure, isNull);
      expect(repository.moveManyCalls, isEmpty);
    });
  });

  group('reorder', () {
    test(
      'applies the new position optimistically before the server answers',
      () async {
        final item = buildItem(
          name: 'Milk',
          updatedAt: DateTime.utc(2026, 1, 1),
        );
        final before = buildItem(id: 'b');
        final after = buildItem(id: 'a');
        repository.byListResult = Ok([item]);
        final pause = Completer<void>();
        repository.savePause = pause.future;

        final container = makeContainer();
        await itemsOf(container);
        final notifier = container.read(
          itemsControllerProvider(listId).notifier,
        );

        final pending = notifier.reorder(item, before: before, after: after);

        final optimistic = currentItems(container).single;
        expect(
          optimistic.sortOrder,
          ShoppingItem.sortOrderBetween(before, after),
        );

        pause.complete();
        expect(await pending, isNull);
      },
    );

    test('rolls the position back on conflict', () async {
      final item = buildItem(name: 'Milk', sortOrder: 5);
      repository.byListResult = Ok([item]);
      repository.saveResult = const Err(Failure.conflict());

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .reorder(item, before: buildItem(id: 'b'), after: null);

      expect(failure, const Failure.conflict());
      expect((await itemsOf(container)).single.sortOrder, 5);
    });
  });

  group('swipeDelete', () {
    test('hides the row immediately, before the undo window ends', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final undo = container
          .read(itemsControllerProvider(listId).notifier)
          .swipeDelete(item);

      expect(currentItems(container), isEmpty);
      expect(
        repository.removedIds,
        isEmpty,
        reason: 'the server call is deferred, not immediate',
      );

      // Undo purely to cancel the pending timer so it does not outlive the
      // test -- this test is about the immediate hide, not the undo path.
      undo();
    });

    test(
      'undo restores the exact row and cancels the pending removal',
      () async {
        final item = buildItem(
          note: Note(
            text: 'the oat one',
            authorId: me,
            updatedAt: DateTime.utc(2026, 9, 9),
          ),
        );
        repository.byListResult = Ok([item]);

        final container = makeContainer();
        await itemsOf(container);

        final undo = container
            .read(itemsControllerProvider(listId).notifier)
            .swipeDelete(item);
        expect(currentItems(container), isEmpty);

        undo();

        expect(currentItems(container).single, item);
        // Cancelling means the server is never told, even once the window
        // that would otherwise have committed the delete has passed.
        await pumpEventQueue();
        expect(repository.removedIds, isEmpty);
      },
    );

    test('undo is idempotent -- a second tap does nothing odd', () async {
      final item = buildItem();
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final undo = container
          .read(itemsControllerProvider(listId).notifier)
          .swipeDelete(item);
      undo();
      undo();

      expect(currentItems(container), [item]);
    });
  });

  group('save', () {
    test('rolls an edit back on conflict', () async {
      final item = buildItem(name: 'Milk');
      repository.byListResult = Ok([item]);
      repository.saveResult = const Err(Failure.conflict());

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .edit(item, name: 'Oat milk', quantity: 1);

      expect(failure, const Failure.conflict());
      expect((await itemsOf(container)).single.name, 'Milk');
    });

    test('applies a valid edit optimistically', () async {
      final item = buildItem(name: 'Milk');
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .edit(item, name: '  Oat milk  ', quantity: 3);

      expect(failure, isNull);
      expect((await itemsOf(container)).single.name, 'Oat milk');
      expect((await itemsOf(container)).single.quantity, 3);
    });

    // The edit path used to reach the repository unvalidated, so an item could
    // be renamed to something AddItem would never have allowed.
    test('rejects a blank name without reaching the repository', () async {
      final item = buildItem(name: 'Milk');
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .edit(item, name: '   ', quantity: 1);

      expect(failure, isA<ValidationFailure>());
      expect(repository.savedItems, isEmpty);
      expect((await itemsOf(container)).single.name, 'Milk');
    });

    test('rejects a quantity below one', () async {
      final item = buildItem(name: 'Milk');
      repository.byListResult = Ok([item]);

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .edit(item, name: 'Milk', quantity: 0);

      expect(failure, isA<ValidationFailure>());
      expect(repository.savedItems, isEmpty);
    });
  });

  group('live updates', () {
    test('another client\'s change arrives without a refresh', () async {
      final mine = buildItem(name: 'Milk');
      repository.byListResult = Ok([mine]);

      final container = makeContainer();
      expect(await itemsOf(container), hasLength(1));

      // Someone else adds bread; the server pushes the merged snapshot.
      repository.live.add(
        Ok([
          mine,
          buildItem(id: '00000000-0000-4000-8000-0000000000b2', name: 'Bread'),
        ]),
      );
      await pumpEventQueue();

      expect(currentItems(container).map((i) => i.name), ['Milk', 'Bread']);
    });

    test('a live event does not clobber an in-flight optimistic edit', () async {
      final milk = buildItem(name: 'Milk');
      final bread = buildItem(
        id: '00000000-0000-4000-8000-0000000000b2',
        name: 'Bread',
      );
      repository.byListResult = Ok([milk, bread]);
      final pause = Completer<void>();
      repository.savePause = pause.future;

      final container = makeContainer();
      await itemsOf(container);
      await container.read(currentUserIdProvider.future);
      final notifier = container.read(itemsControllerProvider(listId).notifier);

      // Tick Milk; the write is still in flight.
      final pending = notifier.toggle(milk);

      // Meanwhile someone else renames Bread. The snapshot they trigger still
      // carries the server's *unticked* copy of Milk.
      repository.live.add(Ok([milk, bread.copyWith(name: 'Sourdough')]));
      await pumpEventQueue();

      final during = currentItems(container);
      expect(
        during.firstWhere((i) => i.id == milk.id).isChecked,
        isTrue,
        reason:
            'the in-flight optimistic tick must survive a third party\'s edit',
      );
      expect(
        during.firstWhere((i) => i.id == bread.id).name,
        'Sourdough',
        reason: 'their change still lands',
      );

      pause.complete();
      expect(await pending, isNull);
    });

    test('a dropped connection surfaces without emptying the list', () async {
      repository.byListResult = Ok([buildItem(name: 'Milk')]);

      final container = makeContainer();
      expect(await itemsOf(container), hasLength(1));

      repository.live.add(const Err(Failure.network('dropped')));
      await pumpEventQueue();

      final state = container
          .read(itemsControllerProvider(listId))
          .requireValue;
      expect(state.failureOrNull, isA<NetworkFailure>());
    });
  });
}
