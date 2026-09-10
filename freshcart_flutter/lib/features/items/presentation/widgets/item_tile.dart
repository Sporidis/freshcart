import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The fraction of the row's width a swipe must cross before it commits to
/// deleting, per the Motion spec (§10).
const _swipeDismissThreshold = 0.4;

/// How far the checkbox slides right to make room for the selection circle,
/// per the Motion spec (§10).
const _checkboxSlide = 8.0;

/// One row of a shopping list.
class ItemTile extends StatefulWidget {
  /// Creates a tile for [item].
  const ItemTile({
    required this.item,
    required this.checkedByName,
    required this.onToggle,
    required this.onEdit,
    required this.onSwipeDelete,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onLongPress,
    required this.index,
    required this.canReorder,
    required this.t,
    super.key,
  });

  /// The item to render.
  final ShoppingItem item;

  /// Who checked it off, already resolved to a display name, or null.
  final String? checkedByName;

  /// Called when the checkbox is tapped.
  final VoidCallback onToggle;

  /// Called when the row is tapped.
  final VoidCallback onEdit;

  /// Called once the swipe commits to deleting the row. Returns the undo
  /// action, which this tile wires into the snackbar it shows.
  final void Function() Function() onSwipeDelete;

  /// Whether the list is in multi-select mode right now.
  final bool selectionMode;

  /// Whether this row is one of the selected ones. Only meaningful while
  /// [selectionMode] is true.
  final bool selected;

  /// Called when a tap should toggle this row's selection rather than its
  /// checked state -- i.e. every tap while [selectionMode] is true.
  final VoidCallback onToggleSelection;

  /// Called once the long-press gesture fires (§10: 500 ms), to enter or add
  /// to the selection.
  final VoidCallback onLongPress;

  /// This row's position within the open, reorderable rows -- for the
  /// selection reveal's stagger (§10: 25 ms per row) and, doubling up, for
  /// [ReorderableDragStartListener] when [canReorder] is true. Rows that
  /// cannot be multi-selected or dragged (the Done section) pass 0.
  final int index;

  /// Whether this row can be dragged to reorder -- true only on the open
  /// rows of a single shop tab (§10: "cross-shop reordering is meaningless"),
  /// and never while [selectionMode] is active, since a drag and a
  /// selection tap would otherwise compete for the same gesture.
  final bool canReorder;

  /// Translations for the active locale.
  final Translations t;

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> with TickerProviderStateMixin {
  /// Drives the strike-through wipe and the fade to 45%.
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: widget.item.isChecked ? 1 : 0,
  );

