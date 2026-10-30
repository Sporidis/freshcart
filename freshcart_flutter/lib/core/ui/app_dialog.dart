import 'package:flutter/material.dart';

/// The app's dialog: a [title], its [content], and [actions] centered
/// underneath.
///
/// A thin wrapper around [AlertDialog], because Flutter's dialog theme
/// can't set where the buttons go. Using this everywhere keeps every
/// dialog alike; colours, shape and text styles still come from the theme.
class AppDialog extends StatelessWidget {
  /// Creates the dialog.
  const AppDialog({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
  });

  /// The question or heading at the top.
  final Widget title;

  /// What the dialog says or asks for.
  final Widget content;

  /// The buttons, usually "Cancel" then the main action.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: title,
    content: content,
    actionsAlignment: MainAxisAlignment.center,
    actions: actions,
  );
}
