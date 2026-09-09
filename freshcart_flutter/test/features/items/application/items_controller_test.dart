import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';

import '../../../fakes/fake_item_repository.dart';

void main() {
  late FakeItemRepository repository;
  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final me = UserId('user-me');

  setUp(() => repository = FakeItemRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<ShoppingItem>> itemsOf(ProviderContainer c) async {
    final result = await c.read(itemsControllerProvider(listId).future);
    return (result as Ok<List<ShoppingItem>>).value;
  }

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

  group('save', () {
    test('rolls an edit back on conflict', () async {
      final item = buildItem(name: 'Milk');
      repository.byListResult = Ok([item]);
      repository.saveResult = const Err(Failure.conflict());

      final container = makeContainer();
      await itemsOf(container);

      final failure = await container
          .read(itemsControllerProvider(listId).notifier)
          .save(item.copyWith(name: 'Oat milk'));

      expect(failure, const Failure.conflict());
      expect((await itemsOf(container)).single.name, 'Milk');
    });
  });
}
