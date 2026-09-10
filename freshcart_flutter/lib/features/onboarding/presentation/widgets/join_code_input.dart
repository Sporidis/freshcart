import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// Captures a [JoinCode]: five characters, typed or pasted.
///
/// TODO(human): the design draws this as five separate boxes — type a
/// character and focus auto-advances to the next box; backspace on an empty
/// box steps back into the previous one and clears it; pasting a full code
/// fills every box at once. That is not built yet: [build] below currently
/// always returns [_PlainJoinCodeInput], a single field that already works
/// end to end (uppercased, capped at 5 characters, monospace, wide
/// letter-spacing), so nothing else in the join flow is blocked on this —
/// swap `build` to return your segmented version once it exists.
///
/// Worth thinking about before you start: a `TextField` per box, each with
/// its own `FocusNode`, reacting to `TextEditingController` changes to
/// decide when to hop focus? Or one hidden, real `TextField` capturing all
/// the input (so the platform keyboard, paste, and autofill all keep working
/// for free) with five read-only boxes drawn on top of it just to *look*
/// segmented? Both are legitimate; they trade off differently on how much
/// platform behaviour (paste, autofill, voice input) you keep for free.
class JoinCodeInput extends StatelessWidget {
  /// Creates the input. [value] is the code so far (already uppercased);
  /// [onChanged] fires with the new value on every edit.
  const JoinCodeInput({
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });

  /// The code typed so far.
  final String value;

  /// Called with the new value whenever it changes.
  final ValueChanged<String> onChanged;

  /// Whether to grab focus and the keyboard as soon as this builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // TODO(human): return your segmented five-box widget here instead, once
    // it exists. See the class doc above.
    return _PlainJoinCodeInput(
      value: value,
      onChanged: onChanged,
      autofocus: autofocus,
    );
  }
}

/// The working fallback: one field, capped and formatted like a join code,
/// good enough to ship while [_SegmentedJoinCodeInput] is unbuilt.
class _PlainJoinCodeInput extends StatefulWidget {
  const _PlainJoinCodeInput({
    required this.value,
    required this.onChanged,
    required this.autofocus,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<_PlainJoinCodeInput> createState() => _PlainJoinCodeInputState();
}

class _PlainJoinCodeInputState extends State<_PlainJoinCodeInput> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.visiblePassword,
      style: AppTextStyles.codeLarge.copyWith(fontSize: 24),
      maxLength: JoinCode.length,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        UpperCaseTextFormatter(),
      ],
      decoration: const InputDecoration(counterText: ''),
      onChanged: widget.onChanged,
    );
  }
}

/// Uppercases as the user types — join codes have no lowercase letters, so
/// there is nothing for case to distinguish, only something for a stray
/// caps-lock state to get wrong.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

@Preview(group: 'Onboarding', name: 'Join code input', size: Size(300, 100))
Widget joinCodeInputPreview() => previewPiece(
  JoinCodeInput(value: '8F3K', onChanged: (_) {}),
);
