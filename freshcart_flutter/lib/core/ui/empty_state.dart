import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// The one empty-state layout, used by every empty screen in the app.
///
/// The design's rule (Motion spec §11) is that all four empties are the same
/// centred stack — a light line-illustration slot, a title, one line of
/// secondary copy, and *at most* one action — so they are one widget rather
/// than four look-alikes that drift apart.
///
/// It fades and rises in because switching to an empty shop tab would
/// otherwise be a blank flash.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.tint,
    this.action,
    this.footer,
    super.key,
  });

  /// The line illustration. Rendered at 22px inside a 48px slot.
  final IconData icon;

  /// One short line naming what is missing.
  final String title;

  /// One line of copy saying what to do about it.
  final String body;

  /// Tints the illustration to a shop's colour. Ink when null.
  final Color? tint;

  /// At most one action. More than one belongs in [footer].
  final Widget? action;

  /// The exception to "at most one action": the no-lists empty offers two,
  /// because a dead end there has no other way out.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    // 12% ink for the slot border, 22% for the glyph — the design's weights.
    final slotBorder = (tint ?? ink).withValues(
      alpha: tint == null ? 0.13 : 0.35,
    );
    final glyph = (tint ?? ink).withValues(alpha: tint == null ? 0.22 : 0.5);

    return _FadeAndRise(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: slotBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Icon(icon, size: 22, color: glyph),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 7),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                action!,
              ],
              if (footer != null) ...[
                const SizedBox(height: 14),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and rises its child in once, on first build.
///
/// The spec asks for 300 ms, which is not one of the six motion tokens it also
/// insists everything is built from. [AppMotion.standard] is the nearest token
/// and the rule about the token set is the stronger of the two, so this uses
/// it rather than introducing a seventh duration.
class _FadeAndRise extends StatefulWidget {
  const _FadeAndRise({required this.child});

  final Widget child;

  @override
  State<_FadeAndRise> createState() => _FadeAndRiseState();
}

class _FadeAndRiseState extends State<_FadeAndRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );
    return FadeTransition(
      opacity: animation,
      child: AppMotion.reduced(context)
          ? widget.child
          : SlideTransition(
              // 12 px of travel, expressed as a fraction of the child's height
              // by the enclosing SlideTransition's own sizing.
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: widget.child,
            ),
    );
  }
}
