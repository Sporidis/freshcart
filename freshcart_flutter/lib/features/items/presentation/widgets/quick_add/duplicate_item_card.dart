import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The "already on the list" card: "{item} is already on {shop}, x{n}".
///
/// Main button: add 1 to the existing item's quantity. Second button: add
/// it as a new row anyway.
class DuplicateItemCard extends StatelessWidget {
  const DuplicateItemCard({
    required this.item,
    required this.shopName,
    required this.t,
    required this.onBump,
    required this.onAddAnyway,
    super.key,
  });

  final ShoppingItem item;
  final String shopName;
  final Translations t;
  final VoidCallback onBump;
  final VoidCallback onAddAnyway;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.items.alreadyOnShop(
                  name: item.name,
                  shop: shopName,
                  quantity: item.quantity,
                ),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.gapSmall),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onBump,
                      child: Text(
                        t.items.makeItX(quantity: item.quantity + 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gapSmall),
                  // Expanded like its neighbour: the theme's buttons are
                  // full-width (Size.fromHeight), which in a Row means
                  // infinitely wide.
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAddAnyway,
                      child: Text(t.items.addAnyway),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
