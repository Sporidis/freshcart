import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Shakes its child once each time [errorText] becomes non-null.
///
/// The design's §07 rule: ±6 px, four oscillations over 320 ms, with
/// `HapticFeedback.vibrate()`. The shake is not decoration — it is what draws
/// the eye back to a field the user has already looked away from.
///
/// [shake] exists because not every inline error deserves one. A typo earns
/// "look again"; an expired invite or an unreachable server is not the user's
/// mistake, and shaking at them for it is just rude.
class ShakeOnError extends ConsumerStatefulWidget {
  /// Wraps [child].
  const ShakeOnError({
    required this.errorText,
    required this.child,
    this.shake = true,
    super.key,
  });

  /// The current error, or null when the field is clean.
  final String? errorText;

  /// Whether a new error should shake, or merely appear.
  final bool shake;

  /// The field being guarded.
  final Widget child;

  @override
  ConsumerState<ShakeOnError> createState() => _ShakeOnErrorState();
}

class _ShakeOnErrorState extends ConsumerState<ShakeOnError>
    with SingleTickerProviderStateMixin {
  /// Four oscillations over 320 ms.
  static const int _oscillations = 4;
  static const double _amplitude = 6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(ShakeOnError oldWidget) {
    super.didUpdateWidget(oldWidget);
    final appeared = widget.errorText != null && oldWidget.errorText == null;
    final changed =
        widget.errorText != null && widget.errorText != oldWidget.errorText;
    if (!(appeared || changed)) return;
    if (!widget.shake || AppMotion.reduced(context)) return;
    if (ref.read(hapticsControllerProvider).value ?? true) {
      unawaited(HapticFeedback.vibrate());
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      if (!_controller.isAnimating) return child!;
      // A decaying sine: the last oscillation is smaller than the first, so it
      // settles rather than stopping dead.
      final decay = 1 - Curves.easeOut.transform(_controller.value);
      final offset =
          math.sin(_controller.value * _oscillations * 2 * math.pi) *
          _amplitude *
          decay;
      return Transform.translate(offset: Offset(offset, 0), child: child);
    },
    child: widget.child,
  );
}
