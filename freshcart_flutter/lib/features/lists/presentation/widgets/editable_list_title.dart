import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// A list name that turns into a text field when tapped, so it can be
/// renamed right there (no dialog).
///
/// Saves when the user presses Done or taps somewhere else. Throwing away
/// what they typed would be more surprising.
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

  /// Called with the new name. Return an error message to keep the field
  /// open, or null if it worked.
  final Future<String?> Function(String name) onRename;

  /// Whether renaming is allowed.
  final bool enabled;

  /// Whether tapping the title starts editing. True in the app bar.
  ///
  /// False in the drawer, where tapping opens the list. There, a long-press
  /// calls [EditableListTitleState.startEditing] through a [GlobalKey].
  final bool tapToEdit;

  /// Text style for the title and the field. Defaults to the app bar title
  /// style.
  final TextStyle? style;

  @override
  State<EditableListTitle> createState() => EditableListTitleState();
}

class EditableListTitleState extends State<EditableListTitle> {
  final FocusNode _focus = FocusNode();

  /// Created once, not on every edit.
  ///
  /// When editing ends, the field fades out for a moment and still uses the
  /// controller. Disposing it right away would crash.
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
    // Tapping somewhere else saves.
    if (_focus.hasFocus || !_editing || _saving) return;
    unawaited(_commit());
  }

  /// Starts editing. Public so the drawer can call it on long-press, using
  /// a `GlobalKey<EditableListTitleState>`.
  void startEditing() {
    if (!widget.enabled) return;
    _controller
      ..text = widget.name
      // Cursor at the end (not everything selected), because people usually
      // change a name a little, not replace it.
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
      // Didn't work: stay open with the typed text, so they can fix it.
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
                ? TapTarget(
                    key: const ValueKey('title'),
                    onTap: startEditing,
                    child: InkWell(
                      onTap: startEditing,
                      child: Text(widget.name, style: style),
                    ),
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
