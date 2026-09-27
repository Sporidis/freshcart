import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/checked_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

class ItemTile extends StatefulWidget {
  const ItemTile({
    required this.item,
    required this.shopColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.t,
    this.selected = false,
    this.selectionMode = false,
    this.onSelectionToggle,
    this.onSelectMore,
    this.onRearrange,
    this.dragHandle,
    this.checkedByMember,
    super.key,
  });

  final ShoppingItem item;
  final Color? shopColor;

  /// Translations for the active locale -- the menu's own option labels and
  /// the "Checked off by {name}" caption both need it.
  final Translations t;

  /// Called once local state has already flipped optimistically -- the
  /// caller owns actually persisting it (and rolling back on failure).
  final VoidCallback onToggle;

  /// Called from the hold-menu's "Edit details" and "Move to shop" rows --
  /// both open the same edit flow, since neither this design nor the app has
  /// a separate move-to-shop-only flow (item_tile.dart doesn't either; shop
  /// is just a field on the same edit sheet).
  final VoidCallback onEdit;

  /// Called from the hold-menu's "Delete" row, after the menu has already
  /// closed.
  final VoidCallback onDelete;

  /// Called with the new absolute quantity from the stepper's +/- buttons --
  /// not a delta, so the caller (which already owns the real edit flow via
  /// [onEdit]) can just fold it into the same `ItemsController.edit` call
  /// without recomputing anything from a +1/-1 signal.
  final ValueChanged<int> onQuantityChanged;

  /// Whether this row is part of the current multi-selection. Only
  /// meaningful while [selectionMode] is true -- reuses the same circle
  /// `CheckCircle` otherwise shows the checked state in, since a
  /// selectable row is never simultaneously a checked one (selection only
  /// ever applies to the open section -- see `ItemsSection`).
  final bool selected;

  /// Whether the list is in multi-select right now. While true, this row's
  /// own hold-to-menu gesture is suppressed and a plain tap toggles
  /// [onSelectionToggle] instead of the checked state -- selection has its
  /// own contextual bar for bulk actions, so there is nothing this row's own
  /// menu would add.
  final bool selectionMode;

  /// Toggles this row's membership in the selection. Only used while
  /// [selectionMode] is true.
  final VoidCallback? onSelectionToggle;

  /// Called from the hold-menu's "Select more…" row, after the menu has
  /// already closed -- seeds the selection with this row, which is how
  /// selection mode is entered (there is no long-press for it here; that
  /// gesture already means "open the menu"). Null leaves the row that
  /// option closes the menu with no further effect, same as before this was
  /// wired up.
  final VoidCallback? onSelectMore;

  /// Called from the hold-menu's "Rearrange list" row, after the menu has
  /// already closed -- puts the whole list into rearrange mode, which is
  /// where [dragHandle] comes from. Null (the default) leaves that option
  /// closing the menu with no further effect -- the same behavior before
  /// reorder existed at all, and what a caller with nothing to reorder into
  /// (the "All" tab, say) should still pass.
  final VoidCallback? onRearrange;

  /// The drag handle to show at the row's leading edge while the list is in
  /// rearrange mode -- typically a
  /// `ReorderableDragStartListener`-wrapped icon, supplied by whoever owns
  /// the `ReorderableListView` this row sits in. Null (the default, and
  /// always true outside rearrange mode) renders no handle at all; this
  /// widget stays dumb about *how* dragging actually works, the same
  /// division of responsibility it already has for everything else.
  final Widget? dragHandle;

