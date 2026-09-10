import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What [AddItemSheet] hands back on save.
typedef AddItemDetails = ({String name, int quantity, ShopId? shopId});

/// The detailed add path: name (already typed, still editable), quantity,
/// and which shop it belongs to.
///
/// Reached from [QuickAddBar] once there is text and the button is tapped
/// rather than Return pressed -- the deliberate path, for whenever the
/// default quantity of one and no shop tag are not what is wanted. [shops]
/// is loaded by the caller rather than watched here, the same shape
/// `EditShopSheet` takes its `siblings` in — a sheet takes what it is given,
/// it does not go fetch its own.
class AddItemSheet extends StatefulWidget {
  /// Creates the sheet, pre-filled with [initialName].
  const AddItemSheet({
    required this.initialName,
    required this.shops,
    required this.t,
    super.key,
  });

  /// What was already typed in [QuickAddBar], carried over so nothing has to
  /// be retyped.
  final String initialName;

  /// The shops on this list, to tag the item to one of them. Empty hides the
  /// picker entirely -- nothing to choose from is not worth a section.
  final List<Shop> shops;

  /// Translations for the active locale.
  final Translations t;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  int _quantity = 1;
  ShopId? _shopId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(
      context,
    ).pop<AddItemDetails>((name: name, quantity: _quantity, shopId: _shopId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.t;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        8,
        AppSpacing.sheetH,
        MediaQuery.viewInsetsOf(context).bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.items.add, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.gap),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: t.items.namePlaceholder),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Quantity never drops below one: AddItem rejects zero, and a
              // zero-quantity row on a shopping list means nothing.
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (widget.shops.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.shops.none),
                  selected: _shopId == null,
                  onSelected: (_) => setState(() => _shopId = null),
                ),
                for (final shop in widget.shops)
                  ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(shop.color.argb),
                      radius: 8,
                    ),
                    label: Text(shop.name),
                    selected: _shopId == shop.id,
                    onSelected: (_) => setState(() => _shopId = shop.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(t.items.add),
            ),
          ),
        ],
      ),
    );
  }
}
