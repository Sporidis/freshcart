import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list's name, saved without a Save button: on the keyboard's Done
/// key, when focus moves away, and when leaving the screen.
class ListNameField extends StatefulWidget {
  /// Creates the field, filled with [initialName].
  const ListNameField({
    required this.initialName,
    required this.label,
    required this.onRename,
    required this.t,
    super.key,
  });

  final String initialName;
  final String label;

  /// Saves the name. Returns the failure, or null when it saved.
  final Future<Failure?> Function(String name) onRename;
  final Translations t;

  @override
  State<ListNameField> createState() => _ListNameFieldState();
}

class _ListNameFieldState extends State<ListNameField> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final FocusNode _focus = FocusNode()..addListener(_saveOnBlur);
  late String _savedName = widget.initialName;
  Failure? _failure;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _isDirty => _name.text.trim() != _savedName;

  void _saveOnBlur() {
    // Don't save twice:
    // - not while already saving (saving also removes focus);
    // - not while leaving the screen (PopScope below saves then).
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!_focus.hasFocus && _isDirty && !_saving && isCurrent) {
      unawaited(_save());
    }
  }

  Future<void> _save() async {
    final name = _name.text;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onRename(name);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failure = failure;
      if (failure == null) _savedName = name.trim();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Leaving with an unsaved name: save it. It goes through the lists
    // controller, which keeps existing after this screen closes.
    onPopInvokedWithResult: (didPop, _) {
      if (didPop && _isDirty) unawaited(widget.onRename(_name.text));
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.gapSmall),
        TextField(
          key: const Key('listNameField'),
          controller: _name,
          focusNode: _focus,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(errorText: _failure?.toMessage(widget.t)),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
  );
}
