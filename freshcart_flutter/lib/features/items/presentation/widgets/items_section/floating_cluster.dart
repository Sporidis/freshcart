import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/item_flows.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What floats over the rows normally: the "all done" card (if needed)
/// and the add button.
class FloatingCluster extends StatelessWidget {
  /// Bottom padding for content under the cluster, so the last row (or
  /// the empty-state text) isn't hidden under the add button.
  static const double inset = 84;

  const FloatingCluster({
    super.key,
    required this.s,
    required this.vm,
    required this.flows,
    required this.t,
  });

  final ItemsSectionState s;
  final ItemsSectionController vm;
  final ItemFlows flows;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.showCelebration)
          CompletionCelebrationCard(
            list: s.list,
            itemCount: s.allItems.length,
            shopColors: s.shops.isEmpty
                ? AppColors.presetShopColors
                : [for (final shop in s.shops) shop.color.toColor()],
            t: t,
            report: flows.report,
            onKeep: vm.dismissCelebration,
            onClear: vm.clearChecked,
          ),
        QuickAddBar(
          listId: s.list.id,
          t: t,
          activeShopName: s.activeShop?.name,
          firstRun: s.firstRun,
          onQuickAdd: flows.quickAdd,
          onOpenDetails: flows.addWithDetails,
          findDuplicate: (name) => s.duplicateFor(name, s.shopFilter),
          onBumpDuplicate: flows.bumpDuplicate,
        ),
      ],
    );
  }
}
