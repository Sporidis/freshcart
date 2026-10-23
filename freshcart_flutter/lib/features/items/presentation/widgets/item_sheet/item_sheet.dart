import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/core/ui/sheet/sheet_close_button.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet/compact_quantity_stepper.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet/item_note_field.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet/item_sheet_outcome.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The bottom sheet for adding a new item or editing one (design v3,
/// "shop-first"): the name and amount share one line because both are
/// nearly done already; the shops are the biggest thing to hit, because
/// where it goes is the one real decision; the note hides behind "Add
/// note" because most items never get one; and the button says where the
/// item is going. When editing there's also a Remove button.
///
/// One widget for both, so a new field only needs to be added once.
class ItemSheet extends StatefulWidget {
  /// Creates the sheet for adding. Starts with [initialName] (what was
  /// typed in [QuickAddBar]) and [initialShopId] (the selected shop tab).
  const ItemSheet.add({
    required String initialName,
    required String this.listName,
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
  }) : listName = null,
       _initialName = null,
       _initialShopId = null;

  /// The item being edited, or null when adding. This alone decides if the
  /// sheet is in "add" or "edit" mode.
  final ShoppingItem? item;

  /// The shops on this list, to pick from. If empty, the shop picker is
  /// hidden.
  final List<Shop> shops;

  /// Translations for the active locale.
  final Translations t;

  /// The list being added to, for the eyebrow. Null when editing.
  final String? listName;

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
    Navigator.of(context).pop<ItemSheetOutcome>(
      ItemSheetSave(
        name: name,
        quantity: _quantity,
        shopId: _shopId,
        noteText: ShoppingItem.cleanNoteText(_note.text),
      ),
    );
  }

  void _remove() =>
      Navigator.of(context).pop<ItemSheetOutcome>(ItemSheetRemove());

  /// Adding from a shop's tab: "No shop" isn't offered (you're adding to
  /// that shop), as in the design.
  bool get _fromShopTab => !widget.isEditing && widget._initialShopId != null;

  @override
  void initState() {
    super.initState();
    // The button dims while the name is empty.
    _name.addListener(() => setState(() {}));
  }

  String _buttonLabel(Translations t) {
    if (widget.isEditing) return t.items.saveChanges;
    final shopId = _shopId;
    if (shopId == null) return t.items.addToList;
    final shop = widget.shops.where((s) => s.id == shopId).firstOrNull;
    return shop == null ? t.items.addToList : t.items.addTo(shop: shop.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = widget.t;
    final eyebrow = AppTextStyles.eyebrow.copyWith(
      fontSize: 11,
      letterSpacing: 1.1,
      color: scheme.onSurface.withValues(alpha: .36),
    );
    final canSave = _name.text.trim().isNotEmpty;
    final listName = widget.listName;

    return AppSheetScaffold(
      children: [
        // The eyebrow takes the title's place; the name below is the title.
        Row(
          children: [
            Expanded(
              child: Text(
                (widget.isEditing || listName == null
                        ? t.items.editProductTitle
                        : t.items.newProductEyebrow(list: listName))
                    .toUpperCase(),
                style: eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SheetCloseButton(),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                autofocus: !widget.isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 28,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: t.items.namePrompt,
                  hintStyle: AppTextStyles.screenTitle.copyWith(
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: scheme.onSurface.withValues(alpha: .3),
                  ),
                  // Borderless and unfilled: a big, quiet line, not a box.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            CompactQuantityStepper(
              quantity: _quantity,
              // Minimum is 1. Zero of something makes no sense on a
              // shopping list (and AddItem rejects it).
              onDecrement: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              onIncrement: () => setState(() => _quantity++),
              decreaseLabel: t.items.decrease,
              increaseLabel: t.items.increase,
            ),
          ],
        ),
        if (widget.shops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(t.items.whereLabel.toUpperCase(), style: eyebrow),
          const SizedBox(height: AppSpacing.sm),
          ShopPicker(
            shops: widget.shops,
            t: t,
            showNoShop: !_fromShopTab,
            isSelected: (id) => id == _shopId,
            onSelected: (id) => setState(() => _shopId = id),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ItemNoteField(
          controller: _note,
          hint: t.items.noteExample,
          addLabel: t.items.addNote,
          onSubmitted: _save,
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedOpacity(
          opacity: canSave ? 1 : .4,
          duration: AppMotion.durationFor(context, AppMotion.quick),
          child: ElevatedButton(
            onPressed: canSave ? _save : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(_buttonLabel(t)),
          ),
        ),
        if (widget.isEditing) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _remove,
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(t.items.remove),
          ),
        ],
      ],
    );
  }
}
