import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/add_item_field.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_editor_dialog.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The items of one list, filtered by the active shop, with the add field
/// pinned underneath.
class ItemsSection extends ConsumerWidget {
  /// Creates the section for [list].
  const ItemsSection({required this.list, super.key});

  /// The list whose items to show. Members come from here so a checked-off item
  /// can name the person who ticked it without another request.
  final ShoppingList list;

  /// Applies the active shop filter.
  ///
  /// The rule itself lives on the entity — an untagged item matches every
  /// filter, so a forgotten tag never hides someone's shopping.
  static List<ShoppingItem> visibleIn(
    List<ShoppingItem> all,
    ShopId? filter,
  ) => [
    for (final item in all)
      if (item.matchesShopFilter(filter)) item,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final items = ref.watch(itemsControllerProvider(list.id));
    final controller = ref.read(itemsControllerProvider(list.id).notifier);
    final shopFilter = ref.watch(shopFilterProvider(list.id));

    /// Shows the message behind a rolled-back optimistic update.
    ///
    /// Without this a row would tick, untick itself and leave the user
    /// wondering whether they mis-tapped.
    void report(Failure? failure) {
      if (failure == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.toMessage(t))));
    }

    return Column(
      children: [
        Expanded(
          child: switch (items) {
            AsyncLoading<Result<List<ShoppingItem>>>() => const Center(
              child: CircularProgressIndicator(),
            ),
            AsyncError<Result<List<ShoppingItem>>>() => Center(
              child: Text(t.errors.unexpected),
            ),
            AsyncOutcome<List<ShoppingItem>>(:final value?) => switch (value) {
              Err<List<ShoppingItem>>(:final failure) => Center(
                child: Text(failure.toMessage(t)),
              ),
              Ok<List<ShoppingItem>>(value: final all)
                  when visibleIn(all, shopFilter).isEmpty =>
                Center(child: Text(t.items.empty)),
              Ok<List<ShoppingItem>>(value: final all) => _ItemList(
                rows: visibleIn(all, shopFilter),
                list: list,
                t: t,
                controller: controller,
                report: report,
                onRefresh: controller.refresh,
              ),
            },
          },
        ),
        AddItemField(
          t: t,
          onSubmit: (name) async {
            final failure = await controller.add(name: name);
            report(failure);
            return failure == null;
          },
        ),
      ],
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.rows,
    required this.list,
    required this.t,
    required this.controller,
    required this.report,
    required this.onRefresh,
  });

  final List<ShoppingItem> rows;
  final ShoppingList list;
  final Translations t;
  final ItemsController controller;
  final void Function(Failure?) report;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final item = rows[index];
        return ItemTile(
          item: item,
          t: t,
          checkedByName: item.checkedBy == null
              ? null
              : list.memberFor(item.checkedBy!)?.displayName,
          onToggle: () async => report(await controller.toggle(item)),
          onDelete: () async => report(await controller.remove(item)),
          onEdit: () async {
            final edit = await showDialog<ItemEdit>(
              context: context,
              builder: (context) => ItemEditorDialog(item: item, t: t),
            );
            if (edit == null) return;
            report(
              await controller.edit(
                item,
                name: edit.name,
                quantity: edit.quantity,
                shopId: item.shopId,
                noteText: edit.noteText,
              ),
            );
          },
        );
      },
    ),
  );
}
