import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// Swipe a row to the left to delete it. Used for items and shops.
///
/// - Only right-to-left. Left-to-right is kept free for later.
/// - You have to swipe 40% of the row's width to delete.
/// - Behind the row is a red background with a trash icon. The icon grows
///   while you swipe, and pops bigger (with a vibration) once you've swiped
///   far enough.
/// - If you let go too early, the row slides back (decisions.md #52).
///
/// [onSwipe] decides what happens after a full swipe:
/// - return true: the row is removed, then [onDismissed] runs (items do
///   this and show an undo snackbar);
/// - return false: the row slides back (shops do this and ask first).
///
/// Screen readers can't swipe, so "delete" is also offered as an
/// accessibility action.
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

  /// What screen readers call the delete action ("Delete", "Delete shop").
  final String semanticLabel;

  /// Runs once the swipe commits. True removes the row; false springs it
  /// back.
  final Future<bool> Function() onSwipe;

  /// Runs after the row has gone.
  final VoidCallback? onDismissed;

  /// Rounded corners for the red background, for rows that look like
  /// cards. Null for normal full-width rows.
  final BorderRadius? borderRadius;

  /// Set to false in select mode and reorder mode, so swiping doesn't
  /// fight with dragging.
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
