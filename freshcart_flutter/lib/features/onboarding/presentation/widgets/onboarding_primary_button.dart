import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';

/// The one primary action on every Getting-in screen: Get started,
/// Continue, Join list, Start my list.
///
/// An [ElevatedButton] because that is the button `AppTheme` styles as the
/// design's ink, full-width, 52 px primary. The flow had drifted into four
/// different primaries -- a restyled [FilledButton] on Welcome, M3-default
/// [FilledButton]s on Join and Invite, this one in the wizard -- and the
/// first screens are exactly where a mismatch is most visible.
///
/// While [isLoading], the label swaps for a spinner and presses are ignored,
/// so a slow network cannot be double-submitted into two lists.
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
          // Inside the button, so IconTheme already carries the button's
          // own foreground colour -- the spinner matches the label it
          // replaces in both themes without naming a colour here.
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
