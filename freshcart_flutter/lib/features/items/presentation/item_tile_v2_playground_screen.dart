import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile_v2/item_tile_v2.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Dev-only: a real, routed screen hosting a list of [ItemTileV2]s.
///
/// Exists specifically to test the hold-to-open overlay outside
/// `flutter widget-preview`'s gallery canvas, which may not composite a
/// full-screen [Overlay] the same way a real running app does — see
/// `docs/dev-guide.md`. Reached only from Settings' dev-tools row, itself
/// gated to `kDebugMode`.
class ItemTileV2PlaygroundScreen extends StatefulWidget {
  const ItemTileV2PlaygroundScreen({super.key});

  @override
  State<ItemTileV2PlaygroundScreen> createState() =>
      _ItemTileV2PlaygroundScreenState();
}

class _ItemTileV2PlaygroundScreenState
    extends State<ItemTileV2PlaygroundScreen> {
  late final List<(ShoppingItem, Color?)> _rows = [
    (_devItem(name: 'Pasta', quantity: 2), Colors.red),
    (
      _devItem(
        name: 'Olive oil',
        quantity: 1,
        note: 'Extra virgin, tall bottle',
      ),
      Colors.green,
    ),
    (_devItem(name: 'Bananas', quantity: 6), Colors.yellow),
    (_devItem(name: 'Yoghurt', quantity: 4), null),
    (
      _devItem(name: 'Ground beef', quantity: 1, note: 'Lean, 500g'),
      Colors.brown,
    ),
    (_devItem(name: 'Chocolate spread', quantity: 1), Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item tile v2 playground')),
      body: ListView(
        children: [
          for (final (item, shopColor) in _rows)
            ItemTileV2(
              t: t,
              key: ValueKey(item.id),
              item: item,
              shopColor: shopColor,
              // Real deletion (so the playground actually exercises
              // "does the row disappear"), plain debug prints for the two
              // that would need real screens (edit sheet, shop repository)
              // this dev-only screen doesn't have.
              onToggle: () => debugPrint('toggle: ${item.name}'),
              onEdit: () => debugPrint('edit: ${item.name}'),
              onDelete: () => setState(
                () => _rows.removeWhere((row) => row.$1.id == item.id),
              ),
              // Also real, since it's just a local list update -- no edit
              // sheet or repository needed to exercise "does the number
              // actually change."
              onQuantityChanged: (quantity) => setState(() {
                final index = _rows.indexWhere((row) => row.$1.id == item.id);
                if (index != -1) {
                  _rows[index] = (
                    _rows[index].$1.copyWith(quantity: quantity),
                    _rows[index].$2,
                  );
                }
              }),
            ),
        ],
      ),
    );
  }
}

ShoppingItem _devItem({
  required String name,
  required int quantity,
  String? note,
}) => ShoppingItem(
  id: ItemId('dev_${name.toLowerCase().replaceAll(' ', '_')}'),
  listId: ListId('dev_list'),
  addedBy: UserId('dev_author'),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  name: name,
  quantity: quantity,
  note: note == null
      ? null
      : Note(
          text: note,
          authorId: UserId('dev_author'),
          updatedAt: DateTime.now(),
        ),
);
