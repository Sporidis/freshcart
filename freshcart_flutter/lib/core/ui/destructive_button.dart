import 'package:flutter/material.dart';

/// The one button that destroys something: delete, leave, sign out of an
/// anonymous account.
///
/// Red from `colorScheme.error`/`onError` (which `AppTheme` pins to
/// `AppColors.destructive`), so it is the theme's colour and not a second
/// copy of it. Two sizes, because the app already has two primary sizes:
///
///  * the default is a dialog action -- a compact [FilledButton], sized like
///    the Cancel beside it;
///  * [DestructiveButton.block] is a sheet's primary -- the themed
///    full-width [ElevatedButton], the same size as every safe primary.
///
/// Only the colours are overridden; size, shape and type come from the
/// theme, so this stays in step with it.
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
