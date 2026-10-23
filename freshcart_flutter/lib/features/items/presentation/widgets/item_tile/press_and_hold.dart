import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Tap or hold as one gesture: lifting the finger early calls [onTap];
/// holding for [holdDuration] calls [onHold] instead.
///
/// Done with timers, not a long-press recognizer, so tap and hold don't
/// compete, and the child can shrink a little halfway as a hint to keep
/// holding (not under reduced motion: whatever [onHold] shows is hint
/// enough).
class PressAndHold extends StatefulWidget {
  /// Wraps [child] in the gesture.
  const PressAndHold({
    required this.onTap,
    required this.onHold,
    required this.child,
    super.key,
  });

  /// How long a press must last to count as a hold.
  static const Duration holdDuration = Duration(milliseconds: 450);

  final VoidCallback onTap;
  final VoidCallback onHold;
  final Widget child;

  @override
  State<PressAndHold> createState() => _PressAndHoldState();
}

class _PressAndHoldState extends State<PressAndHold>
    with SingleTickerProviderStateMixin {
  static const Duration _hintDelay = Duration(milliseconds: 300);

  late final AnimationController _scale = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: 1,
  );
  Timer? _holdTimer;
  Timer? _hintTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _hintTimer?.cancel();
    _scale.dispose();
    super.dispose();
  }

  void _settle() => _scale.animateTo(1, curve: AppMotion.pop);

  void _onPressStart() {
    _holdTimer?.cancel();
    _holdTimer = Timer(PressAndHold.holdDuration, () {
      _hintTimer?.cancel();
      _settle();
      widget.onHold();
    });
    _hintTimer?.cancel();
    if (AppMotion.reduced(context)) return;
    _hintTimer = Timer(
      _hintDelay,
      () => _scale.animateTo(AppMotion.pressScale),
    );
  }

  void _onPressCancel() {
    _holdTimer?.cancel();
    _hintTimer?.cancel();
    _settle();
  }

  void _onPressEnd() {
    _hintTimer?.cancel();
    _settle();
    // Hold timer still running: the finger lifted early, so it's a tap. If
    // it already fired, the hold was handled and this lift means nothing.
    if (_holdTimer?.isActive ?? false) {
      _holdTimer!.cancel();
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _onPressStart(),
    onTapCancel: _onPressCancel,
    onTapUp: (_) => _onPressEnd(),
    child: AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    ),
  );
}
