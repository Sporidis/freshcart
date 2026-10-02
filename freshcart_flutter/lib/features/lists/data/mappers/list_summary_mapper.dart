import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.ListSummary] into our domain [ListSummary].
///
/// Only one direction: summaries are calculated by the server and never
/// sent back.
extension ListSummaryDtoX on dto.ListSummary {
  /// Converts to the domain [ListSummary].
  ListSummary toDomain() => ListSummary(
    listId: ListId(listId.uuid),
    total: total,
    checkedCount: checkedCount,
  );
}
