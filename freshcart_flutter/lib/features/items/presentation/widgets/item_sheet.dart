import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

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

/// The bottom sheet for adding a new item or editing one. When editing,
/// the title is "Edit product" and there's a Remove button.
///
/// One widget for both, so a new field only needs to be added once.
class ItemSheet extends StatefulWidget {
  /// Creates the sheet for adding. Starts with [initialName] (what was
  /// typed in [QuickAddBar]) and [initialShopId] (the selected shop tab).
  const ItemSheet.add({
    required String initialName,
    required this.shops,
    required this.t,
    ShopId? initialShopId,
    super.key,
  }) : item = null,
       _initialName = initialName,
       _initialShopId = initialShopId;

  /// Creates the sheet for editing [item], filled in with its details.
  const ItemSheet.edit({
    required ShoppingItem this.item,
    required this.shops,
    required this.t,
    super.key,
  }) : _initialName = null,
       _initialShopId = null;

  /// The item being edited, or null when adding. This alone decides if the
  /// sheet is in "add" or "edit" mode.
  final ShoppingItem? item;

  /// The shops on this list, to pick from. If empty, the shop picker is
  /// hidden.
  final List<Shop> shops;

  /// Translations for the active locale.
  final Translations t;

  final String? _initialName;
  final ShopId? _initialShopId;

  /// True when editing ([item] isn't null).
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

  /// The shop to start with: the item's shop when editing, the selected tab
  /// when adding. If that shop isn't in [ItemSheet.shops] anymore (for
  /// example it was deleted), it falls back to "no shop".
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

  /// A field's label, as plain text above the field (the design never uses
  /// `labelText` inside the field).
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

    return AppSheetScaffold(
      title: widget.isEditing
          ? t.items.editProductTitle
          : t.items.newProductTitle,
      children: [
        _fieldLabel(context, t.items.nameLabel),
        TextField(
          controller: _name,
          autofocus: !widget.isEditing,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: t.items.namePlaceholder),
          onSubmitted: (_) => _save(),
        ),
        // Shop comes before Amount, as in the design.
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
                  // Minimum is 1. Zero of something makes no sense on a
                  // shopping list (and AddItem rejects it).
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
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _remove,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(t.items.remove),
            ),
          ),
        ],
      ],
    );
  }
}
