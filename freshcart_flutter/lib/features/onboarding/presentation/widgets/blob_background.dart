import 'dart:ui';

import 'package:flutter/material.dart';

/// A soft, heavily-blurred color circle used to give a background depth.
class Blob extends StatelessWidget {
  const Blob({
    super.key,
    required this.color,
    required this.size,
    required this.alignment,
  });

  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
