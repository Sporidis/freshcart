import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What the user picked in [showMoveToShopSheet].
///
/// A wrapper is needed because "no shop" is also null. Without it, null
/// could mean "move to no shop" or "cancelled".
class MoveToShopOutcome {
  const MoveToShopOutcome(this.shopId);

  final ShopId? shopId;
}

/// Asks which shop the selected items should move to. Returns null if
/// cancelled.
Future<MoveToShopOutcome?> showMoveToShopSheet(
  BuildContext context, {
  required List<Shop> shops,
  required Translations t,
}) => showAppSheet<MoveToShopOutcome>(
  context: context,
  builder: (_) => _MoveToShopSheet(shops: shops, t: t),
);

/// The "Move to shop" sheet in select mode. Uses the same [ShopPicker] as
/// `ItemSheet`.
class _MoveToShopSheet extends StatelessWidget {
  const _MoveToShopSheet({required this.shops, required this.t});

  final List<Shop> shops;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: t.items.moveTo,
      children: [
        ShopPicker(
          shops: shops,
          t: t,
          onSelected: (id) => Navigator.of(context).pop(MoveToShopOutcome(id)),
        ),
      ],
    );
  }
}
