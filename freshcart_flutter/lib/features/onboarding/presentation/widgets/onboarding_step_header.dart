import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';

/// The title and one-line explanation every onboarding and join step opens
/// with.
///
/// One widget rather than each step styling its own, because they had
/// drifted to four different title sizes across five screens -- the design
/// draws them all identically, and the steps only read as one wizard if they
/// actually are identical.
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
          child: Text(title, style: theme.textTheme.headlineLarge),
        ),
        const SizedBox(height: AppSpacing.gapSmall),
        OnboardingEntrance(
          index: 1,
          child: Text(subtitle, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

@Preview(group: 'Onboarding', name: 'Step header', size: Size(393, 160))
Widget onboardingStepHeaderPreview() => previewPiece(
  const OnboardingStepHeader(
    title: 'What should we call you?',
    subtitle: 'This is how your household sees you on shared lists.',
  ),
);
