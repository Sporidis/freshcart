import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Shows the v3 toast: a 48px ink bar sitting just above the add button,
/// with an optional tick and an optional Undo.
///
/// Every bulk or destructive action on the list ends in one ("Pasta
/// checked off", "Deleted 3 items", "Order saved"). Only one shows at a
/// time; a new one replaces the old.
///
/// It's a [SnackBar] underneath, so it keeps the messenger's queueing,
/// timeout and screen-reader announcement. Undo is drawn inside the content
/// instead of as a [SnackBarAction], because the action's padding rules
/// can't produce the design's fixed 48px row.
///
/// [duration] defaults to [AppMotion.toastHold]. When Undo depends on a
/// timer elsewhere (a delayed delete), pass that timer's window, so the
/// toast is visible exactly as long as Undo still works.
void showUndoToast(
  BuildContext context, {
  required String message,
  required Translations t,
  VoidCallback? onUndo,
  bool tick = false,
  Duration duration = AppMotion.toastHold,
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      // Explicit, not left to the theme: [SnackBar.margin] asserts unless
      // the snackbar floats.
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        aboveAddButton,
      ),
      content: _ToastBody(
        message: message,
        tick: tick,
        undoLabel: onUndo == null ? null : t.common.undo,
        onUndo: onUndo == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
      ),
    ),
  );
}

/// Bottom margin that clears the floating add button: it sits 22px up and
/// is 56px tall, and the design leaves a 14px gap above it.
const double aboveAddButton = 22 + 56 + 14;

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.message,
    required this.tick,
    required this.undoLabel,
    required this.onUndo,
  });

  final String message;
  final bool tick;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    // The snackbar theme already sets the ink-on-paper colours; read the
    // text colour from it so dark mode follows.
    final style = DefaultTextStyle.of(context).style;
    final fg = style.color ?? Colors.white;
    final undoLabel = this.undoLabel;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          if (tick) ...[
            Icon(Icons.check_rounded, size: 16, color: fg),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(fontSize: 15),
            ),
          ),
          if (undoLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: fg.withValues(alpha: .85),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  textStyle: style.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(undoLabel),
              ),
            )
          else
            const SizedBox(width: AppSpacing.lg),
        ],
      ),
    );
  }
}
