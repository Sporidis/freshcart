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

/// One row of a shopping list.
class ItemTile extends StatefulWidget {
  /// Creates a tile for [item].
  const ItemTile({
    required this.item,
    required this.checkedByName,
    required this.onToggle,
    required this.onEdit,
    required this.onSwipeDelete,
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
    if (widget.item.isChecked == oldWidget.item.isChecked) return;
    if (widget.item.isChecked) {
      _strike.forward();
    } else {
      // Unchecking reverses with no overshoot: the intent is unambiguous.
      _strike.reverse();
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    _iconPop.dispose();
    super.dispose();
  }

  void _handleToggle() {
    // Haptics fire on commitment, and on check only -- confirming a tick is
    // useful, confirming an undo is noise.
    if (!widget.item.isChecked) unawaited(HapticFeedback.lightImpact());
    widget.onToggle();
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

    return Dismissible(
      key: ValueKey(item.id.value),
      direction: DismissDirection.endToStart,
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
        animation: _strike,
        builder: (context, child) => Opacity(
          // 45% once checked: present, but plainly already in the trolley.
          opacity: 1 - (_strike.value * 0.55),
          child: child,
        ),
        child: CheckboxListTile(
          value: item.isChecked,
          onChanged: (_) => _handleToggle(),
          controlAffinity: ListTileControlAffinity.leading,
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
          secondary: IconButton(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: widget.t.common.save,
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
          t: t,
        ),
        ItemTile(
          item: item(id: 'c', name: 'Milk', quantity: 2, isChecked: true),
          checkedByName: 'Sam',
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          t: t,
        ),
      ],
    ),
  );
}
