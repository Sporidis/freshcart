import 'package:flutter/material.dart';

/// The text field in the open pill, with the shop's dot before it.
///
/// Stateless: the text controller and focus node are kept by
/// `QuickAddBar`.
class QuickAddField extends StatelessWidget {
  const QuickAddField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.placeholder,
    required this.showShopDot,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String placeholder;

  /// Whether to show the accent dot before the field.
  final bool showShopDot;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Theme from inside WaveThemed, so the dot and cursor colours follow
    // the wave (decisions.md #90).
    final theme = Theme.of(context);
    final shopColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        children: [
          if (showShopDot) ...[
            Container(
              key: const ValueKey('quick-add-dot'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: shopColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: theme.colorScheme.onSurface),
              cursorColor: shopColor,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
        ],
      ),
    );
  }
}
