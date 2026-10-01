import 'package:flutter/material.dart';

/// Lets a step's [child] -- a [Column] that pins its button to the bottom
/// with a [Spacer] -- fill the screen when there is room, and scroll when
/// there is not.
///
/// A bare Column with a Spacer overflows the moment its height shrinks below
/// its content: a small phone with the keyboard up, or mid-transition while
/// the wizard's footer grows back in under the outgoing step.
/// [SliverFillRemaining] with `hasScrollBody: false` is the standard way to
/// get both behaviours from one layout.
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
