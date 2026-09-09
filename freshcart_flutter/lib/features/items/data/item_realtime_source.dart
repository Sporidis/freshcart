import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

/// Turns the server's change deltas into a live list of items.
///
/// The wire carries one [dto.ItemChange] per edit, because a list can hold
/// hundreds of items and a change usually touches one. Keeping the merged list
/// is therefore the client's job, and this is where that happens — above the
/// transport, below anything that knows what a widget is.
class ItemRealtimeSource {
  /// Creates the source against a generated Serverpod [dto.Client].
  const ItemRealtimeSource(this._client);

  final dto.Client _client;

  /// Emits the full list of items on [listId], re-emitting on every change.
  ///
  /// Seeds with a normal fetch, then applies deltas. Emits `Err` rather than
  /// closing when the connection drops, so the UI can show a reconnecting state
  /// instead of going blank.
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) async* {
    final listUuid = dto.UuidValue.withValidation(listId.value);

    List<ShoppingItem> current;
    try {
      current = (await _client.item.byList(
        listUuid,
      )).map((i) => i.toDomain()).toList();
    } on Object catch (error) {
      yield Err(mapExceptionToFailure(error));
      return;
    }
    yield Ok(List<ShoppingItem>.unmodifiable(current));

    try {
      await for (final change in _client.item.watchList(listUuid)) {
        current = applyChange(current, change);
        yield Ok(List<ShoppingItem>.unmodifiable(current));
      }
    } on Object catch (error) {
      yield Err(mapExceptionToFailure(error));
    }
  }

  /// Merges one change into [current].
  ///
  /// Exposed for testing: the merge is the part with the rules in it, and it is
  /// worth pinning without a socket. An upsert for an unknown id appends, which
  /// is how another person's new item arrives.
  static List<ShoppingItem> applyChange(
    List<ShoppingItem> current,
    dto.ItemChange change,
  ) {
    final id = ItemId(change.itemId.uuid);
    switch (change.kind) {
      case dto.ItemChangeKind.removed:
        return [
          for (final item in current)
            if (item.id != id) item,
        ];
      case dto.ItemChangeKind.upserted:
        final incoming = change.item?.toDomain();
        // An upsert with no payload is a malformed event; dropping it is safer
        // than guessing, and the next full read will correct the list.
        if (incoming == null) return current;
        final known = current.any((item) => item.id == id);
        if (!known) return [...current, incoming];
        return [
          for (final item in current)
            if (item.id == id) incoming else item,
        ];
    }
  }
}
