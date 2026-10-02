import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';

/// Opens [EditShopSheet] to create a new shop, and saves it with
/// [ShopsController.create].
///
/// A top-level function, because more than one place opens it: Manage shops
/// and the "+" in the shop tabs. One function means they can't drift apart.
/// See decisions.md #63 and #65.
Future<void> addShop(
  BuildContext context,
  WidgetRef ref,
  ListId listId,
  List<Shop> siblings,
) async {
  final controller = ref.read(shopsControllerProvider(listId).notifier);
  final t = ref.read(translationsProvider);

  await showAppSheet<void>(
    context: context,
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
