import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_sizes.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/feedback/empty_state.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_state.dart';
import 'package:freshcart_flutter/core/ui/motion/swipe_to_delete.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_controller.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/dashed_add_row.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/delete_shop_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The screen to manage one list's shops.
///
/// Each row shows the shop's colour dot and name. Tap to edit. Swipe left
/// to delete, which opens the delete sheet. There's no trash icon on
/// purpose, so deleting is never one accidental tap away.
///
/// The sheets are opened here (they need a `BuildContext`). Everything
/// else comes from [ManageShopsScreenController].
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
        // Loading failed: show the error with a Retry button.
        ManageShopsScreenState(loadFailure: final failure?) => FailureState(
          failure: failure,
          t: t,
          action: ElevatedButton(
            onPressed: vm.retry,
            child: Text(t.common.retry),
          ),
        ),
        ManageShopsScreenState(shops: null) => const Center(
          child: CircularProgressIndicator(),
        ),
        ManageShopsScreenState(shops: final loaded?) when loaded.isEmpty =>
          EmptyState(
            icon: Icons.storefront_outlined,
            title: t.shops.none,
            body: t.items.emptyShopBody,
            // No shops yet: the empty state has the "add shop" button.
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
              Padding(
                key: ValueKey(shop.id.value),
                padding: const EdgeInsets.only(bottom: AppSpacing.gapSmall),
                child: _ShopRow(shop: shop, siblings: loaded, vm: vm),
              ),
            // "Add another" row at the end of the list (not a FAB), same
            // as in onboarding.
            DashedAddRow(
              label: t.shops.add,
              onTap: () => addShop(context, ref, listId, loaded),
            ),
          ],
        ),
      },
    );
  }
}

class _ShopRow extends ConsumerStatefulWidget {
  const _ShopRow({
    required this.shop,
    required this.siblings,
    required this.vm,
  });

  final Shop shop;
  final List<Shop> siblings;
  final ManageShopsScreenController vm;

  @override
  ConsumerState<_ShopRow> createState() => _ShopRowState();
}

class _ShopRowState extends ConsumerState<_ShopRow> {
  /// Border width while previewing a colour. Thicker than normal, so you
  /// can see the row react behind the sheet.
  static const double _previewBorder = 1.5;

  Shop get shop => widget.shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    // Includes the preview colour, so this row changes while the user tries
    // colours in the sheet.
    final color = ref.watch(effectiveShopColorProvider(shop));
    // If the colour differs from the saved one, it's a preview. Show a
    // border so it's clear which row is being edited.
    final previewing = color != shop.color;

    return SwipeToDelete(
      dismissKey: ValueKey('dismiss-${shop.id.value}'),
      semanticLabel: t.shops.delete,
      borderRadius: BorderRadius.circular(AppRadii.card),
      // Swiping doesn't delete directly. It opens the delete sheet (the
      // user has to decide what happens to the items) and the row slides
      // back. If the shop is deleted, the list rebuilds without it.
      onSwipe: () async {
        await _delete(t);
        return false;
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _edit(t),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: AnimatedContainer(
            duration: AppMotion.durationFor(context, AppMotion.standard),
            curve: AppMotion.enter,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap,
              vertical: AppSpacing.rowVertical,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color: previewing
                    ? color.toColor()
                    : theme.colorScheme.outlineVariant,
                width: previewing ? _previewBorder : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.durationFor(
                    context,
                    AppMotion.standard,
                  ),
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
                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(Translations t) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => ShopSheet(
        shop: shop,
        siblings: widget.siblings,
        onSave: ({required name, required color}) async =>
            (await widget.vm.edit(shop, name: name, color: color))?.toMessage(
              t,
            ),
      ),
    );
    widget.vm.endEdit();
  }

  Future<void> _delete(Translations t) async {
    final int count;
    switch (await widget.vm.itemCountForDelete(shop)) {
      case Ok(:final value):
        count = value;
      case Err(:final failure):
        showFailureSnackBar(context, failure: failure, t: t);
        return;
    }
    if (!mounted) return;

    final choice = await showAppSheet<ShopDeletion>(
      context: context,
      builder: (_) => DeleteShopSheet(
        shop: shop,
        itemCount: count,
        siblings: widget.siblings,
      ),
    );
    if (choice == null || !mounted) return;

    final failure = await widget.vm.remove(
      shop,
      disposition: choice.disposition,
      moveTo: choice.moveTo,
    );
    if (!mounted) return;
    showFailureSnackBar(context, failure: failure, t: t);
  }
}
