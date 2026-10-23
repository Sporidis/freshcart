import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/error_tier.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/ui/feedback/shake_on_error.dart';

/// A dialog with one text field and one button, whose action can fail
/// (today: "Join a list"). If the action fails, the error
/// shows under the text field (not in a snackbar), so the user sees what to
/// fix.
class TextPromptDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const TextPromptDialog({
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

  /// Runs the action. [Err] keeps the dialog open with the error. [Ok]
  /// closes it.
  final Future<Result<void>> Function(String value) onSubmit;

  /// How the keyboard capitalizes. Join codes use all caps.
  final TextCapitalization capitalization;

  @override
  ConsumerState<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends ConsumerState<TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _busy = false;

  /// Whether the field should shake for the current error. Not for errors
  /// that aren't the user's fault (expired invite, no internet).
  bool _shake = true;

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
          // toMessage handles every kind of failure, no special cases needed.
          _errorText = failure.toMessage(ref.read(translationsProvider));
          _shake = shakesOn(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ShakeOnError(
        errorText: _errorText,
        shake: _shake,
        child: TextField(
          controller: _controller,
          autofocus: true,
          enabled: !_busy,
          textCapitalization: widget.capitalization,
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: _errorText,
          ),
          // Keep the text after an error, so the user can fix it. The error
          // disappears as soon as they type again.
          onChanged: (_) {
            if (_errorText == null) return;
            setState(() => _errorText = null);
          },
          onSubmitted: (_) => _busy ? null : _submit(),
        ),
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
