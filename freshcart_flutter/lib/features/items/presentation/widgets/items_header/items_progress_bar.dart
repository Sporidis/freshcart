import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';

/// The tab's progress: a 4px bar in the tab's colour and "3 of 10". Lined
/// up with the title (60px in), not the menu button.
class ItemsProgressBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Creates the bar for [list]'s active tab.
  const ItemsProgressBar({required this.list, required this.height, super.key});

  final ShoppingList list;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final items = ref.watch(itemsSectionControllerProvider(list));
    // Search looks across every tab, so the tab's progress means nothing
    // there.
    final visible = items.mode != ItemsMode.search;
    final done = items.checkedCount;
    final total = items.visibleCount;
    final theme = Theme.of(context);
    final color =
        items.activeShop?.color.toColor() ?? theme.colorScheme.primary;
    final fraction = total == 0 ? 0.0 : done / total;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.durationFor(context, AppMotion.quick),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 0, AppSpacing.screen, 6),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: ColoredBox(
                    color: theme.colorScheme.fill,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fraction),
                      duration: AppMotion.durationFor(
                        context,
                        const Duration(milliseconds: 420),
                      ),
                      curve: AppMotion.enter,
                      builder: (context, value, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: AnimatedContainer(
                          duration: AppMotion.durationFor(
                            context,
                            AppMotion.standard,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                t.items.progressOf(done: done, total: total),
                style: AppTextStyles.secondaryStrong.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