  /// The row's own scale: the long-press "keep holding" tell (0.97) and its
  /// spring-back, both driven directly rather than through a Tween, since
  /// each has its own target reached from `animateTo` calls at different
  /// moments rather than a single start-to-end run.
  late final AnimationController _pressScale = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: 1,
  );

  /// Set 300 ms into a press; cancelled on release or once the long press
  /// fires. Its own field rather than reusing `_pressScale`'s ticking,
  /// because "has 300 ms passed" is a plain wall-clock question independent
  /// of animation state.
  Timer? _pressTellTimer;

  /// Reveals the selection circle and slides the checkbox aside on entering
  /// selection mode (§10: 240 ms, staggered by [ItemTile.index]); reverses,
  /// unstaggered, on exit. Starts already-settled rather than at 0 so a row
  /// built fresh *while* selection mode is active (scrolled into view, for
  /// instance) does not visibly animate in from nothing.
  late final AnimationController _selectionReveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.selectionMode ? 1 : 0,
  );

  /// How far the current swipe has travelled, 0 to 1 of the row's width.
  /// Feeds [_iconScale]; set from [_handleSwipeUpdate].
  double _swipeProgress = 0;

  /// Plays the delete icon's overshoot-and-settle "pop" the instant a swipe
  /// crosses the dismiss threshold (Motion spec §10).
  late final AnimationController _iconPop = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );
  late final Animation<double> _iconPopOvershoot =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
      ]).animate(CurvedAnimation(parent: _iconPop, curve: Curves.easeOut));

  /// The delete icon's scale: 0.7 while under 30% of the row's width,
  /// ramping linearly to 1 by the time the row is fully swiped (§10), plus
  /// whatever overshoot [_iconPop] is currently playing.
  double get _iconScale {
    const rampStart = 0.3;
    final base = _swipeProgress <= rampStart
        ? 0.7
        : 0.7 +
              0.3 *
                  ((_swipeProgress - rampStart) / (1 - rampStart)).clamp(
                    0.0,
                    1.0,
                  );
    return base + _iconPopOvershoot.value;
  }

  @override
  void didUpdateWidget(ItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isChecked != oldWidget.item.isChecked) {
      if (widget.item.isChecked) {
        _strike.forward();
      } else {
        // Unchecking reverses with no overshoot: the intent is unambiguous.
        _strike.reverse();
      }
    }
    if (widget.selectionMode != oldWidget.selectionMode) {
      if (widget.selectionMode) {
        unawaited(_enterSelectionReveal());
      } else {
        // Exiting is not staggered -- only the entry draws the eye down the
        // list; leaving should read as one dismissal, not a second wave.
        _selectionReveal.reverse();
      }
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    _iconPop.dispose();
    _pressScale.dispose();
    _pressTellTimer?.cancel();
    _selectionReveal.dispose();
    super.dispose();
  }

  void _handleToggle() {
    // Haptics fire on commitment, and on check only -- confirming a tick is
    // useful, confirming an undo is noise.
    if (!widget.item.isChecked) unawaited(HapticFeedback.lightImpact());
    widget.onToggle();
  }

  /// A tap on the row: toggles selection while selection mode is active,
  /// otherwise the usual checked/unchecked toggle.
  void _activateRow() {
    if (widget.selectionMode) {
      unawaited(HapticFeedback.selectionClick());
      widget.onToggleSelection();
    } else {
      _handleToggle();
    }
  }

  Future<void> _enterSelectionReveal() async {
    await Future<void>.delayed(AppMotion.selectionStagger(widget.index));
    if (!mounted) return;
    _selectionReveal.forward();
  }

  /// The finger touched down: starts the clock on the "keep holding" tell.
  void _handlePressStart(PointerDownEvent event) {
    _pressTellTimer?.cancel();
    // 300 ms per §10 -- the row starts easing toward 0.97 from here, so it
    // visibly reaches it right around the 500 ms mark the long press fires.
    _pressTellTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_pressScale.animateTo(0.97, duration: AppMotion.quick));
    });
  }

  /// The finger lifted or the gesture was cancelled before firing: whatever
  /// tell had started springs back.
  void _handlePressEnd(PointerEvent event) {
    _pressTellTimer?.cancel();
    _pressTellTimer = null;
    unawaited(_pressScale.animateTo(1, duration: AppMotion.quick));
  }

  /// The long press committed (§10: 500 ms): confirms with a haptic, snaps
  /// the row back to size, and hands off to the controller.
  void _handleLongPressFire() {
    _pressTellTimer?.cancel();
    _pressTellTimer = null;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_pressScale.animateTo(1, duration: AppMotion.quick));
    widget.onLongPress();
  }

  /// Turns one swipe-drag update into the feedback the Motion spec (§10)
  /// asks for: the delete icon tracking the drag, plus a haptic and an
  /// overshoot "pop" the instant the swipe crosses the dismiss threshold.
  void _handleSwipeUpdate(DismissUpdateDetails details) {
    setState(() => _swipeProgress = details.progress);

    // `details.reached` is true for every frame past the threshold, not just
    // the first -- comparing against `details.previousReached` (rather than,
    // say, the old `_swipeProgress`) is what isolates the single frame the
    // drag actually crossed it, so the haptic and pop fire once per crossing
    // instead of once per frame.
    if (details.reached && !details.previousReached) {
      unawaited(HapticFeedback.mediumImpact());
      _iconPop.forward(from: 0);
    }
  }

  /// Commits the swipe: hands off to the controller, which hides the row and
  /// returns the undo action, then offers that action through a snackbar.
  void _handleDismissed(BuildContext context) {
    final undo = widget.onSwipeDelete();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.t.items.itemRemoved(name: widget.item.name)),
          duration: ItemsController.swipeUndoWindow,
          action: SnackBarAction(label: widget.t.common.undo, onPressed: undo),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final subtitle = _subtitle();
    final muted = theme.colorScheme.onSurfaceVariant;

    return Listener(
      // Raw pointer events, not a second gesture recognizer: a `Listener`
      // sits outside Flutter's gesture arena entirely, so timing the 300 ms
      // tell here cannot compete with -- or steal -- the tap and long-press
      // recognizers the `ListTile` below owns.
      onPointerDown: _handlePressStart,
      onPointerUp: _handlePressEnd,
      onPointerCancel: _handlePressEnd,
      child: Dismissible(
        key: ValueKey(item.id.value),
        // Selection mode owns the gesture instead: a swipe mid-select would
        // be ambiguous between "delete this one" and "drag to select".
        direction: widget.selectionMode
            ? DismissDirection.none
            : DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: _swipeDismissThreshold,
        },
        // 220 ms per the Motion spec (§10) -- the default resize is slower.
        resizeDuration: const Duration(milliseconds: 220),
        onUpdate: _handleSwipeUpdate,
        background: ColoredBox(
          color: AppColors.destructive,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: AnimatedBuilder(
                animation: _iconPop,
                builder: (context, child) =>
                    Transform.scale(scale: _iconScale, child: child),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
            ),
          ),
        ),
        onDismissed: (_) => _handleDismissed(context),
        child: AnimatedBuilder(
          animation: Listenable.merge([_strike, _pressScale]),
          builder: (context, child) => Transform.scale(
            scale: _pressScale.value,
            child: Opacity(
              // 45% once checked: present, but plainly already in the trolley.
              opacity: 1 - (_strike.value * 0.55),
              child: child,
            ),
          ),
          child: ListTile(
            onTap: _activateRow,
            onLongPress: _handleLongPressFire,
            leading: AnimatedBuilder(
              animation: _selectionReveal,
              builder: (context, child) => SizedBox(
                width: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Opacity(
                      opacity: _selectionReveal.value,
                      child: _SelectionCircle(selected: widget.selected),
                    ),
                    Transform.translate(
                      offset: Offset(
                        _checkboxSlide * _selectionReveal.value,
                        0,
                      ),
                      child: Checkbox(
                        value: item.isChecked,
                        onChanged: (_) => _activateRow(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                if (item.quantity > 1) ...[
                  Text(
                    '${item.quantity}×',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _StrikeThrough(
                    progress: _strike,
                    color: muted,
                    child: Text(item.name, style: theme.textTheme.bodyLarge),
                  ),
                ),
                if (item.hasNote)
                  Icon(Icons.sticky_note_2_outlined, size: 18, color: muted),
              ],
            ),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: widget.t.common.save,
                ),
                if (widget.canReorder)
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _subtitle() {
    final note = widget.item.note;
    if (note != null && !note.isEmpty) return note.text;
    if (widget.item.isChecked && widget.checkedByName != null) {
      return widget.t.items.checkedBy(name: widget.checkedByName!);
    }
    return null;
  }
}

/// The circle that stands in for the checkbox once selection mode is active:
/// outlined while unselected, filled with a check once tapped. The 120 ms
/// fill is [AnimatedContainer]'s own transition, driven purely by [selected]
/// changing -- no controller of its own, since nothing here needs staggering
/// or to be read mid-flight the way the reveal does.
class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primary : Colors.transparent,
        border: Border.all(color: selected ? primary : outline, width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// Draws a strike-through across [child] as [progress] runs 0 to 1.
///
/// Painted rather than set as [TextDecoration.lineThrough], which would snap
/// on the frame the value flips. The line wipes left to right instead, which
/// is what makes checking something off feel like an action rather than a
/// state change.
class _StrikeThrough extends StatelessWidget {
  const _StrikeThrough({
    required this.progress,
    required this.color,
    required this.child,
  });

  final Animation<double> progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // With motion reduced there is nothing to wipe, so it is drawn or it is
    // not -- but it is still drawn, because it carries meaning, not polish.
    if (AppMotion.reduced(context)) {
      return CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value > 0 ? 1 : 0,
          color: color,
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value,
          color: color,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress.clamp(0, 1), y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.progress != progress || old.color != color;
}

@Preview(group: 'Items', name: 'Item row · every state', size: Size(393, 340))
Widget itemTilePreview() {
  final t = previewTranslations;
  final now = DateTime.utc(2026, 3, 1, 12);
  ShoppingItem item({
    required String id,
    required String name,
    int quantity = 1,
    bool isChecked = false,
    Note? note,
  }) => ShoppingItem(
    id: ItemId(id),
    listId: ListId('list-1'),
    name: name,
    addedBy: UserId('user-1'),
    createdAt: now,
    updatedAt: now,
    quantity: quantity,
    isChecked: isChecked,
    note: note,
    checkedBy: isChecked ? UserId('user-2') : null,
    checkedAt: isChecked ? now : null,
  );

  return previewPiece(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ItemTile(
          item: item(id: 'a', name: 'Bananas', quantity: 6),
          checkedByName: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
        ItemTile(
          item: item(
            id: 'b',
            name: 'Olive oil',
            note: Note(
              text: 'the green tin',
              authorId: UserId('user-1'),
              updatedAt: now,
            ),
          ),
          checkedByName: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
        ItemTile(
          item: item(id: 'c', name: 'Milk', quantity: 2, isChecked: true),
          checkedByName: 'Sam',
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
      ],
    ),
  );
}
