import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar_pill.dart';

/// The header while rearranging: what's being reordered (the list or one
/// shop's tab) and Done.
class ItemsRearrangeBar extends ConsumerWidget {
  /// Creates the bar for rearranging [list]'s items.
  const ItemsRearrangeBar({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final activeShop = ref.watch(
      itemsSectionControllerProvider(list).select((s) => s.activeShop),
    );
    return ModeBar(
      title: Text(t.items.rearrangeHeader),
      subtitle: switch (activeShop) {
        null => t.items.rearrangeScopeAll(list: list.name),
        final shop => t.items.rearrangeScopeShop(shop: shop.name),
      },
      actions: [
        ModeBarPill(
          label: t.common.done,
          emphasized: true,
          onTap: () {
            ref
                .read(itemsSectionControllerProvider(list).notifier)
                .stopRearrange();
            showUndoToast(
              context,
              message: t.items.orderSaved,
              t: t,
              tick: true,
            );
          },
        ),
      ],
    );
  }
}
