import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';

/// Padding around every onboarding and join step (design v3: 24px at the
/// sides, 14px below the top bar).
const EdgeInsets onboardingStepPadding = EdgeInsets.fromLTRB(
  AppSpacing.xxl,
  14,
  AppSpacing.xxl,
  AppSpacing.screen,
);

/// The title and short explanation at the top of every onboarding and join
/// step. One widget, so they all look the same.
///
/// Design v3: a 30/700 title and a 16px muted subtitle, 10px apart.
class OnboardingStepHeader extends StatelessWidget {
  /// Creates the header.
  const OnboardingStepHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingEntrance(
          index: 0,
          child: Text(
            title,
            style: AppTextStyles.largeTitle.copyWith(
              fontSize: 30,
              height: 36 / 30,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OnboardingEntrance(
          index: 1,
          child: Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              height: 23 / 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
