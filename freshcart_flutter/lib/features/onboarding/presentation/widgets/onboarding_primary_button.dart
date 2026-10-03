import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';

/// The main button on the welcome, onboarding and join screens ("Get
/// started", "Continue", "Join list", "Start my list").
///
/// It's an [ElevatedButton], because our theme styles that one as the big
/// dark full-width button.
///
/// While [isLoading], it shows a spinner and ignores taps, so a slow
/// network can't cause a double save (two lists).
class OnboardingPrimaryButton extends StatelessWidget {
  /// Creates the button.
  const OnboardingPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  static const double _spinnerSize = 20;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          // No colour set: inside the button it automatically gets the
          // button's text colour.
          ? Builder(
              builder: (context) => SizedBox.square(
                dimension: _spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: IconTheme.of(context).color,
                ),
              ),
            )
          : Text(label),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Primary button', size: Size(393, 160))
Widget onboardingPrimaryButtonPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      OnboardingPrimaryButton(label: 'Continue', onPressed: () {}),
      OnboardingPrimaryButton(
        label: 'Continue',
        onPressed: () {},
        isLoading: true,
      ),
    ],
  ),
);
