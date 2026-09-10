import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.subtleDark : AppColors.subtleLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Hero(
                    tag: BasketMark.heroTag,
                    child: BasketMark(size: 24, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ListPreviewScene(t: t, backgroundColor: bg),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.welcome.headline, style: AppTextStyles.largeTitle),
                  const SizedBox(height: 9),
                  Text(
                    t.welcome.subhead,
                    style: AppTextStyles.secondary.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: FilledButton(
                      onPressed: () => context.go(Routes.onboarding),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                        textStyle: AppTextStyles.bodyStrong,
                      ),
                      child: Text(t.welcome.getStarted),
                    ),
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
              angle: -4 * 3.14159265 / 180,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
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
              color: AppColors.textFaintLight,
            ),
          ),
          const SizedBox(height: 10),
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              const Divider(height: 1, color: AppColors.dividerLight),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          if (checked)
            Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            )
          else
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1.5),
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
              color: checked ? AppColors.textFaintLight : AppColors.ink,
              decoration: checked ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textFaintLight,
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
    // Whoever added the sample item — a stand-in household member, not a
    // real user, so this is the one place in the app a display name is
    // hardcoded rather than read from a session.
    const sampleMemberName = 'koliiin';

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadii.pill),
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
          const CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.success,
            child: Text(
              'K',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
