import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Design v3's one shared-element moment: when you pick a list in the
/// drawer, its name flies from the drawer row into the header title.
///
/// The drawer isn't a route, so `Hero` can't do this (decisions.md #106).
/// Instead the drawer measures where the name was ([from]) and passes it
/// along with the navigation (go_router's `extra`). The new screen offers
/// it to its header through [ListTitleFlight.scope], and the header flies a
/// copy of the name there with [flyListTitle] before showing its own.
class ListTitleFlight {
  const ListTitleFlight({required this.from});

  /// Where the name sat in the drawer, in global coordinates.
  final Rect from;

  /// Makes [flight] available to the header title below.
  static Widget scope({
    required ListTitleFlight? flight,
    required Widget child,
  }) => _ListTitleFlightScope(flight: flight, child: child);

  /// The flight to play into this screen's title, if it was opened from the
  /// drawer. Read once; it doesn't change.
  static ListTitleFlight? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ListTitleFlightScope>()?.flight;
}

class _ListTitleFlightScope extends InheritedWidget {
  const _ListTitleFlightScope({required this.flight, required super.child});

  final ListTitleFlight? flight;

  @override
  bool updateShouldNotify(_ListTitleFlightScope oldWidget) =>
      flight != oldWidget.flight;
}

/// Flies [text] in [style] from [from] to [to] (global rects), above
/// everything, and completes when it has landed.
///
/// v3: 380ms on the emphasized curve, growing from the drawer's size (16 of
/// the header's 26px) to full size, scaled from its top-left corner so the
/// first letter leads.
Future<void> flyListTitle(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required Rect from,
  required Rect to,
}) {
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TitleFlight(
      text: text,
      style: style,
      from: from,
      to: to,
      onLanded: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return done.future;
}

class _TitleFlight extends StatefulWidget {
  const _TitleFlight({
    required this.text,
    required this.style,
    required this.from,
    required this.to,
    required this.onLanded,
  });

  final String text;
  final TextStyle style;
  final Rect from;
  final Rect to;
  final VoidCallback onLanded;

  @override
  State<_TitleFlight> createState() => _TitleFlightState();
}

class _TitleFlightState extends State<_TitleFlight>
    with SingleTickerProviderStateMixin {
  /// The drawer's title size over the header's (v3: 16/26).
  static const double _startScale = 16 / 26;

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: AppMotion.sharedTitle,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _flight,
    curve: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_flight.forward().whenComplete(widget.onLanded));
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        final at = Offset.lerp(widget.from.topLeft, widget.to.topLeft, t)!;
        final scale = _startScale + (1 - _startScale) * t;
        return Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: child,
              ),
            ),
          ],
        );
      },
      // Material for the text's default style; transparent, so only the
      // letters show.
      child: Material(
        type: MaterialType.transparency,
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: widget.style,
        ),
      ),
    ),
  );
}
