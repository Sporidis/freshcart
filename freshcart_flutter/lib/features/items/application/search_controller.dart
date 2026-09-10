import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

/// Whether search is open on one list, and what has been typed.
///
/// [active] and [query] are tracked separately rather than treating an empty
/// query as "closed" (the way [SelectionController] treats an empty
/// selection): tapping the search icon opens an empty field with results
/// still to be typed, and that state has to persist until the field is
/// explicitly closed, not collapse the instant it renders with nothing in it.
@riverpod
class SearchController extends _$SearchController {
  @override
  ({bool active, String query}) build(ListId listId) =>
      (active: false, query: '');

  /// Opens the search field, per §16: the tab strip slides away and the
  /// header expands into a field, both keyed off [active].
  void open() => state = (active: true, query: state.query);

  /// Updates the typed query. Filtering itself is local and per-keystroke
  /// (§16: "no spinner"), so there is nothing to await here.
  void updateQuery(String query) => state = (active: true, query: query);

  /// Closes search and forgets the query, collapsing everything back.
  void close() => state = (active: false, query: '');
}
