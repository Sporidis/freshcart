import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/delete_shop_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';

/// The shops on one list, editable.
class ManageShopsScreen extends ConsumerWidget {
  /// Creates the screen for [listId].
  const ManageShopsScreen({required this.listId, super.key});

  /// The list whose shops these are.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final shops = ref.watch(shopsControllerProvider(listId));
    final isEmpty = shops.dataOrNull?.isEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(t.shops.manage)),
      body: switch (shops) {
        AsyncLoading<Result<List<Shop>>>() => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<Result<List<Shop>>>() => Center(
          child: Text(t.errors.unexpected),
        ),
        AsyncOutcome<List<Shop>>(:final value?) => switch (value) {
          Err<List<Shop>>(:final failure) => Center(
            child: Text(failure.toMessage(t)),
          ),
          Ok<List<Shop>>(value: final loaded) when loaded.isEmpty => EmptyState(
            icon: Icons.storefront_outlined,
            title: t.shops.none,
            body: t.items.emptyShopBody,
            // The only exit here, so it lives in the empty state itself
            // rather than a FAB — same rule as ListsScreen's empty state.
            action: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addShop(context, ref, listId, const []),
                child: Text(t.shops.add),
              ),
            ),
          ),
          Ok<List<Shop>>(value: final loaded) => ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              for (final shop in loaded)
                _ShopRow(shop: shop, siblings: loaded, listId: listId),
            ],
          ),
        },
      },
      // Hidden while the empty state is up, matching ListsScreen: the empty
      // state already offers this as its one action.
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addShop(
                context,
                ref,
                listId,
                shops.dataOrNull ?? const [],
              ),
              icon: const Icon(Icons.add),
              label: Text(t.shops.add),
            ),
    );
  }

  /// Opens the create-mode sheet and commits through [ShopsController.create].
  static Future<void> _addShop(
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
}

class _ShopRow extends ConsumerWidget {
  const _ShopRow({
    required this.shop,
    required this.siblings,
    required this.listId,
  });

  final Shop shop;
  final List<Shop> siblings;
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Through the preview, so a colour being tried in the sheet shows here
    // too — this row sits behind it.
    final color = ref.watch(effectiveShopColorProvider(shop));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
      child: InkWell(
        onTap: () => _edit(context, ref),
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
                  color: Color(color.argb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.gap),
              Expanded(
                child: Text(shop.name, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: ref.read(translationsProvider).shops.delete,
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(shopsControllerProvider(listId).notifier);
    final t = ref.read(translationsProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditShopSheet(
        shop: shop,
        siblings: siblings,
        onSave: ({required name, required color}) async {
          final result = await controller.edit(shop, name: name, color: color);
          return switch (result) {
            Ok<Shop>() => null,
            Err<Shop>(:final failure) => failure.toMessage(t),
          };
        },
      ),
    );
    // Whether it saved or was dismissed, the preview must not outlive the
    // sheet: an abandoned colour left tinting the app would be a lie about
    // what is stored.
    ref.read(shopColorPreviewProvider.notifier).clear();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(shopsControllerProvider(listId).notifier);
    final t = ref.read(translationsProvider);

    // The count is fetched before asking, because it is the question: an empty
    // shop needs no decision, a shop holding six products needs a real one.
    final count = switch (await controller.itemCount(shop.id)) {
      Ok<int>(:final value) => value,
      Err<int>(:final failure) => failure,
    };
    if (!context.mounted) return;
    if (count is Failure) {
      showFailureSnackBar(context, failure: count, t: t);
      return;
    }

    final choice = await showModalBottomSheet<ShopDeletion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DeleteShopSheet(
        shop: shop,
        itemCount: count as int,
        siblings: siblings,
      ),
    );
    if (choice == null || !context.mounted) return;

    final result = await controller.remove(
      shop.id,
      disposition: choice.disposition,
      moveTo: choice.moveTo,
    );
    if (!context.mounted) return;
    if (result case Err<void>(:final failure)) {
      showFailureSnackBar(context, failure: failure, t: t);
    }
  }
}
