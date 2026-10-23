import 'package:flutter/animation.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// The hold menu's v3 entrance and exit, as animations cut from two
/// controllers: [open] (0 → 1 as the menu arrives) and [close] (0 → 1 as it
/// leaves).
///
/// On open (v3 `openMenu`, all in ms from the hold):
/// - 0–340: the card travels from the row to where it's placed, opacity .5
///   → 1, scale .97 → 1.02 by 55% of the way, then settles to 1;
/// - 90–390: the body under the row unrolls downwards (a paint clip);
/// - 150 + 40·i: option i falls 6px into place, 220ms each.
///
/// On close: 160ms, the card fades out and shrinks to .97.
///
/// Reduced motion: a 120ms fade in; everything else is already in place.
/// Closing is instant.
class ItemMenuMotion {
  ItemMenuMotion({
    required this.open,
    required this.close,
    required this.reduced,
  });

  final Animation<double> open;
  final Animation<double> close;
  final bool reduced;

  /// How long [open] runs: until the last option has landed.
  static const Duration openDuration = Duration(
    milliseconds: _itemsStart + (_options - 1) * _itemStep + _itemMs,
  );
  static const Duration closeDuration = Duration(milliseconds: 160);

  static const int _liftMs = 340;
  static const int _bodyStart = 90;
  static const int _bodyMs = 300;
  static const int _itemsStart = 150;
  static const int _itemStep = 40;
  static const int _itemMs = 220;

  /// Edit, Move, Rearrange, Delete, Select more.
  static const int _options = 5;

  /// Where the quantity becomes a stepper: early in the lift, so the swap
  /// happens while the card is still moving and reads as part of it.
  static const int _stepperAtMs = 150;

  static double _at(int ms) => ms / openDuration.inMilliseconds;

  Animation<double> _slice(int startMs, int lengthMs, Curve curve) =>
      CurvedAnimation(
        parent: open,
        curve: Interval(_at(startMs), _at(startMs + lengthMs), curve: curve),
      );

  late final Animation<double> _lift = _slice(0, _liftMs, Curves.linear);

  /// Two easing segments, like a two-step WAAPI keyframe animation: the
  /// first 55% overshoots to its peak, the rest settles.
  late final Animation<double> _scaleIn = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: .97,
        end: 1.02,
      ).chain(CurveTween(curve: AppMotion.enter)),
      weight: 55,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.02,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.enter)),
      weight: 45,
    ),
  ]).animate(_lift);

  late final Animation<double> _arrive = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.enter)),
      weight: 55,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
  ]).animate(_lift);

  late final Animation<double> _closeCurve = CurvedAnimation(
    parent: close,
    curve: Curves.easeIn,
  );

  /// 0 at the row, 1 at the card's place.
  Animation<double> get travel => reduced ? kAlwaysCompleteAnimation : _arrive;

  /// The card's scale, opening then closing.
  double get scale {
    if (reduced) return 1;
    final closing = 1 - .03 * _closeCurve.value;
    return _scaleIn.value * closing;
  }

  /// The card's opacity, opening then closing.
  double get opacity {
    final opening = reduced ? open.value : .5 + .5 * _arrive.value;
    return opening * (1 - _closeCurve.value);
  }

  /// How much of the body (the options under the row) is uncovered, 0 → 1
  /// from the top down.
  late final Animation<double> body = reduced
      ? kAlwaysCompleteAnimation
      : _slice(_bodyStart, _bodyMs, AppMotion.emphasized);

  /// Option [index]'s entrance, 0 → 1.
  Animation<double> option(int index) => reduced
      ? kAlwaysCompleteAnimation
      : _slice(_itemsStart + index * _itemStep, _itemMs, AppMotion.enter);

  /// Whether the quantity has turned into the stepper yet.
  bool get showsStepper => reduced || open.value >= _at(_stepperAtMs);
}
