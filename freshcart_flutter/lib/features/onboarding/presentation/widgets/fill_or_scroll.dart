import 'package:flutter/material.dart';

/// Fills the screen when there's room, and scrolls when there isn't.
///
/// For a [Column] that uses a [Spacer] to push its button to the bottom.
/// A plain Column like that overflows when the screen gets too small (for
/// example a small phone with the keyboard open). [SliverFillRemaining]
/// with `hasScrollBody: false` is the standard fix.
class FillOrScroll extends StatelessWidget {
  /// Wraps [child].
  const FillOrScroll({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverFillRemaining(hasScrollBody: false, child: child),
        ),
      ],
    );
  }
}