  /// Who checked this item off, if anyone -- shown as a caption below the
  /// name once checked, the same priority `item_tile.dart`'s own
  /// `_buildSubtitle` gives: a note always wins over "checked by", since
  /// the note is the shopper's own instruction and stays visible even after
  /// the item is in the trolley.
  final ListMember? checkedByMember;

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> with TickerProviderStateMixin {
  static const _longPressThreshold = Duration(milliseconds: 450);
  static const _liftDuration = Duration(milliseconds: 300);
  static const _liftScale = 1.015;
  // Partway through the lift, not a fixed "menu is open" constant — this is
  // what actually gives the quantity's AnimatedSwitcher a before/after state
  // to transition between, instead of being born already switched.
  static const _quantityMorphThreshold = 0.5;

  late final AnimationController _animationController;
  late final AnimationController _strikeController;
  late final AnimationController _checkFillController;
  late final AnimationController _pressScaleController;
  OverlayEntry? _menuEntry;
  Timer? _longPressTimer;
  Timer? _pressTellTimer;
  late bool _isChecked;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.item.isChecked;
    _animationController = AnimationController(
      vsync: this,
      duration: _liftDuration,
    );
    _strikeController = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      value: _isChecked ? 1 : 0,
    );
    // 340ms bouncy, matching item_tile.dart's own _checkFill -- the overshoot
    // curve is applied at the widget that reads this, not here, since it
    // only applies going forward (checking), not on the plain reverse.
    _checkFillController = AnimationController(
      vsync: this,
      duration: AppMotion.bouncy,
      value: (_isChecked || widget.selected) ? 1 : 0,
    );
    _pressScaleController = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      value: 1,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _strikeController.dispose();
    _checkFillController.dispose();
    _pressScaleController.dispose();
    _longPressTimer?.cancel();
    _pressTellTimer?.cancel();
    // Not `_closeMenu()`: that calls `setState`, which is illegal here even
    // guarded by `mounted` -- `mounted` is still true for the duration of
    // `dispose()` itself, but the Element is already defunct as part of
    // being torn down. Only the actual cleanup (removing the entry) belongs
    // here; nothing will read `_isMenuOpen` again regardless.
    _menuEntry?.remove();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync if the real checked state changed for a reason other than our
    // own optimistic flip below -- a realtime update from another member, or
    // the controller rolling an optimistic change back after a failure.
    if (widget.item.isChecked != oldWidget.item.isChecked &&
        widget.item.isChecked != _isChecked) {
      _animateChecked(widget.item.isChecked);
    }
    // Reuses the same fill controller _CheckCircle animates checking with --
    // a row in selection mode is never also checked (selection is
    // open-section-only), so the two never compete for it.
    if (widget.selectionMode && widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _checkFillController.forward();
      } else {
        _checkFillController.reverse();
      }
    }
  }

  void _animateChecked(bool checked) {
    setState(() => _isChecked = checked);
    if (checked) {
      _strikeController.forward();
      _checkFillController.forward();
    } else {
      _strikeController.reverse();
      _checkFillController.reverse();
    }
  }

  void _setChecked(bool? value) {
    _animateChecked(value ?? false);
    widget.onToggle();
  }

  void _openMenu() {
    if (_menuEntry != null) return;
    _animationController.forward(from: 0);

    _menuEntry = OverlayEntry(
      // `context` below resolves to this State's own `context` getter, not
      // to this builder's parameter — naming that parameter `context` would
      // shadow it and silently capture the overlay's own (wrong) RenderBox
      // instead of the row's.
      builder: (_) {
        final renderBox = context.findRenderObject() as RenderBox;
        final globalPosition = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final scale = Tween<double>(begin: 1, end: _liftScale).transform(
              Curves.easeOutBack.transform(_animationController.value),
            );
            return ItemMenu(
              globalPosition: globalPosition,
              size: size,
              scale: scale,
              item: widget.item,
              isChecked: _isChecked,
              onChanged: _setChecked,
              onClose: _closeMenu,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              onSelectMore: widget.onSelectMore,
              onRearrange: widget.onRearrange,
              onQuantityChanged: widget.onQuantityChanged,
              strikeProgress: _strikeController,
              fillProgress: _checkFillController,
              isMenuClosed:
                  _animationController.value < _quantityMorphThreshold,
              shopColor: widget.shopColor,
              t: widget.t,
              checkedByMember: widget.checkedByMember,
            );
          },
        );
      },
    );
    Overlay.of(context).insert(_menuEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _closeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
    _pressScaleController.animateTo(1, curve: AppMotion.pop);
    if (mounted) {
      setState(() => _isMenuOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelectionToggle,
        child: ItemRowContent(
          item: widget.item,
          isChecked: widget.selected,
          onChanged: (_) => widget.onSelectionToggle?.call(),
          strikeProgress: _strikeController,
          fillProgress: _checkFillController,
          shopColor: widget.shopColor,
          onQuantityChanged: widget.onQuantityChanged,
          t: widget.t,
          checkedByMember: widget.checkedByMember,
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _longPressTimer?.cancel();
        _longPressTimer = Timer(_longPressThreshold, () {
          _pressTellTimer?.cancel();
          _pressScaleController.animateTo(1, curve: AppMotion.pop);
          _openMenu();
        });
        // The "keep holding" tell: a subtle press-down 300ms into the hold,
        // matching item_tile.dart's own _pressScale/_pressTellTimer split --
        // "has 300ms passed" is a plain wall-clock question independent of
        // whatever the lift animation is doing.
        _pressTellTimer?.cancel();
        _pressTellTimer = Timer(const Duration(milliseconds: 300), () {
          _pressScaleController.animateTo(0.97);
        });
      },
      onTapCancel: () {
        _longPressTimer?.cancel();
        _pressTellTimer?.cancel();
        _pressScaleController.animateTo(1, curve: AppMotion.pop);
      },
      onTapUp: (_) {
        _pressTellTimer?.cancel();
        _pressScaleController.animateTo(1, curve: AppMotion.pop);
        // Still pending means the hold threshold never fired — a real tap,
        // released early — so this is where checking happens. Once it has
        // fired, `_openMenu` already ran and owns this gesture instead.
        if (_longPressTimer?.isActive ?? false) {
          _longPressTimer!.cancel();
          _setChecked(!_isChecked);
        }
      },
      // Kept mounted (not removed from the list) while the menu is open, so
      // the list never reflows or loses scroll position — just hidden.
      child: AnimatedBuilder(
        animation: _pressScaleController,
        builder: (context, child) =>
            Transform.scale(scale: _pressScaleController.value, child: child),
        child: Opacity(
          opacity: _isMenuOpen ? 0 : 1,
          child: CheckedFade(
            progress: _strikeController,
            child: ItemRowContent(
              item: widget.item,
              isChecked: _isChecked,
              onChanged: _setChecked,
              strikeProgress: _strikeController,
              fillProgress: _checkFillController,
              isMenuClosed: !_isMenuOpen,
              shopColor: widget.shopColor,
              onQuantityChanged: widget.onQuantityChanged,
              dragHandle: widget.dragHandle,
              t: widget.t,
              checkedByMember: widget.checkedByMember,
            ),
          ),
        ),
      ),
    );
  }
}

