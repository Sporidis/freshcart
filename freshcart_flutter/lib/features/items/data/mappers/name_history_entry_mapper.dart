import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.ItemNameHistory] wire object to the domain entity.
///
/// One-way only: nothing in the app writes a [NameHistoryEntry] back --
/// history rows are written server-side, as a side effect of `ItemService.add`
/// (decisions #64), not through this repository.
extension ItemNameHistoryDtoX on dto.ItemNameHistory {
  /// Converts to the domain [NameHistoryEntry].
  NameHistoryEntry toDomain() =>
      NameHistoryEntry(name: name, lastUsedAt: lastUsedAt);
}
