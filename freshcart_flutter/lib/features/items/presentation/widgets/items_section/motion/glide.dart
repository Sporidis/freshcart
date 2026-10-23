import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_switch_motion.dart';

/// Moves a row smoothly when the list around it changes (the FLIP
/// technique): remember where the row was, and when it ends up somewhere
/// else, start it at the old place and animate to the new one.
///
/// One mechanism for every reflow: ticked rows gliding down into Done,
/// unticked ones gliding back up, and the rows around them closing the gap.
/// It works because rows are keyed, so Flutter keeps this State when a row
/// changes position in the list.
///
/// Positions are measured in the list's content (screen position plus
/// scroll offset), so scrolling never starts a glide. During a tab switch
/// the rows have their own slide, so this only takes note.
class Glide extends StatefulWidget {
  const Glide({
    super.key,
    required this.duration,
    required this.delay,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget child;

  @override
  State<Glide> createState() => _GlideState();
}

class _GlideState extends State<Glide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  late Animation<double> _progress = _controller;

  /// Where the row was last measured, in content coordinates.
  double? _lastY;

  /// How far above (negative: below) its real place the glide starts.
  double _from = 0;

  /// Read in [build]: post-frame callbacks shouldn't look up inherited
  /// widgets.
  bool _reduced = false;
  AnimationController? _tabs;

  /// Rows "lift" a little while they travel, like being picked up.
  static const double _lift = .015;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _offset => _from * (1 - _progress.value);

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final scroll = Scrollable.maybeOf(context)?.position;
    final y =
        box.localToGlobal(Offset.zero).dy +
        (scroll != null && scroll.hasPixels ? scroll.pixels : 0);
    final last = _lastY;
    _lastY = y;
    if (last == null || (y - last).abs() < 1) return;

    if (_reduced || (_tabs?.isAnimating ?? false)) return;

    // Start from where it was on screen, including any glide in progress.
    _from = last - y + _offset;
    final total = widget.delay + widget.duration;
    _controller.duration = total;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.emphasized,
      ),
    );
    unawaited(_controller.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    _reduced = AppMotion.reduced(context);
    _tabs = context
        .dependOnInheritedWidgetOfExactType<TabSwitchScope>()
        ?.notifier;
    // After layout, see whether this row ended up somewhere new.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (!_controller.isAnimating) return child!;
        final t = _progress.value;
        return Transform.translate(
          offset: Offset(0, _offset),
          child: Transform.scale(
            scale: 1 + _lift * math.sin(math.pi * t),
            child: child,
          ),
        );
      },
    );
  }
}
