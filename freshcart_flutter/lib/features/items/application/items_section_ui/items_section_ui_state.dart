import 'package:freshcart_domain/freshcart_domain.dart';

/// The state of [ItemsSectionUiController]. Just the raw values.
/// `ItemsSectionController` turns them into one `ItemsMode`.
class ItemsSectionUiState {
  const ItemsSectionUiState({
    this.selection = const {},
    this.searchActive = false,
    this.searchQuery = '',
    this.rearranging = false,
    this.doneCollapsed = false,
    this.celebrationDismissed = false,
    this.settling = const {},
    this.lastSettled = const [],
    this.settleCount = 0,
  });

  final Set<ItemId> selection;
  final bool searchActive;
  final String searchQuery;
  final bool rearranging;
  final bool doneCollapsed;
  final bool celebrationDismissed;

  /// Checked, but still held in the open section until the burst settles.
  final Set<ItemId> settling;

  /// The last batch that moved to Done, in tap order.
  final List<ItemId> lastSettled;

  /// How many batches have settled. Goes up by one per batch, so a listener
  /// can tell "a new batch just landed" from any other rebuild.
  final int settleCount;

  ItemsSectionUiState copyWith({
    Set<ItemId>? selection,
    bool? searchActive,
    String? searchQuery,
    bool? rearranging,
    bool? doneCollapsed,
    bool? celebrationDismissed,
    Set<ItemId>? settling,
    List<ItemId>? lastSettled,
    int? settleCount,
  }) => ItemsSectionUiState(
    selection: selection ?? this.selection,
    searchActive: searchActive ?? this.searchActive,
    searchQuery: searchQuery ?? this.searchQuery,
    rearranging: rearranging ?? this.rearranging,
    doneCollapsed: doneCollapsed ?? this.doneCollapsed,
    celebrationDismissed: celebrationDismissed ?? this.celebrationDismissed,
    settling: settling ?? this.settling,
    lastSettled: lastSettled ?? this.lastSettled,
    settleCount: settleCount ?? this.settleCount,
  );
}
