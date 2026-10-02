import 'package:flutter/material.dart';

/// The red button for actions that delete or remove something (delete,
/// leave, sign out).
///
/// The red comes from the theme (`colorScheme.error`). Two sizes:
///
///  * default: a small button for dialogs, next to Cancel;
///  * [DestructiveButton.block]: a full-width button for bottom sheets.
///
/// Only the colour is changed. Size and shape come from the theme.
class DestructiveButton extends StatelessWidget {
  /// A compact dialog action.
  const DestructiveButton({
    required this.onPressed,
    required this.child,
    super.key,
  }) : _block = false;

  /// A full-width sheet primary.
  const DestructiveButton.block({
    required this.onPressed,
    required this.child,
    super.key,
  }) : _block = true;

  final VoidCallback? onPressed;
  final Widget child;
  final bool _block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_block) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
        onPressed: onPressed,
        child: child,
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
