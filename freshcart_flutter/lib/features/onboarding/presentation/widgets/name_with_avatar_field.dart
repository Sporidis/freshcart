import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/shake_on_error.dart';

/// The "What should we call you?" field: an avatar that fills in with the
/// person's initial as they type, beside the name field itself.
///
/// Shared by the onboarding wizard's first step and the join flow's name
/// step -- the design draws them identically, and they had already drifted
/// apart as two copies (different title sizes, two different initial rules).
///
/// The avatar is the field's explanation: before anything is typed it is an
/// empty dashed circle, so it is obvious the name is what will go in it.
class NameWithAvatarField extends StatefulWidget {
  /// Creates the field, starting from [initialValue].
  const NameWithAvatarField({
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
    this.errorText,
    this.autofocus = true,
    super.key,
  });

  /// The name typed so far -- the controller's draft, so going back to this
  /// step does not lose it.
  final String initialValue;

  final String hintText;
  final ValueChanged<String> onChanged;

  /// Inline validation message, or null. Shakes the field when it appears.
  final String? errorText;

  final bool autofocus;

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

  @override
  Widget build(BuildContext context) {
    return Row(
      // Top-aligned: an error line under the field must not drag the avatar
      // down to the new vertical centre.
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
  }
}

class _NameAvatar extends StatelessWidget {
  const _NameAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = name.trim().isEmpty;
    return SizedBox.square(
      dimension: AppSizes.avatarLarge,
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

@Preview(group: 'Onboarding', name: 'Name with avatar', size: Size(393, 200))
Widget nameWithAvatarFieldPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 24,
    children: [
      NameWithAvatarField(
        initialValue: 'Alex Janssens',
        hintText: 'e.g. Alex Janssens',
        onChanged: (_) {},
        autofocus: false,
      ),
      NameWithAvatarField(
        initialValue: '',
        hintText: 'e.g. Alex Janssens',
        onChanged: (_) {},
        errorText: 'Please enter your name to continue',
        autofocus: false,
      ),
    ],
  ),
);
