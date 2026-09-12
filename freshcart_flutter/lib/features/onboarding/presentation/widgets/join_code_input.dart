import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// Captures a [JoinCode]: five boxes, matching the design, backed by one
/// real (invisible) text field.
///
/// The design's own interaction — type a character and the "cursor" hops to
/// the next box, backspace on an empty box steps back into the previous one
/// and clears it, pasting a full code fills every box at once — turns out to
/// already be exactly what a single ordinary text field does to a plain
/// string: delete the last character, or replace the whole value on paste.
/// There is no real per-box focus to hand off here, only the *look* of five
/// boxes. So rather than five `TextField`s each juggling their own
/// `FocusNode` (and hand-rolling backspace-into-the-previous-box and
/// paste-splitting to match), this keeps one real `TextField` — fully
/// transparent, sized over the whole row — doing the actual text editing,
/// and draws five read-only boxes underneath purely for how it looks. That
/// keeps the platform keyboard, paste, and SMS autofill suggestions all
/// working for free, which five separate fields would each have to earn back
/// on their own.
class JoinCodeInput extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    // The box about to receive the next character — the design's "cursor"
    // is really just this box's border, since there is nowhere else for a
    // blinking caret to visibly land once the real field is invisible.
    final activeIndex = text.length.clamp(0, JoinCode.length - 1);

    return GestureDetector(
      // Tapping anywhere in the row should focus the field, not just its
      // own (invisible, possibly narrower) hit area.
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
                    ),
                  ),
                ],
              ],
            ),
            // The real field: invisible, capturing every keystroke, paste
            // and autofill suggestion. The boxes above are purely decorative.
            Opacity(
              opacity: 0,
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
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.character, required this.active});

  final String character;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.quick,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: active ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        character,
        style: AppTextStyles.codeLarge.copyWith(
          fontSize: 22,
          color: theme.colorScheme.onSurface,
        ),
      ),
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
