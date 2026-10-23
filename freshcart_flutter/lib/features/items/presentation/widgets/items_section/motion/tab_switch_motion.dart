import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_slide.dart';

/// Slides the rows in from the side of the tab you moved to (design v3:
/// 28px, 220ms, rows 24ms apart).
///
/// One controller for the whole list, shared through [TabSwitchScope].
/// A row that mounts later (a newly added item) finds the animation already
/// finished and simply appears; one animation per row couldn't tell the
/// two cases apart.
class TabSwitchMotion extends StatefulWidget {
  const TabSwitchMotion({
    super.key,
    required this.filter,
    required this.order,
    required this.child,
  });

  final ShopId? filter;

  /// The tabs in strip order (null is All), to tell left from right.
  final List<ShopId?> order;
  final Widget child;

  @override
  State<TabSwitchMotion> createState() => _TabSwitchMotionState();
}

class _TabSwitchMotionState extends State<TabSwitchMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.listSlide + TabSlide.step * TabSlide.maxStagger,
    value: 1,
  );
  double _direction = 1;

  @override
  void didUpdateWidget(covariant TabSwitchMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter == oldWidget.filter) return;
    if (AppMotion.reduced(context)) return;
    final from = widget.order.indexOf(oldWidget.filter);
    final to = widget.order.indexOf(widget.filter);
    // Moving right, the rows come in from the right.
    _direction = to >= from ? 1 : -1;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabSwitchScope(
    controller: _controller,
    direction: _direction,
    child: widget.child,
  );
}

class TabSwitchScope extends InheritedNotifier<AnimationController> {
  const TabSwitchScope({
    super.key,
    required AnimationController controller,
    required this.direction,
    required super.child,
  }) : super(notifier: controller);

  /// 1 when the rows enter from the right, -1 from the left.
  final double direction;
}
