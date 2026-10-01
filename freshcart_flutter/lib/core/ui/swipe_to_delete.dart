import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The app's one swipe-to-delete (Motion spec §10), for item rows and shop
/// rows alike.
///
/// - Right-to-left only; left-to-right stays free for a future "move".
/// - Commits at 40% of the row's width.
/// - A red background whose trash icon grows from 70% to full size over the
///   first 30% of the drag, then pops to 115% the moment the threshold is
///   crossed -- with `mediumImpact`, the spec's pre-commit warning.
/// - Below the threshold the row springs back (`Dismissible`'s own recoil,
///   decisions #52); a committed row collapses over 220 ms.
///
/// [onSwipe] decides what a committed swipe means. Return true and the row
/// goes, then [onDismissed] runs (an item: hidden now, undo snackbar). Return
/// false and the row springs back (a shop: its delete sheet asks first).
///
/// A swipe is invisible to a screen reader and unreachable by keyboard, so
/// the same action is also offered as a custom semantics action.
class SwipeToDelete extends ConsumerStatefulWidget {
  /// Wraps [child]. [dismissKey] must be unique and stable per row.
  const SwipeToDelete({
    required this.dismissKey,
    required this.semanticLabel,
    required this.onSwipe,
    required this.child,
    this.onDismissed,
    this.borderRadius,
    this.enabled = true,
    super.key,
  });

  final Key dismissKey;

  /// The semantics action's name ("Delete", "Delete shop").
  final String semanticLabel;

  /// Runs once the swipe commits. True removes the row; false springs it
  /// back.
  final Future<bool> Function() onSwipe;

  /// Runs after the row has gone.
  final VoidCallback? onDismissed;

  /// Rounds the red background to match a card-shaped row; null for a
  /// full-bleed list row.
  final BorderRadius? borderRadius;

  /// Off while another gesture owns the row -- multi-select and rearrange,
  /// where a horizontal swipe racing the reorder drag is the one ambiguity
  /// the spec says to design out.
  final bool enabled;

  final Widget child;

  @override
  ConsumerState<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends ConsumerState<SwipeToDelete> {
  static const double _threshold = 0.4;
  static const double _growUntil = 0.3;
  static const double _iconMin = 0.7;
  static const double _iconPop = 1.15;

  double _progress = 0;
  bool _reached = false;

  void _onUpdate(DismissUpdateDetails details) {
    if (details.reached && !details.previousReached) {
      ref.haptic(HapticFeedback.mediumImpact);
    }
    setState(() {
      _progress = details.progress;
      _reached = details.reached;
    });
  }

  double get _iconScale {
    if (_reached) return _iconPop;
    final grown = (_progress / _growUntil).clamp(0.0, 1.0);
    return _iconMin + (1 - _iconMin) * grown;
  }

  Future<void> _semanticDelete() async {
    if (await widget.onSwipe()) widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: widget.semanticLabel): () =>
            unawaited(_semanticDelete()),
      },
      child: Dismissible(
        key: widget.dismissKey,
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: _threshold},
        resizeDuration: AppMotion.durationFor(context, AppMotion.sheetOut),
        onUpdate: _onUpdate,
        confirmDismiss: (_) => widget.onSwipe(),
        onDismissed: (_) => widget.onDismissed?.call(),
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.destructive,
            borderRadius: widget.borderRadius,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: AnimatedScale(
                scale: _iconScale,
                duration: AppMotion.durationFor(context, AppMotion.micro),
                curve: AppMotion.curveFor(context, AppMotion.pop),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
