import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What [ItemSheet] hands back: either the details to save, or a request to
/// remove the item entirely. A sealed class rather than a nullable-field
/// record, so the caller's own `switch` has to handle both without a third,
/// silently-possible "neither" shape to forget.
sealed class ItemSheetOutcome {}

/// Save with these details -- creating a new item, or updating an existing
/// one, depending on which [ItemSheet] was opened.
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

/// Remove the item being edited. Only reachable when [ItemSheet.item] is
/// set -- there is nothing to remove while adding.
class ItemSheetRemove extends ItemSheetOutcome {}

/// One sheet for both adding a new item and editing an existing one --
/// "the same sheet, titled Edit product and with a Remove action, is what a
/// row tap opens later; one component, two entry points" (§09). Previously
/// two separate widgets (`AddItemSheet`, and an `ItemEditorDialog` that
/// could not even change an item's shop); unified because they already did
/// almost the same thing, and a second field added to one would otherwise
/// need remembering to add to the other too.
class ItemSheet extends StatefulWidget {
  /// Creates the sheet for adding a new item, pre-filled with [initialName]
  /// (already typed in [QuickAddBar]) and, if a shop tab was active,
  /// [initialShopId].
  const ItemSheet.add({
    required String initialName,
    required this.shops,
    required this.t,
    ShopId? initialShopId,
    super.key,
  }) : item = null,
       _initialName = initialName,
       _initialShopId = initialShopId;

  /// Creates the sheet for editing [item], pre-filled from it.
  const ItemSheet.edit({
    required ShoppingItem this.item,
    required this.shops,
    required this.t,
    super.key,
  }) : _initialName = null,
       _initialShopId = null;

  /// Null while adding; the item being edited otherwise. Also what decides
  /// the sheet's mode -- there is no separate boolean to keep in step with it.
  final ShoppingItem? item;

  /// The shops on this list, to tag the item to one of them. Empty hides the
  /// picker entirely -- nothing to choose from is not worth a section.
  final List<Shop> shops;

  /// Translations for the active locale.
  final Translations t;

  final String? _initialName;
  final ShopId? _initialShopId;

  /// Whether this is the edit form -- [item] is set.
  bool get isEditing => item != null;

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<ItemSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item?.name ?? widget._initialName ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.item?.note?.text ?? '',
  );
  late int _quantity = widget.item?.quantity ?? 1;
  late ShopId? _shopId = _initialShopId();

  /// The item's own shop when editing; the active shop tab when adding --
  /// but only if it is actually one of [ItemSheet.shops] either way. A
  /// stale filter or a shop deleted out from under an open sheet should
  /// fall back to "no shop" rather than tag to something with no chip.
  ShopId? _initialShopId() {
    final id = widget.item?.shopId ?? widget._initialShopId;
    if (id == null) return null;
    return widget.shops.any((shop) => shop.id == id) ? id : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final note = _note.text.trim();
    Navigator.of(context).pop<ItemSheetOutcome>(
      ItemSheetSave(
        name: name,
        quantity: _quantity,
        shopId: _shopId,
        noteText: note.isEmpty ? null : note,
      ),
    );
  }

  void _remove() =>
      Navigator.of(context).pop<ItemSheetOutcome>(ItemSheetRemove());

  /// A field's caption, sitting above it as plain text -- the design's own
  /// rule, stated in `app_theme.dart`'s `inputDecorationTheme` comment:
  /// labels never float inside the field via `labelText`.
  Widget _fieldLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.t;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        8,
        AppSpacing.sheetH,
        MediaQuery.viewInsetsOf(context).bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing
                ? t.items.editProductTitle
                : t.items.newProductTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.gap),
          _fieldLabel(context, t.items.nameLabel),
          TextField(
            controller: _name,
            autofocus: !widget.isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: t.items.namePlaceholder),
            onSubmitted: (_) => _save(),
          ),
          // Shop before Amount, matching Flow 09 frame 6 / Flow 11's own
          // field order -- not the arbitrary order this sheet had before.
          if (widget.shops.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gap),
            _fieldLabel(context, t.items.shopLabel),
            ShopPicker(
              shops: widget.shops,
              t: t,
              isSelected: (id) => id == _shopId,
              onSelected: (id) => setState(() => _shopId = id),
            ),
          ],
          const SizedBox(height: AppSpacing.gap),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.gap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.items.amountLabel, style: theme.textTheme.bodyLarge),
                  QuantityStepper(
                    quantity: _quantity,
                    // Quantity never drops below one: AddItem rejects zero,
                    // and a zero-quantity row on a shopping list means
                    // nothing.
                    onDecrement: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    onIncrement: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          _fieldLabel(context, t.items.notePlaceholder),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.gap),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(widget.isEditing ? t.common.save : t.items.add),
            ),
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _remove,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                ),
                child: Text(t.items.remove),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
