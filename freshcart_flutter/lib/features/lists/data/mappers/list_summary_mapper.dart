import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.ListSummary] wire object to the domain entity.
///
/// One-way only: a summary is read-only, computed server-side on demand
/// (`ListService.summaries`) -- nothing in the app ever writes one back.
extension ListSummaryDtoX on dto.ListSummary {
  /// Converts to the domain [ListSummary].
  ListSummary toDomain() => ListSummary(
    listId: ListId(listId.uuid),
    total: total,
    checkedCount: checkedCount,
  );
}
