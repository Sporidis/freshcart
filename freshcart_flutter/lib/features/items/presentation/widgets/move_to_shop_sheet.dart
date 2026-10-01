import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What [showMoveToShopSheet] resolved to -- distinct from `null`, which
/// means "dismissed without choosing", so "moved to no shop" (untagged, a
/// real choice) is never confused with "cancelled" (do nothing at all).
class MoveToShopOutcome {
  const MoveToShopOutcome(this.shopId);

  final ShopId? shopId;
}

/// Asks which shop a multi-selection should move to.
Future<MoveToShopOutcome?> showMoveToShopSheet(
  BuildContext context, {
  required List<Shop> shops,
  required Translations t,
}) => showModalBottomSheet<MoveToShopOutcome>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MoveToShopSheet(shops: shops, t: t),
);

/// The multi-select "Move" sheet: the same [ShopPicker] `ItemSheet` uses
/// for one item at a time, offered here for a whole selection instead.
class _MoveToShopSheet extends StatelessWidget {
  const _MoveToShopSheet({required this.shops, required this.t});

  final List<Shop> shops;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sheetH,
          0,
          AppSpacing.sheetH,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.items.moveTo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.gap),
            ShopPicker(
              shops: shops,
              t: t,
              onSelected: (id) =>
                  Navigator.of(context).pop(MoveToShopOutcome(id)),
            ),
          ],
        ),
      ),
    );
  }
}
