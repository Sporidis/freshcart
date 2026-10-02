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

/// The first screen a new user sees. Two buttons: "Get started" and "I have
/// an invite code".
///
/// The top shows a tilted picture of a shopping list, so the user sees what
/// the app does before reading anything.
class WelcomeScreen extends ConsumerWidget {
  /// Creates the welcome screen.
  const WelcomeScreen({super.key});

  /// Side margin for this screen (28 px, wider than elsewhere). Logo, title
  /// and buttons all line up on it.
  static const double _sideInset = 28;

  /// The logo's size here (after flying in from the splash screen).
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
            // Where the splash logo lands. The Hero tag must match the
            // splash screen's, or it would just fade instead of fly.
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.welcome.subhead,
                    style: AppTextStyles.secondary.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  OnboardingPrimaryButton(
                    label: t.welcome.getStarted,
                    onPressed: () => context.go(Routes.onboarding),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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

/// The picture at the top: a tilted fake shopping list, with a small
/// "someone added this" bubble on it. Fades into [backgroundColor] at the
/// bottom.
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
          // A fade at the bottom, so the picture doesn't end with a hard
          // edge.
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
        // Theme colour (not a fixed light colour), so the card is dark in
        // dark mode.
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.celebration),
        // A thin border, because in dark mode the card and the background
        // are almost the same colour. A shadow alone isn't visible enough.
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
            // No colour set, so it uses the theme's divider colour (which
            // works in dark mode too).
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
    // Theme colours for the circle and its checkmark, so the checkmark is
    // still visible in dark mode (a fixed white one would vanish).
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
    // A made-up housemate's name, translated per language.
    final sampleMemberName = t.welcome.sampleMemberName;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        // Thin border, same reason as the list card above.
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
