import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/items/application/celebration_dismissed_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/confetti_burst.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Everything on this list is checked off" — one raised card, plus the
/// restrained confetti burst §09 of the motion spec calls for.
///
/// Named `celebrate` in the motion spec (§13, `AppMotion.celebrate`,
/// `AppMotion.spring`) as the one moment in the app allowed to feel like an
/// event — everywhere else, motion stays quick and gets out of the way.
/// Reduced motion (`AppMotion.reduced`) turns the spring pop into a plain,
/// static appearance and skips the confetti burst entirely, per the spec's
/// own fallback note for this exact card.
class CompletionCelebrationCard extends ConsumerStatefulWidget {
  /// Creates the card for [list], which currently has [itemCount] items, all
  /// checked.
  const CompletionCelebrationCard({
    required this.list,
    required this.itemCount,
    required this.shopColors,
    required this.t,
    required this.report,
    super.key,
  });

  /// The list being celebrated.
  final ShoppingList list;

  /// How many items are on it — the celebration counts them, so the caller
  /// hands over the number it already had rather than this card re-deriving
  /// it from a second watch of the same provider.
  final int itemCount;

  /// The palette the confetti burst draws from — "the list's shop colours
  /// only" per the motion spec, not an app-wide default. Handed in rather
  /// than re-derived here so this widget never needs its own opinion about
  /// what a shopless list falls back to; `ItemsSection` already owns that
  /// call for the rest of the screen.
  final List<Color> shopColors;

  /// Translations for the active locale.
  final Translations t;

  /// Surfaces a failed "Clear checked" the same way every other write on
  /// this screen does — see `ItemsSection`'s own `report`.
  final void Function(Failure? failure) report;

  @override
  ConsumerState<CompletionCelebrationCard> createState() =>
      _CompletionCelebrationCardState();
}

class _CompletionCelebrationCardState
    extends ConsumerState<CompletionCelebrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    value: 0,
  );

  // Held so dispose() can cancel a still-running burst -- otherwise its
  // Ticker has no idea this widget (and the confetti it started) is going
  // away before the 1.4s finishes on its own.
  ConfettiBurstHandle? _confetti;

  @override
  void initState() {
    super.initState();
    // Deferred a frame: AppMotion.reduced needs a built context to read
    // MediaQuery from, which initState does not reliably have yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _entrance.value = 1;
      } else {
        _entrance.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0));
        // "Skip entirely if reduced-motion is on" (§09) — the branch above
        // already means this line is only reached when it isn't.
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
    final controller = ref.read(
      itemsControllerProvider(widget.list.id).notifier,
    );

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
          padding: const EdgeInsets.all(20),
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
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 4),
              Text(
                t.items.celebrateBody(list: widget.list.name),
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                spacing: 9,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(
                            celebrationDismissedProvider(
                              widget.list.id,
                            ).notifier,
                          )
                          .dismiss(),
                      child: Text(t.items.keepList),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async =>
                          widget.report(await controller.clearChecked()),
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
  ),
  padding: EdgeInsets.zero,
);

/// A minimal [ShoppingList] for the preview above — not exported, previews
/// only.
ShoppingList buildPreviewList() => ShoppingList(
  id: ListId('00000000-0000-4000-8000-000000000001'),
  name: 'Weekly Groceries',
  joinCode: JoinCode.parse('ABC23').valueOrNull!,
  ownerId: UserId('user-1'),
  createdAt: DateTime.utc(2026, 9, 9),
);
