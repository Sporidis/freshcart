import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';

/// The item's note: an "Add note" button that opens into a field, because
/// most items never get one. Open from the start if there's already a note.
///
/// Once open: a 50px field on the fill colour with a lines glyph.
class ItemNoteField extends StatefulWidget {
  /// Creates the note for [controller]'s text.
  const ItemNoteField({
    required this.controller,
    required this.hint,
    required this.addLabel,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hint;

  /// The button's label ("Add note").
  final String addLabel;
  final VoidCallback onSubmitted;

  @override
  State<ItemNoteField> createState() => _ItemNoteFieldState();
}

class _ItemNoteFieldState extends State<ItemNoteField> {
  late bool _open = widget.controller.text.isNotEmpty;
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _openField() {
    setState(() => _open = true);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.standard),
      curve: AppMotion.emphasized,
      alignment: Alignment.topLeft,
      child: _open
          ? Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: scheme.fill,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: .36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => widget.onSubmitted(),
                    ),
                  ),
                ],
              ),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openField,
                icon: const Icon(Icons.add, size: 14),
                label: Text(widget.addLabel),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                ),
              ),
            ),
    );
  }
}
