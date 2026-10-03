import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// How a new item's row arrives (design flow 09, v3 timings):
/// - it drops in from 6px above, fading in and growing from 98%, 260ms;
/// - its background flashes the shop colour at 8%, holds 200ms, then
///   fades over 400ms, so it reads as landing on the list;
/// - if [mine] (you added it), a light haptic as it lands.
///
/// Plays when the row is built with [isNew], or when [isNew] turns true.
/// Which items are new is decided from the data (`itemArrivals`), not here:
/// a row is also built on first load, tab switches and scrolling.
///
/// Reduced motion: no drop or growth, just the fade and the flash.
class ArrivalFlash extends ConsumerStatefulWidget {
  const ArrivalFlash({
    required this.isNew,
    required this.child,
    this.color,
    this.mine = false,
    super.key,
  });

  final bool isNew;

  /// The row's shop colour, or null for no shop (the flash uses ink).
  final Color? color;

  /// Whether the signed-in user added it (only then the haptic).
  final bool mine;

  final Widget child;

  @override
  ConsumerState<ArrivalFlash> createState() => _ArrivalFlashState();
}

class _ArrivalFlashState extends ConsumerState<ArrivalFlash>
    with SingleTickerProviderStateMixin {
  static const int _enterMs = 260;
  static const int _holdMs = 200;
  static const int _fadeMs = 400;
  static const int _totalMs = _holdMs + _fadeMs;

  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
    value: 1,
  );
  late final Animation<double> _enter = CurvedAnimation(
    parent: _arrive,
    curve: const Interval(0, _enterMs / _totalMs, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _flash = CurvedAnimation(
    parent: _arrive,
    curve: const Interval(_holdMs / _totalMs, 1, curve: Curves.easeOut),
  );

  Timer? _landed;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.isNew) _play();
  }

  @override
  void didUpdateWidget(ArrivalFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNew && !oldWidget.isNew) _play();
  }

  void _play() {
    unawaited(_arrive.forward(from: 0));
    if (!widget.mine) return;
    _landed?.cancel();
    _landed = Timer(const Duration(milliseconds: _enterMs), () {
      if (mounted) ref.haptic(HapticFeedback.lightImpact);
    });
  }

  @override
  void dispose() {
    _landed?.cancel();
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final tint = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _arrive,
      child: widget.child,
      builder: (context, child) {
        // The same widgets whether playing or done (only the values
        // change): swapping in the bare child when done would rebuild the
        // row's state (its hold menu, its animations) from scratch.
        final enter = _enter.value;
        final flash = .08 * (1 - _flash.value);
        return DecoratedBox(
          decoration: BoxDecoration(color: tint.withValues(alpha: flash)),
          child: Opacity(
            opacity: enter,
            child: Transform.translate(
              offset: Offset(0, reduced ? 0 : -6 * (1 - enter)),
              child: Transform.scale(
                scale: reduced ? 1 : .98 + .02 * enter,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
