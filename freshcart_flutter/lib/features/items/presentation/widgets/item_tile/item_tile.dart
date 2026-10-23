import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/checked_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// One item row on the list.
///
/// - Tap: check or uncheck it (with a strike-through animation).
/// - Hold: the row lifts up and a menu appears (edit, delete, select,
///   rearrange).
/// - In select mode, tap selects the row instead.
///
/// This widget only handles the gestures and animations. Saving is done by
/// the parent, through the callbacks.
class ItemTile extends StatefulWidget {
  /// Creates the row for [item].
  const ItemTile({
    required this.item,
    required this.shopColor,
    required this.onToggle,
    this.shopName,
    this.inDone = false,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.t,
    this.selected = false,
    this.selectionMode = false,
    this.onSelectionToggle,
    this.onSelectMore,
    this.onRearrange,
    this.shops = const [],
    this.onMove,
    this.dragHandle,
    this.checkedByMember,
    this.highlightQuery,
    super.key,
  });

  /// The item to show.
  final ShoppingItem item;

  /// The colour of the item's shop (the check fills with it), or null if
  /// it has no shop.
  final Color? shopColor;

  /// The shop's name for the subtitle. Only on the All tab; see
  /// [ItemRowContent.shopName].
  final String? shopName;

  /// Whether the row sits in the Done section (faded). A row checked a
  /// moment ago is still settling in the open section and isn't faded yet.
  final bool inDone;

  /// Translations (for the menu labels and "Checked off by {name}").
  final Translations t;

  /// Called after the row already shows the new checked state. The parent
  /// saves it (and undoes it if saving fails).
  final VoidCallback onToggle;

  /// Called from the hold menu's "Edit details" and "Move to shop". Both
  /// open the same edit sheet (the shop is a field in it).
  final VoidCallback onEdit;

  /// Called from the hold menu's "Delete", after the menu has closed.
  final VoidCallback onDelete;

  /// Called with the new quantity (not +1/-1) when the stepper is tapped.
  final ValueChanged<int> onQuantityChanged;

  /// Whether this row is selected. Only matters in select mode. Uses the
  /// same circle as "checked" (selected rows are never checked, because you
  /// can only select open items).
  final bool selected;

  /// Whether the list is in select mode. Then a tap selects the row instead
  /// of checking it, and holding doesn't open the menu.
  final bool selectionMode;

  /// Selects or unselects this row. Only used in select mode.
  final VoidCallback? onSelectionToggle;

  /// Called from the hold menu's "Select more…". Starts select mode with
  /// this row selected. If null, the option just closes the menu.
  final VoidCallback? onSelectMore;

  /// Called from the hold menu's "Rearrange list". Puts the list in
  /// rearrange mode. If null (for checked rows), the option just closes
  /// the menu.
  final VoidCallback? onRearrange;

  /// The list's shops, for the hold menu's inline Move.
  final List<Shop> shops;

  /// Moves the item to a shop (null = no shop), from the hold menu.
  final ValueChanged<ShopId?>? onMove;

  /// The drag handle shown at the start of the row in rearrange mode.
  /// Given by the parent list (usually wrapped in a
  /// `ReorderableDragStartListener`). Null outside rearrange mode.
  final Widget? dragHandle;

  /// Who checked this item off, shown under the name. If the item has a
  /// note, the note is shown instead.
  final ListMember? checkedByMember;