void _noop() {}
void _noopInt(int _) {}

@Preview(group: 'Items', name: 'Item row — list', size: previewPhone)
Widget itemTilePreview() => previewPiece(
  ListView(
    children: [
      ItemTile(
        item: _sampleItem(name: 'Pasta', quantity: 2),
        shopColor: Colors.red,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
      ItemTile(
        item: _sampleItem(
          name: 'Olive oil',
          quantity: 1,
          note: 'Extra virgin, tall bottle',
        ),
        shopColor: Colors.green,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
      ItemTile(
        item: _sampleItem(name: 'Bananas', quantity: 6),
        shopColor: null,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
      ItemTile(
        item: _sampleItem(name: 'Yoghurt', quantity: 4),
        shopColor: Colors.blue,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
      ItemTile(
        item: _sampleItem(
          name: 'Ground beef',
          quantity: 1,
          note: 'Lean, 500g',
        ),
        shopColor: Colors.brown,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
      ItemTile(
        item: _sampleItem(name: 'Chocolate spread', quantity: 1),
        shopColor: Colors.purple,
        onToggle: _noop,
        onEdit: _noop,
        onDelete: _noop,
        onQuantityChanged: _noopInt,
        t: previewTranslations,
      ),
    ],
  ),
  padding: EdgeInsets.zero,
);

ShoppingItem _sampleItem({
  required String name,
  required int quantity,
  String? note,
}) => ShoppingItem(
  id: ItemId('sample_${name.toLowerCase().replaceAll(' ', '_')}'),
  listId: ListId('sample_list'),
  addedBy: UserId('sample_author'),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  name: name,
  quantity: quantity,
  note: note == null
      ? null
      : Note(
          text: note,
          authorId: UserId('sample_author'),
          updatedAt: DateTime.now(),
        ),
);
