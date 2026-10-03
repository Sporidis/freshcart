import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
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
    _noteFocus.dispose();
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

  /// Whether the note field shows. Open from the start only if there's
  /// already a note.
  late bool _noteOpen = _note.text.isNotEmpty;
  final FocusNode _noteFocus = FocusNode();

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
            _CompactStepper(
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
        AnimatedSize(
          duration: AppMotion.durationFor(context, AppMotion.standard),
          curve: AppMotion.emphasized,
          alignment: Alignment.topLeft,
          child: _noteOpen
              ? _NoteField(
                  controller: _note,
                  focusNode: _noteFocus,
                  hint: t.items.noteExample,
                  onSubmitted: _save,
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _noteOpen = true);
                      _noteFocus.requestFocus();
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(t.items.addNote),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: AppTextStyles.bodyStrong.copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
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

/// The sheet's amount: a compact "− 2 +" on the fill colour, the + raised
/// on the surface. Smaller and quieter than the row stepper, because here
/// the amount is usually already right.
class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.decreaseLabel,
    required this.increaseLabel,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      bool raised = false,
    }) => Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? .3 : 1,
          duration: AppMotion.durationFor(context, AppMotion.quick),
          child: Container(
            width: 34,
            height: 34,
            decoration: raised
                ? BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .12),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  )
                : null,
            child: Icon(icon, size: 16, color: scheme.onSurface),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.fill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            icon: Icons.remove,
            label: decreaseLabel,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          button(
            icon: Icons.add,
            label: increaseLabel,
            onTap: onIncrement,
            raised: true,
          ),
        ],
      ),
    );
  }
}

/// The note, once opened: a 50px field on the fill colour with a lines
/// glyph.
class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.fill,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notes_rounded,
            size: 16,
            color: scheme.onSurface.withValues(alpha: .36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
        ],
      ),
    );
  }
}
