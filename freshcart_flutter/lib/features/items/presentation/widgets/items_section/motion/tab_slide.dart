import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_switch_motion.dart';

/// One row's part of [TabSwitchMotion]: its own 220ms slice of the shared
/// animation, starting [step] later than the row above.
class TabSlide extends StatelessWidget {
  const TabSlide({super.key, required this.position, required this.child});

  /// The row's place in the list, for its delay.
  final int position;
  final Widget child;

  static const Duration step = Duration(milliseconds: 24);

  /// Rows below this all start together, so a long list isn't still
  /// arriving half a second later.
  static const int maxStagger = 8;
  static const double _travel = 28;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TabSwitchScope>();
    final controller = scope?.notifier;
    if (scope == null || controller == null || controller.isCompleted) {
      return child;
    }
    final total = controller.duration!.inMicroseconds;
    final start = (step * position.clamp(0, maxStagger)).inMicroseconds;
    final t = Interval(
      start / total,
      (start + AppMotion.listSlide.inMicroseconds) / total,
      curve: AppMotion.enter,
    ).transform(controller.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(scope.direction * _travel * (1 - t), 0),
        child: child,
      ),
    );
  }
}
