import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.ItemNameHistory] into our [NameHistoryEntry].
///
/// Only one direction: the server writes the history itself when an item
/// is added (decisions.md #64).
extension ItemNameHistoryDtoX on dto.ItemNameHistory {
  /// Converts to the domain [NameHistoryEntry].
  NameHistoryEntry toDomain() =>
      NameHistoryEntry(name: name, lastUsedAt: lastUsedAt);
}
