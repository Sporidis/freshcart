import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The result of editing an item.
typedef ItemEdit = ({String name, int quantity, String? noteText});

/// Edits an item's name, quantity and note.
class ItemEditorDialog extends StatefulWidget {
  /// Creates an editor pre-filled from [item].
  const ItemEditorDialog({required this.item, required this.t, super.key});

  /// The item being edited.
  final ShoppingItem item;

  /// Translations for the active locale.
  final Translations t;

  @override
  State<ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<ItemEditorDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item.name,
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.item.note?.text ?? '',
  );
  late int _quantity = widget.item.quantity;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(t.items.add),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: t.items.namePlaceholder),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                // Quantity never drops below one: AddItem rejects zero, and a
                // zero-quantity row on a shopping list means nothing.
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_quantity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: t.items.notePlaceholder),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            final note = _note.text.trim();
            Navigator.of(context).pop((
              name: _name.text,
              quantity: _quantity,
              noteText: note.isEmpty ? null : note,
            ));
          },
          child: Text(t.common.save),
        ),
      ],
    );
  }
}
