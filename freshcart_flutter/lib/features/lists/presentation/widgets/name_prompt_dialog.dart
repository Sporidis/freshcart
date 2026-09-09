import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';

/// A single-field dialog that submits through a fallible action.
///
/// Shared by "new list" and "join by code" because both are the same shape: one
/// text field, one action that can fail with a [ValidationFailure] belonging to
/// *that field*. Showing the message inline is the whole point — a snackbar
/// would leave the user staring at a field they cannot see is wrong.
class NamePromptDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const NamePromptDialog({
    required this.title,
    required this.label,
    required this.submitLabel,
    required this.cancelLabel,
    required this.onSubmit,
    this.capitalization = TextCapitalization.sentences,
    super.key,
  });

  /// Dialog heading.
  final String title;

  /// Label for the single text field.
  final String label;

  /// Label for the confirming button.
  final String submitLabel;

  /// Label for the dismissing button.
  final String cancelLabel;

  /// Runs the action. Returning an [Err] keeps the dialog open and shows the
  /// message; an [Ok] closes it.
  final Future<Result<void>> Function(String value) onSubmit;

  /// How the field capitalizes input. Join codes are upper-case.
  final TextCapitalization capitalization;

  @override
  ConsumerState<NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends ConsumerState<NamePromptDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():
        Navigator.of(context).pop(true);
      case Err<void>(:final failure):
        setState(() {
          _busy = false;
          // FailureMessage already shows a ValidationFailure's own message and
          // localizes everything else, so there is no special case here.
          _errorText = failure.toMessage(ref.read(translationsProvider));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_busy,
        textCapitalization: widget.capitalization,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _errorText,
        ),
        onSubmitted: (_) => _busy ? null : _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}
