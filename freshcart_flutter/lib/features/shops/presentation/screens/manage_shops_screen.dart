import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/dashed_add_row.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_flutter/core/ui/swipe_to_delete.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_controller.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/delete_shop_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The shops on one list, editable.
///
/// Each row is just the shop's dot and name, and tapping it opens the edit
/// sheet. Deleting is a deliberate swipe (right-to-left, Motion spec §10)
/// that opens the delete sheet -- never a trash icon one tap away on every
/// row, sitting beside the edit chevron and looking no more serious than it.
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
        // The same empty-state layout every other screen uses, with the one
        // thing worth doing about a failed load: trying again.
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
            // The only exit here, so it lives in the empty state itself --
            // same rule as ListsScreen's empty state.
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
            // Inline at the end, not a FAB: the same dashed "add another"
            // row onboarding ends its shop list with, and the same dash as
            // the strip's own "+" pill.
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
  /// The preview border's weight -- heavier than the resting hairline, so
  /// the row behind the sheet visibly answers each swatch tap.
  static const double _previewBorder = 1.5;

  Shop get shop => widget.shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    // Through the preview, so a colour being tried in the sheet shows here
    // too -- this row sits behind it.
    final color = ref.watch(effectiveShopColorProvider(shop));
    // A colour that differs from what is stored can only be a live preview:
    // the row being edited takes it as its border, tying it to the sheet.
    final previewing = color != shop.color;

    return SwipeToDelete(
      dismissKey: ValueKey('dismiss-${shop.id.value}'),
      semanticLabel: t.shops.delete,
      borderRadius: BorderRadius.circular(AppRadii.card),
      // Never dismisses on its own: a shop's products need a decision
      // first, so a committed swipe opens the delete sheet and the row
      // springs back. If the shop is deleted, the list rebuilds without it.
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditShopSheet(
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
        if (mounted) showFailureSnackBar(context, failure: failure, t: t);
        return;
    }
    if (!mounted) return;

    final choice = await showModalBottomSheet<ShopDeletion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
    if (failure != null && mounted) {
      showFailureSnackBar(context, failure: failure, t: t);
    }
  }
}
