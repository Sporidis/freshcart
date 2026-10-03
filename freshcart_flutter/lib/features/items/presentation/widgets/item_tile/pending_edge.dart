import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// The "not confirmed yet" mark on a row changed offline (design v3, Flow
/// 07): a dashed line down its left edge. No colour, no icon: the row
/// works as normal; this only says the server hasn't got it yet.
///
/// When the change reaches the server, the line fades out, [index] × 40ms
/// after the moment it synced, so a batch of rows resolves top to bottom.
/// It appears straight away.
class PendingEdge extends StatefulWidget {
  const PendingEdge({
    required this.pending,
    required this.child,
    this.index = 0,
    super.key,
  });

  /// Whether the row's change is still waiting in the offline queue.
  final bool pending;

  /// The row's place in the list, for the stagger as the lines resolve.
  final int index;

  final Widget child;

  /// v3: 40ms between rows as their lines resolve.
  static const Duration _step = Duration(milliseconds: 40);

  /// Rows past this resolve together, so a long list isn't still ticking
  /// away a second later.
  static const int _maxStagger = 8;

  @override
  State<PendingEdge> createState() => _PendingEdgeState();
}

class _PendingEdgeState extends State<PendingEdge> {
  late bool _shown = widget.pending;
  Timer? _resolve;

  @override
  void didUpdateWidget(PendingEdge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pending == oldWidget.pending) return;
    _resolve?.cancel();
    // Assigned, not setState: a rebuild always follows didUpdateWidget.
    if (widget.pending) {
      _shown = true;
      return;
    }
    final delay = AppMotion.reduced(context)
        ? Duration.zero
        : PendingEdge._step * widget.index.clamp(0, PendingEdge._maxStagger);
    if (delay == Duration.zero) {
      _shown = false;
      return;
    }
    _resolve = Timer(delay, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _resolve?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 9,
          top: 8,
          bottom: 8,
          width: 1.5,
          // Only a mark: taps, swipes and holds go to the row.
          child: IgnorePointer(
            child: AnimatedOpacity(
              key: const ValueKey('pending-edge'),
              opacity: _shown ? 1 : 0,
              duration: AppMotion.durationFor(context, AppMotion.standard),
              child: CustomPaint(
                painter: _DashedLine(color: ink.withValues(alpha: .35)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A vertical dashed line filling its box: 4px dashes, 3px gaps.
class _DashedLine extends CustomPainter {
  const _DashedLine({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.butt;
    final x = size.width / 2;
    for (var y = 0.0; y < size.height; y += _dash + _gap) {
      final end = (y + _dash).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => color != oldDelegate.color;
}

@Preview(group: 'Items', name: 'Pending edge', size: Size(393, 140))
Widget pendingEdgePreview() => previewPiece(
  const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      PendingEdge(
        pending: true,
        child: SizedBox(height: 58, child: Center(child: Text('Olive oil'))),
      ),
      PendingEdge(
        pending: false,
        child: SizedBox(height: 58, child: Center(child: Text('Bananas'))),
      ),
    ],
  ),
);
