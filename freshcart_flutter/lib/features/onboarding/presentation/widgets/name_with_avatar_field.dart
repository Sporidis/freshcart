import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_text_listener.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/feedback/shake_on_error.dart';

/// The "What should we call you?" field, with an avatar next to it that
/// shows the first letter as you type.
///
/// Used by both onboarding and the join flow.
///
/// Before anything is typed, the avatar is an empty dashed circle, so it's
/// clear the name goes there.
class NameWithAvatarField extends StatefulWidget {
  /// Creates the field, starting from [initialValue].
  const NameWithAvatarField({
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
    this.errorText,
    this.autofocus = true,
    this.scriptedField,
    super.key,
  });

  /// The name typed so far. Comes from the controller, so it's still there
  /// when the user comes back to this step.
  final String initialValue;

  final String hintText;
  final ValueChanged<String> onChanged;

  /// Error message under the field, or null. The field shakes when it
  /// appears.
  final String? errorText;

  final bool autofocus;

  /// Lets the web demo type into this field. Null everywhere but there is
  /// the same as not having it (decisions.md #109).
  final ScriptedField? scriptedField;

  @override
  State<NameWithAvatarField> createState() => _NameWithAvatarFieldState();
}

class _NameWithAvatarFieldState extends State<NameWithAvatarField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScriptedText(String text) {
    ScriptedTextListener.apply(_controller, text);
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final field = Row(
      // Aligned to the top, so the avatar doesn't move down when an error
      // appears under the field.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => _NameAvatar(name: value.text),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: ShakeOnError(
            errorText: widget.errorText,
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              autofocus: widget.autofocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: widget.hintText,
                errorText: widget.errorText,
              ),
            ),
          ),
        ),
      ],
    );
    return switch (widget.scriptedField) {
      final scripted? => ScriptedTextListener(
        field: scripted,
        onText: _onScriptedText,
        child: field,
      ),
      null => field,
    };
  }
}

class _NameAvatar extends StatelessWidget {
  const _NameAvatar({required this.name});

  final String name;

  /// v3: 56px, the same height as the field next to it.
  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = name.trim().isEmpty;
    return SizedBox.square(
      dimension: _size,
      child: AnimatedSwitcher(
        duration: AppMotion.quick,
        child: empty
            ? CustomPaint(
                key: const ValueKey('empty'),
                painter: DashedOutlinePainter(
                  color: theme.colorScheme.outline,
                ),
                child: const SizedBox.expand(),
              )
            : DecoratedBox(
                key: const ValueKey('filled'),
                decoration: BoxDecoration(
                  color: AppColors.avatarColorFor(name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initialFor(name),
                    style: AppTextStyles.sheetTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
