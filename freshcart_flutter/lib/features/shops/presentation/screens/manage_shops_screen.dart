import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_controller.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/delete_shop_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The shops on one list, editable.
/// TODO: improve the UI and UX for managing shops, including better handling of empty states and error messages.
///
/// Reads [ManageShopsScreenController]. The edit and delete sheets stay
/// here, since they need a `BuildContext`; every step around them -- the
/// write, the item count, clearing the colour preview -- comes from the VM.
class ManageShopsScreen extends ConsumerWidget {
  /// Creates the screen for [listId].
  const ManageShopsScreen({required this.listId, super.key});

  /// The list whose shops these are.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(manageShopsScreenControllerProvider(listId));
    final vm = ref.read(manageShopsScreenControllerProvider(listId).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t.shops.manage)),
      body: switch (s) {
        ManageShopsScreenState(loadFailure: final failure?) => Center(
          child: Text(failure.toMessage(t)),
        ),
        ManageShopsScreenState(shops: null) => const Center(
          child: CircularProgressIndicator(),
        ),
        ManageShopsScreenState(shops: final loaded?) when loaded.isEmpty =>
          EmptyState(
            icon: Icons.storefront_outlined,
            title: t.shops.none,
            body: t.items.emptyShopBody,
            // The only exit here, so it lives in the empty state itself
            // rather than a FAB — same rule as ListsScreen's empty state.
            action: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => addShop(context, ref, listId, const <Shop>[]),
                child: Text(t.shops.add),
              ),
            ),
          ),
        ManageShopsScreenState(shops: final loaded?) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            for (final shop in loaded)
              _ShopRow(shop: shop, siblings: loaded, vm: vm),
          ],
        ),
      },
      // Hidden while the empty state is up, matching ListsScreen: the empty
      // state already offers this as its one action.
      floatingActionButton: s.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  addShop(context, ref, listId, s.shops ?? const <Shop>[]),
              icon: const Icon(Icons.add),
              label: Text(t.shops.add),
            ),
    );
  }
}

class _ShopRow extends ConsumerWidget {
  const _ShopRow({
    required this.shop,
    required this.siblings,
    required this.vm,
  });

  final Shop shop;
  final List<Shop> siblings;
  final ManageShopsScreenController vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    // Through the preview, so a colour being tried in the sheet shows here
    // too — this row sits behind it.
    final color = ref.watch(effectiveShopColorProvider(shop));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
      child: InkWell(
        onTap: () => _edit(context, t),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.durationFor(context, AppMotion.standard),
                curve: AppMotion.enter,
                width: AppSizes.shopDotLarge,
                height: AppSizes.shopDotLarge,
                decoration: BoxDecoration(
                  color: color.toColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.gap),
              Expanded(
                child: Text(shop.name, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: () => _delete(context, t),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: t.shops.delete,
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Translations t) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditShopSheet(
        shop: shop,
        siblings: siblings,
        onSave: ({required name, required color}) async =>
            (await vm.edit(shop, name: name, color: color))?.toMessage(t),
      ),
    );
    vm.endEdit();
  }

  Future<void> _delete(BuildContext context, Translations t) async {
    final int count;
    switch (await vm.itemCountForDelete(shop)) {
      case Ok(:final value):
        count = value;
      case Err(:final failure):
        if (context.mounted) {
          showFailureSnackBar(context, failure: failure, t: t);
        }
        return;
    }
    if (!context.mounted) return;

    final choice = await showModalBottomSheet<ShopDeletion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DeleteShopSheet(
        shop: shop,
        itemCount: count,
        siblings: siblings,
      ),
    );
    if (choice == null || !context.mounted) return;

    final failure = await vm.remove(
      shop,
      disposition: choice.disposition,
      moveTo: choice.moveTo,
    );
    if (failure != null && context.mounted) {
      showFailureSnackBar(context, failure: failure, t: t);
    }
  }
}