  /// The search text, to make matching letters bold. Null outside search.
  final String? highlightQuery;

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> with TickerProviderStateMixin {
  static const _longPressThreshold = Duration(milliseconds: 450);

  /// How long the menu's stepper waits after the last tap before saving.
  /// "+ + +" becomes one save of 4, not three racing saves: the server
  /// rejects an edit whose `updatedAt` isn't the one it holds, and the
  /// second tap would otherwise send the first tap's optimistic copy.
  static const _quantityCommitDelay = Duration(milliseconds: 400);

  /// The hold menu's arrival and departure (see [ItemMenuMotion]).
  late final AnimationController _menuOpen;
  late final AnimationController _menuClose;
  late final AnimationController _strikeController;
  late final AnimationController _checkFillController;
  late final AnimationController _pressScaleController;
  OverlayEntry? _menuEntry;
  Timer? _longPressTimer;
  Timer? _pressTellTimer;
  late bool _isChecked;
  bool _isMenuOpen = false;

  /// The quantity the menu's stepper shows but hasn't saved yet.
  int? _pendingQuantity;
  Timer? _quantityCommit;

  /// [ItemTile.item] with the stepper's unsaved quantity, for the menu.
  ShoppingItem get _menuItem {
    final pending = _pendingQuantity;
    return pending == null
        ? widget.item
        : widget.item.copyWith(quantity: pending);
  }

  @override
  void initState() {
    super.initState();
    _isChecked = widget.item.isChecked;
    _menuOpen = AnimationController(
      vsync: this,
      duration: ItemMenuMotion.openDuration,
    );
    _menuClose = AnimationController(
      vsync: this,
      duration: ItemMenuMotion.closeDuration,
    );
    _strikeController = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      value: _isChecked ? 1 : 0,
    );
    // The check circle filling in (340 ms). The bounce curve is added where
    // it's used, because it only applies when checking, not unchecking.
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
    // Remove the menu directly, not through `_closeMenu()`. That one
    // animates and calls `setState`, neither allowed inside `dispose()`
    // (even though `mounted` is still true here). Removed before its
    // controllers go, so nothing listens to a disposed controller.
    _menuEntry?.remove();
    _menuEntry = null;
    _menuOpen.dispose();
    _menuClose.dispose();
    _strikeController.dispose();
    _checkFillController.dispose();
    _pressScaleController.dispose();
    _longPressTimer?.cancel();
    _pressTellTimer?.cancel();
    _commitQuantity();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the checked state changed from outside (someone else checked it,
    // or saving failed and it was undone), update our local copy.
    if (widget.item.isChecked != oldWidget.item.isChecked &&
        widget.item.isChecked != _isChecked) {
      _animateChecked(widget.item.isChecked);
    }
    // Selecting uses the same circle animation as checking. That's fine:
    // only open items can be selected, so a row is never both.
    if (widget.selectionMode && widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _checkFillController.forward();
      } else {
        _checkFillController.reverse();
      }
    }
    if (widget.item != oldWidget.item) {
      // The saved item has caught up with (or, after a failed save, undone)
      // the stepper. Show the item itself again.
      if (_quantityCommit == null) _pendingQuantity = null;
      // The menu lives in an overlay, outside this row's subtree, so it
      // doesn't rebuild with it. Without this it keeps the item from when
      // it opened. After the frame, because marking another subtree dirty
      // during build isn't allowed.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _menuEntry?.markNeedsBuild(),
      );
    }
  }

  /// The menu's stepper: show the new quantity now, save it once the taps
  /// stop.
  void _onMenuQuantity(int quantity) {
    _pendingQuantity = quantity;
    _menuEntry?.markNeedsBuild();
    _quantityCommit?.cancel();
    _quantityCommit = Timer(_quantityCommitDelay, _commitQuantity);
  }

  /// Saves the stepper's quantity now, if it differs from the item's.
  void _commitQuantity() {
    _quantityCommit?.cancel();
    _quantityCommit = null;
    final pending = _pendingQuantity;
    if (pending == null || pending == widget.item.quantity) {
      _pendingQuantity = null;
      return;
    }
    widget.onQuantityChanged(pending);
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

  // ── Press and hold ──────────────────────────────────────────────────────
  // A tap checks the row. Holding longer than [_longPressThreshold] opens
  // the menu instead. Done with timers (not a long-press recognizer), so
  // tap and hold are one gesture and we can show a hint halfway.

  void _onPressStart() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressThreshold, () {
      _pressTellTimer?.cancel();
      _pressScaleController.animateTo(1, curve: AppMotion.pop);
      _openMenu();
    });
    // After 300 ms of holding, the row shrinks a little as a hint to keep
    // holding.
    // Not under reduced motion: the hint is a scale, and the menu opening
    // is hint enough.
    _pressTellTimer?.cancel();
    if (AppMotion.reduced(context)) return;
    _pressTellTimer = Timer(const Duration(milliseconds: 300), () {
      _pressScaleController.animateTo(AppMotion.pressScale);
    });
  }

  void _onPressCancel() {
    _longPressTimer?.cancel();
    _pressTellTimer?.cancel();
    _pressScaleController.animateTo(1, curve: AppMotion.pop);
  }

  void _onPressEnd() {
    _pressTellTimer?.cancel();
    _pressScaleController.animateTo(1, curve: AppMotion.pop);
    // If the hold timer is still running, the finger was lifted early: it's
    // a tap, so check the item. If the timer already fired, the menu is
    // open and the tap is ignored here.
    if (_longPressTimer?.isActive ?? false) {
      _longPressTimer!.cancel();
      _setChecked(!_isChecked);
    }
  }

  // ── Menu overlay ────────────────────────────────────────────────────────

  void _openMenu() {
    if (_menuEntry != null) return;
    final reduced = AppMotion.reduced(context);
    _menuOpen.duration = reduced
        ? AppMotion.micro
        : ItemMenuMotion.openDuration;
    _menuClose.value = 0;
    unawaited(_menuOpen.forward(from: 0));
    final motion = ItemMenuMotion(
      open: _menuOpen,
      close: _menuClose,
      reduced: reduced,
    );

    _menuEntry = OverlayEntry(
      // Careful: `context` below must be the row's context, not the
      // overlay's. That's why the builder's parameter isn't called
      // `context`; it would hide the row's one.
      builder: (_) {
        final renderBox = context.findRenderObject() as RenderBox;
        final globalPosition = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        return AnimatedBuilder(
          animation: Listenable.merge([_menuOpen, _menuClose]),
          builder: (context, child) => ItemMenu(
            globalPosition: globalPosition,
            size: size,
            motion: motion,
            item: _menuItem,
            isChecked: _isChecked,
            onChanged: _setChecked,
            onClose: _closeMenu,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onSelectMore: widget.onSelectMore,
            shops: widget.shops,
            onMove: widget.onMove,
            onRearrange: widget.onRearrange,
            onQuantityChanged: _onMenuQuantity,
            strikeProgress: _strikeController,
            fillProgress: _checkFillController,
            isMenuClosed: !motion.showsStepper,
            shopColor: widget.shopColor,
            shopName: widget.shopName,
            t: widget.t,
            checkedByMember: widget.checkedByMember,
          ),
        );
      },
    );
    Overlay.of(context).insert(_menuEntry!);
    setState(() => _isMenuOpen = true);
  }

  /// Closes the menu: v3 fades it out over 160ms, then it's removed. The
  /// row underneath shows again straight away, so the card fades out over
  /// it. Whatever the user picked runs right away, not after the fade.
  void _closeMenu() {
    final entry = _menuEntry;
    if (entry == null || _menuClose.isAnimating) return;
    // Don't make the user wait out the delay: closing saves.
    _commitQuantity();
    _pressScaleController.animateTo(1, curve: AppMotion.pop);
    if (mounted) setState(() => _isMenuOpen = false);

    void remove() {
      if (_menuEntry != entry) return;
      entry.remove();
      _menuEntry = null;
    }

    if (!mounted || AppMotion.reduced(context)) {
      remove();
      return;
    }
    unawaited(_menuClose.forward(from: 0).whenComplete(remove));
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
          shopName: widget.shopName,
          isSelecting: true,
          onQuantityChanged: widget.onQuantityChanged,
          t: widget.t,
          checkedByMember: widget.checkedByMember,
          highlightQuery: widget.highlightQuery,
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onPressStart(),
      onTapCancel: _onPressCancel,
      onTapUp: (_) => _onPressEnd(),
      // While the menu is open, the row is only hidden, not removed. So the
      // list doesn't jump or lose its scroll position.
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
              shopName: widget.shopName,
              faded: widget.inDone,
              onQuantityChanged: widget.onQuantityChanged,
              dragHandle: widget.dragHandle,
              t: widget.t,
              checkedByMember: widget.checkedByMember,
              highlightQuery: widget.highlightQuery,
            ),
          ),
        ),
      ),
    );
  }
}
