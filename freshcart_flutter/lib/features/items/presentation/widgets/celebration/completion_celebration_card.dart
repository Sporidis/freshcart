import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/confetti_burst.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The "everything is checked off!" card, with a small confetti burst.
///
/// The only place in the app with a big, fun animation. Everywhere else,
/// animations are quick and subtle.
///
/// With reduced motion on, the card just appears (no bounce) and there's no
/// confetti.
class CompletionCelebrationCard extends StatefulWidget {
  /// Creates the card for [list], which currently has [itemCount] items, all
  /// checked.
  const CompletionCelebrationCard({
    required this.list,
    required this.itemCount,
    required this.shopColors,
    required this.t,
    required this.report,
    required this.onKeep,
    required this.onClear,
    super.key,
  });

  /// The list being celebrated.
  final ShoppingList list;

  /// How many items are on the list (shown on the card).
  final int itemCount;

  /// The confetti colours: the list's shop colours. Passed in by
  /// `ItemsSection`, which also decides what to use if there are no shops.
  final List<Color> shopColors;

  /// Translations for the active locale.
  final Translations t;

  /// Shows an error if "Clear checked" fails (same as other errors on this
  /// screen).
  final void Function(Failure? failure) report;

  /// "Keep list": hide the card, leave the items alone.
  final VoidCallback onKeep;

  /// "Clear checked": remove every checked item.
  final Future<Failure?> Function() onClear;

  @override
  State<CompletionCelebrationCard> createState() =>
      _CompletionCelebrationCardState();
}

class _CompletionCelebrationCardState extends State<CompletionCelebrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    value: 0,
  );

  // Kept so dispose() can stop the confetti if the card closes before the
  // 1.4 s animation is done.
  ConfettiBurstHandle? _confetti;

  @override
  void initState() {
    super.initState();
    // Wait one frame: AppMotion.reduced reads MediaQuery, which isn't
    // safe to use in initState yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _entrance.value = 1;
      } else {
        _entrance.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0));
        // Confetti. We only get here when reduced motion is off (checked
        // above).
        _confetti = ConfettiBurst.fire(context, colors: widget.shopColors);
      }
    });
  }

  @override
  void dispose() {
    _confetti?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.t;

    return FadeTransition(
      opacity: _entrance,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.85,
          end: 1,
        ).animate(_entrance),
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.gap,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.celebration),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 34,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                t.items.celebrateCount(n: widget.itemCount),
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.items.celebrateBody(list: widget.list.name),
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                spacing: 9,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onKeep,
                      child: Text(t.items.keepList),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async =>
                          widget.report(await widget.onClear()),
                      child: Text(t.items.clearChecked),
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

@Preview(
  group: 'Items',
  name: 'Completion celebration',
  size: Size(393, 220),
)
Widget completionCelebrationCardPreview() => previewPiece(
  CompletionCelebrationCard(
    list: buildPreviewList(),
    itemCount: 6,
    shopColors: const [Colors.orange, Colors.teal, Colors.purple],
    t: previewTranslations,
    report: (_) {},
    onKeep: () {},
    onClear: () async => null,
  ),
  padding: EdgeInsets.zero,
);

/// A fake [ShoppingList], only for the preview above.
ShoppingList buildPreviewList() => ShoppingList(
  id: ListId('00000000-0000-4000-8000-000000000001'),
  name: 'Weekly Groceries',
  joinCode: JoinCode.parse('ABC23').valueOrNull!,
  ownerId: UserId('user-1'),
  createdAt: DateTime.utc(2026, 9, 9),
);
