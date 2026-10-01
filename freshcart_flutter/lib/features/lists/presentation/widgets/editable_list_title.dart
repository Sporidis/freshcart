import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// The list name in the app bar, editable in place.
///
/// Renaming happens here rather than in a sheet or a dialog, per the design:
/// the title *is* the field, so there is no modal to open, no second copy of
/// the name to reconcile, and no doubt about what is being renamed.
///
/// Commits on submit or on blur. Blur counts as intent because the alternative
/// — silently discarding what someone typed when they tap away — is the more
/// surprising of the two.
class EditableListTitle extends StatefulWidget {
  /// Creates the title for [name].
  const EditableListTitle({
    required this.name,
    required this.onRename,
    this.enabled = true,
    this.tapToEdit = true,
    this.style,
    super.key,
  });

  /// The current name.
  final String name;

  /// Called with the new name. Returning an error message keeps the field
  /// open so it can be corrected; null means it was accepted.
  final Future<String?> Function(String name) onRename;

  /// Whether renaming is offered at all.
  final bool enabled;

  /// Whether tapping the title itself starts editing (the app bar's own
  /// behaviour -- there, nothing else on the title competes for the tap).
  /// False when some other gesture on the same element already means
  /// something else (the drawer row's tap opens the list) -- editing then
  /// starts only through [EditableListTitleState.startEditing], called
  /// externally via a [GlobalKey] from whatever gesture *does* mean "rename"
  /// there (the drawer's long-press).
  final bool tapToEdit;

  /// The text style for both the static title and the field. Defaults to
  /// the app bar's own title style, which is all every caller but the
  /// drawer needs.
  final TextStyle? style;

  @override
  State<EditableListTitle> createState() => EditableListTitleState();
}

class EditableListTitleState extends State<EditableListTitle> {
  final FocusNode _focus = FocusNode();

  /// Lives as long as the widget does, rather than being created per edit.
  ///
  /// The switcher below keeps the outgoing field on screen while it fades, so
  /// a controller disposed the moment editing ends is still being read by a
  /// widget that has not finished leaving.
  final TextEditingController _controller = TextEditingController();

  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Blurring commits. Silently discarding what someone typed when they tap
    // away is the more surprising of the two options.
    if (_focus.hasFocus || !_editing || _saving) return;
    unawaited(_commit());
  }

  /// Starts editing, same as tapping the title does when [tapToEdit] is
  /// true. Public so a caller that suppresses that tap (passing
  /// `tapToEdit: false`) can trigger it from its own gesture instead, via a
  /// `GlobalKey<EditableListTitleState>`.
  void startEditing() {
    if (!widget.enabled) return;
    _controller
      ..text = widget.name
      // Cursor at the end, not a full selection: renaming is usually a tweak
      // to the existing name rather than a replacement.
      ..selection = TextSelection.collapsed(offset: widget.name.length);
    setState(() => _editing = true);
    _focus.requestFocus();
  }

  Future<void> _commit() async {
    if (!_editing || _saving) return;
    final typed = _controller.text;
    if (typed == widget.name) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onRename(typed);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      // Rejected: stay open holding what they typed, so it can be corrected
      // rather than retyped.
      _focus.requestFocus();
      return;
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).appBarTheme.titleTextStyle;

    return AnimatedSwitcher(
      duration: AppMotion.durationFor(context, AppMotion.quick),
      child: !_editing
          ? (widget.tapToEdit
                ? InkWell(
                    key: const ValueKey('title'),
                    onTap: startEditing,
                    child: Text(widget.name, style: style),
                  )
                : Text(
                    widget.name,
                    key: const ValueKey('title'),
                    style: style,
                  ))
          : TextField(
              key: const ValueKey('field'),
              controller: _controller,
              focusNode: _focus,
              enabled: !_saving,
              style: style,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onSubmitted: (_) => _commit(),
            ),
    );
  }
}

@Preview(group: 'Lists', name: 'Editable title', size: Size(393, 200))
Widget editableListTitlePreview() => previewApp(
  Scaffold(
    appBar: AppBar(
      title: EditableListTitle(
        name: 'Weekly Groceries',
        onRename: (_) async => null,
      ),
    ),
    body: const Center(child: Text('Tap the title to rename it in place')),
  ),
);
