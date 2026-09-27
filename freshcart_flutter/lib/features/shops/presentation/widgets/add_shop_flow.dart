import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/shops/application/controllers/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';

/// Opens the create-mode [EditShopSheet] and commits through
/// [ShopsController.create].
///
/// A top-level function rather than a method on one screen, because two
/// entry points open it now -- [ManageShopsScreen]'s FAB and the shop tab
/// strip's own dashed "+" pill -- and this codebase's own rule (decisions
/// #63, #65) is one flow, more than one place to reach it, not a second
/// copy to keep in sync.
Future<void> addShop(
  BuildContext context,
  WidgetRef ref,
  ListId listId,
  List<Shop> siblings,
) async {
  final controller = ref.read(shopsControllerProvider(listId).notifier);
  final t = ref.read(translationsProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => EditShopSheet(
      shop: null,
      siblings: siblings,
      onSave: ({required name, required color}) async {
        final result = await controller.create(name: name, color: color);
        return switch (result) {
          Ok<Shop>() => null,
          Err<Shop>(:final failure) => failure.toMessage(t),
        };
      },
    ),
  );
}
