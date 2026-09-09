import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// One row of a shopping list.
class ItemTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _subtitle();

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
      onDismissed: (_) => onDelete(),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (_) => onToggle(),
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
              child: Text(
                item.name,
                style: item.isChecked
                    // Struck through rather than hidden: a shopper needs to see
                    // what is already in the trolley.
                    ? theme.textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : theme.textTheme.bodyLarge,
              ),
            ),
            if (item.hasNote)
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        secondary: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: t.common.save,
        ),
      ),
    );
  }

  String? _subtitle() {
    final note = item.note;
    if (note != null && !note.isEmpty) return note.text;
    if (item.isChecked && checkedByName != null) {
      return t.items.checkedBy(name: checkedByName!);
    }
    return null;
  }
}
