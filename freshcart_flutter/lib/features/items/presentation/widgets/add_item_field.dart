import 'package:flutter/material.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The always-visible "what do you need?" field at the bottom of a list.
///
/// A persistent field rather than a dialog: adding several things in a row is
/// the single most common action in this app, and a dialog per item would make
/// that four taps instead of one.
class AddItemField extends StatefulWidget {
  /// Creates the field.
  const AddItemField({required this.onSubmit, required this.t, super.key});

  /// Called with the typed name. Returning false keeps the text for a retry.
  final Future<bool> Function(String name) onSubmit;

  /// Translations for the active locale.
  final Translations t;

  @override
  State<AddItemField> createState() => _AddItemFieldState();
}

class _AddItemFieldState extends State<AddItemField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    final added = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) {
      _controller.clear();
      // Keep focus so the next item can be typed straight away.
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: widget.t.items.namePlaceholder,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton.filled(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.add),
                tooltip: widget.t.items.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
