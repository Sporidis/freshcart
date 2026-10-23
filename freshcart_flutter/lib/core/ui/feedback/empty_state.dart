import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';

/// What a screen shows when there's nothing in it ("No items yet").
///
/// Every empty screen uses this, so they all look the same: an icon, a
/// title, one line of text, and at most one button, all centred.
///
/// It fades in, so switching to an empty tab doesn't look like a flash.
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

  /// The icon. 22px, inside a 48px box.
  final IconData icon;

  /// A short line saying what's missing.
  final String title;

  /// One line saying what the user can do about it.
  final String body;

  /// Colours the icon with a shop's colour. Dark ink if null.
  final Color? tint;

  /// One button. If you need more, use [footer].
  final Widget? action;

  /// Extra buttons. Only used when there are no lists at all, because then
  /// the user needs more than one way forward.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    // Icon box border at 12% opacity, icon at 22%, as in the design.
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

/// Fades the child in and slides it up a little, once, when first shown.
///
/// Uses [AppMotion.standard], the closest existing duration to the design's
/// 300 ms.
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
              // SlideTransition moves by a fraction of the child's height,
              // so this works out to about 12 px.
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: widget.child,
            ),
    );
  }
}
