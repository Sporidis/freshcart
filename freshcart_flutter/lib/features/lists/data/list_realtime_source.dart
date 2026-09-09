import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';

/// Turns the server's list broadcasts into a live view of one list.
///
/// Unlike the item source, the wire carries the whole [dto.ShoppingList]
/// on every change rather than a delta: a list is a single row, not a
/// collection that could run to hundreds, so there is nothing to merge. Each
/// event simply replaces what was there.
class ListRealtimeSource {
  /// Creates the source against a generated Serverpod [dto.Client].
  const ListRealtimeSource(this._client);

  final dto.Client _client;

  /// Emits the current state of [listId], re-emitting whenever anyone changes
  /// it — a rename, a join, a member leaving.
  ///
  /// Seeds with a normal fetch, then follows the stream. Emits `Err` rather
  /// than closing when the connection drops, so the UI can show a
  /// reconnecting state instead of going blank.
  Stream<Result<ShoppingList>> watch(ListId listId) async* {
    final listUuid = dto.UuidValue.withValidation(listId.value);

    ShoppingList current;
    try {
      current = (await _client.list.byId(listUuid)).toDomain();
    } on Object catch (error) {
      yield Err(mapExceptionToFailure(error));
      return;
    }
    yield Ok(current);

    try {
      await for (final list in _client.list.watchList(listUuid)) {
        current = list.toDomain();
        yield Ok(current);
      }
    } on Object catch (error) {
      yield Err(mapExceptionToFailure(error));
    }
  }
}
