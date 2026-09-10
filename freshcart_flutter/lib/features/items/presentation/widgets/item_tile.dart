import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// One row of a shopping list.
class ItemTile extends StatefulWidget {
  /// Creates a tile for [item].
  const ItemTile({
    required this.item,
    required this.checkedByName,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
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

  /// Called when the row is swiped away.
  final VoidCallback onDelete;

  /// Translations for the active locale.
  final Translations t;

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile>
    with SingleTickerProviderStateMixin {
  /// Drives the strike-through wipe and the fade to 45%.
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: widget.item.isChecked ? 1 : 0,
  );

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
    super.dispose();
  }

  void _handleToggle() {
    // Haptics fire on commitment, and on check only -- confirming a tick is
    // useful, confirming an undo is noise.
    if (!widget.item.isChecked) unawaited(HapticFeedback.lightImpact());
    widget.onToggle();
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
      background: ColoredBox(
        color: theme.colorScheme.errorContainer,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
      onDismissed: (_) => widget.onDelete(),
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
          onDelete: () {},
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
          onDelete: () {},
          t: t,
        ),
        ItemTile(
          item: item(id: 'c', name: 'Milk', quantity: 2, isChecked: true),
          checkedByName: 'Sam',
          onToggle: () {},
          onEdit: () {},
          onDelete: () {},
          t: t,
        ),
      ],
    ),
  );
}
