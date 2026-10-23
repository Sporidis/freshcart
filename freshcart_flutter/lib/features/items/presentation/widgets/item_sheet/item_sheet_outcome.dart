import 'package:freshcart_domain/freshcart_domain.dart';

/// What [ItemSheet] returns: either "save these details" or "delete the
/// item". A sealed class, so the caller's `switch` must handle both cases.
sealed class ItemSheetOutcome {}

/// Save these details (a new item, or changes to an existing one).
class ItemSheetSave extends ItemSheetOutcome {
  /// Creates the outcome.
  ItemSheetSave({
    required this.name,
    required this.quantity,
    this.shopId,
    this.noteText,
  });

  final String name;
  final int quantity;
  final ShopId? shopId;
  final String? noteText;
}

/// Delete the item. Only possible when editing (not when adding).
class ItemSheetRemove extends ItemSheetOutcome {}
