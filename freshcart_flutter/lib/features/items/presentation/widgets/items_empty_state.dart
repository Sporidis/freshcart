import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/cascade_in.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The list's empty state (design v3): a ghost of the list it will become
/// (three rows with dashed rings in the accent colour), a title, one line,
/// and a pill that starts adding.
///
/// The ghost shows what to do instead of describing it. The accent comes
/// from the theme, so on a shop tab it's that shop's colour.
class ItemsEmptyState extends StatelessWidget {
  const ItemsEmptyState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parts = <Widget>[
      const _GhostCard(),
      const SizedBox(height: 22),
      Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.cardTitle.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 15,
            height: 21 / 15,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: 18),
      _ActionPill(label: actionLabel, onTap: onAction),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, part) in parts.indexed)
            CascadeIn(
              index: i,
              step: const Duration(milliseconds: 40),
              child: part,
            ),
        ],
      ),
    );
  }
}

/// A 230px card with three placeholder rows, fading out down the card.
class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(double width, double opacity) => Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CustomPaint(
                painter: DashedOutlinePainter(
                  color: scheme.primary.withValues(alpha: .55),
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.fill,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .06),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(children: [row(120, 1), row(86, .7), row(140, .4)]),
    );
  }
}

/// "+ Add a product": a 44px outlined pill with an accent plus.
class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: TapTarget(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 15,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(group: 'Items', name: 'Empty list (v3)', size: Size(393, 520))
Widget itemsEmptyStatePreview() => previewPiece(
  ItemsEmptyState(
    title: 'Your list is empty',
    body:
        'Add the first product. Everyone in the household sees it straight away.',
    actionLabel: 'Add a product',
    onAction: () {},
  ),
);
