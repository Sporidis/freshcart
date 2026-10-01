import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// FreshCart's front door: one screen, two exits, no carousel.
///
/// Traced from the design's own Welcome frame rather than an original take —
/// it shows the product instead of describing it, a tilted preview of a real
/// list cropped by the fold, so the pitch is legible before a single word of
/// copy is read.
class WelcomeScreen extends ConsumerWidget {
  /// Creates the welcome screen.
  const WelcomeScreen({super.key});

  /// Welcome's own, wider side margin (the design's 28 px) -- the mark, the
  /// headline and both exits all hang off the same left edge.
  static const double _sideInset = 28;

  /// The mark's size once it has landed here from the splash tile.
  static const double _markSize = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final bg = theme.colorScheme.surfaceContainer;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // The landing spot for the splash's Hero: without a matching
            // tag here, the "mark flies to Welcome" moment was only a fade.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sideInset,
                AppSpacing.gap,
                _sideInset,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Hero(
                  tag: BasketMark.heroTag,
                  child: BasketMark(
                    size: _markSize,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _ListPreviewScene(t: t, backgroundColor: bg),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sideInset,
                0,
                _sideInset,
                AppSpacing.gapSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.welcome.headline,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    t.welcome.subhead,
                    style: AppTextStyles.secondary.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  OnboardingPrimaryButton(
                    label: t.welcome.getStarted,
                    onPressed: () => context.go(Routes.onboarding),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(Routes.join),
                      child: Text(
                        t.welcome.haveInviteCode,
                        style: AppTextStyles.secondaryStrong.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The illustration area: a tilted card mocking up a real list, an activity
/// bubble floating over it, faded into [backgroundColor] at the fold.
class _ListPreviewScene extends StatelessWidget {
  const _ListPreviewScene({required this.t, required this.backgroundColor});

  final Translations t;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 34,
            right: -46,
            top: 40,
            child: Transform.rotate(
              angle: -4 * math.pi / 180,
              child: _ListPreviewCard(t: t),
            ),
          ),
          Positioned(
            left: 20,
            top: 4,
            child: _ActivityBubble(t: t),
          ),
          // Blends the card's crop into the headline section below it,
          // rather than the fold reading as a hard clip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0),
                      backgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPreviewCard extends StatelessWidget {
  const _ListPreviewCard({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      (t.welcome.sampleItem1, AppColors.info, true),
      (t.welcome.sampleItem2, AppColors.swatchOrange, false),
      (t.welcome.sampleItem3, AppColors.success, false),
      (t.welcome.sampleItem4, AppColors.info, false),
    ];

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        // theme.colorScheme.surface, not AppColors.surfaceLight -- this
        // mockup card was hardcoded to the light-mode surface regardless of
        // the active theme, which is why it stayed bright white in dark
        // mode instead of following the screen around it.
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        // surfaceDark and this screen's own subtleDark background are only
        // a couple of RGB units apart -- a shadow alone (which barely reads
        // against a dark background anyway) left the card blending into
        // whatever was behind it. A hairline border is what the app already
        // reaches for elsewhere to bound a surface regardless of how close
        // its fill sits to what's behind it (see OutlinedButton/input
        // fields in AppTheme._build, same AppColors.border* tokens).
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.welcome.sampleListName.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final (index, row) in rows.indexed) ...[
            // No explicit colour: Divider falls back to the theme's own
            // DividerThemeData (already correctly light/dark-aware in
            // AppTheme._build), where a hardcoded AppColors.dividerLight
            // would not have been.
            if (index > 0) const Divider(height: 1),
            _PreviewRow(
              name: row.$1,
              dotColor: row.$2,
              checked: row.$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.name,
    required this.dotColor,
    required this.checked,
  });

  final String name;
  final Color dotColor;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A checked circle's fill and its own checkmark are an on-surface/
    // surface pair, not a fixed ink/white pair -- in dark mode onSurface is
    // white, so a hardcoded white checkmark on it would vanish the same way
    // the activity bubble's text did against a hardcoded-light card.
    final checkedFill = theme.colorScheme.onSurface;
    final checkedGlyph = theme.colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (checked)
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: checkedFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.check, size: 11, color: checkedGlyph),
            )
          else
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
          const SizedBox(width: 11),
          Container(
            width: AppSizes.shopDot,
            height: AppSizes.shopDot,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 11),
          Text(
            name,
            style: AppTextStyles.body.copyWith(
              color: checked
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
              decoration: checked ? TextDecoration.lineThrough : null,
              decorationColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBubble extends StatelessWidget {
  const _ActivityBubble({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    // Whoever added the sample item -- a stand-in household member, not a
    // real user. Localised like the rest of the mock list, so the bubble
    // reads as a plausible housemate in every locale.
    final sampleMemberName = t.welcome.sampleMemberName;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        // theme.colorScheme.surface, not AppColors.surfaceLight -- the
        // actual bug report: this stayed hardcoded light regardless of
        // theme, while the activity text beside it (no explicit colour,
        // AppTextStyles.captionStrong) correctly inherited the ambient,
        // theme-aware text colour -- white in dark mode. A card that never
        // leaves light mode plus text that correctly follows dark mode is
        // exactly how "white text on a white card" (the actual symptom
        // reported) happens: two colours from two different sources that
        // silently stopped agreeing the moment the theme changed.
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        // Same reasoning as _ListPreviewCard's border: surfaceDark sits too
        // close to this screen's own background to read as "a card" from
        // fill colour and a barely-visible-on-dark shadow alone.
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.success,
            child: Text(
              initialFor(sampleMemberName),
              style: AppTextStyles.captionStrong.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            t.welcome.sampleActivity(
              name: sampleMemberName,
              item: t.welcome.sampleItem2,
            ),
            style: AppTextStyles.captionStrong,
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Welcome', size: previewPhone)
Widget welcomeScreenPreview() => previewApp(const WelcomeScreen());
