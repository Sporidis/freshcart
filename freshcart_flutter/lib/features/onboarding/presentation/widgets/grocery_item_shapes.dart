import 'package:flutter/material.dart';

/// Positions a grocery-item shape along its thrown-in-from-off-screen [path],
/// tumbling per [rotate] as it flies, settling at [bottom].
class FallingItem extends StatelessWidget {
  const FallingItem({
    super.key,
    required this.path,
    required this.rotate,
    required this.bottom,
    required this.child,
  });

  /// Horizontal offset from center plus vertical offset from [bottom].
  final Animation<Offset> path;
  final Animation<double> rotate;
  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([path, rotate]),
      builder: (context, builtChild) => Positioned(
        bottom: bottom,
        left: 110 + path.value.dx,
        child: Transform.translate(
          offset: Offset(0, path.value.dy),
          child: Transform.rotate(angle: rotate.value, child: builtChild),
        ),
      ),
      child: child,
    );
  }
}

/// A round fruit with a small leaf — built from a circle and a rounded rect.
class AppleShape extends StatelessWidget {
  const AppleShape({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 6,
            child: Container(
              width: 36,
              height: 34,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 0,
            left: 18,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 14,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A milk carton — a white body with a colored roof strip.
class CartonShape extends StatelessWidget {
  const CartonShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF5C6BC0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        Container(
          width: 26,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A loaf of bread — a single rounded rect in a warm tone.
class BreadShape extends StatelessWidget {
  const BreadShape({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
