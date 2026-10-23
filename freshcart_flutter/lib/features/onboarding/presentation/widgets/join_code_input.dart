import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_text_listener.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';

/// The input for a [JoinCode]: looks like five boxes, but it's really one
/// invisible text field.
///
/// How it works: one normal `TextField` sits on top of the row, fully
/// transparent, and does all the typing. Underneath, five boxes just
/// display the characters.
///
/// Why not five real text fields? Then we'd have to write code to jump to
/// the next box, go back on backspace, and split a pasted code over the
/// boxes. One text field already does all of that for free, including
/// paste and autofill.
class JoinCodeInput extends StatefulWidget {
  /// Creates the input. [value] is the code so far (in uppercase).
  /// [onChanged] is called on every change.
  const JoinCodeInput({
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.hasError = false,
    this.scriptedField,
    super.key,
  });

  /// The code typed so far.
  final String value;

  /// Called with the new value whenever it changes.
  final ValueChanged<String> onChanged;

  /// Whether to open the keyboard straight away.
  final bool autofocus;

  /// Makes all box borders red, to show an error.
  final bool hasError;

  /// Lets the web demo type into this field. Null everywhere but there is
  /// the same as not having it (decisions.md #109).
  final ScriptedField? scriptedField;

  @override
  State<JoinCodeInput> createState() => _JoinCodeInputState();
}

class _JoinCodeInputState extends State<JoinCodeInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focus = FocusNode()
    ..addListener(() => setState(() {})); // repaint the active box's border.

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onScriptedText(String text) {
    ScriptedTextListener.apply(_controller, text);
    setState(() {}); // the boxes read _controller.text directly.
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    // The box where the next character goes. It gets a highlighted border,
    // which acts as the cursor (the real cursor is invisible).
    final activeIndex = text.length.clamp(0, JoinCode.length - 1);

    final input = GestureDetector(
      // Tapping anywhere on the row opens the keyboard.
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                for (final index in List.generate(
                  JoinCode.length,
                  (i) => i,
                )) ...[
                  if (index > 0) const SizedBox(width: 9),
                  Expanded(
                    child: _CodeBox(
                      character: index < text.length ? text[index] : '',
                      active: _focus.hasFocus && index == activeIndex,
                      hasError: widget.hasError,
                    ),
                  ),
                ],
              ],
            ),
            // The real, invisible text field. It handles typing, paste and
            // autofill. The boxes only display.
            Opacity(
              opacity: 0,
              // Opacity 0 also hides a widget from screen readers, which
              // would make the code impossible to type with one on.
              alwaysIncludeSemantics: true,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.visiblePassword,
                maxLength: JoinCode.length,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {}); // the boxes read _controller.text directly.
                  widget.onChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
    return switch (widget.scriptedField) {
      final scripted? => ScriptedTextListener(
        field: scripted,
        onText: _onScriptedText,
        child: input,
      ),
      null => input,
    };
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.character,
    required this.active,
    required this.hasError,
  });

  final String character;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.quick,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error
              : active
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: active ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        character,
        // No letter spacing: one letter per box, and spacing would push it
        // off-centre.
        style: AppTextStyles.codeLarge.copyWith(
          letterSpacing: 0,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Turns letters into uppercase while typing. Join codes are always
/// uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
