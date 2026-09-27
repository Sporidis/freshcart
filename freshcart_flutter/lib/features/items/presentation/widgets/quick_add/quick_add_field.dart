import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// The open pill's text field, led by the active shop's dot.
///
/// Stateless on purpose: the controller and focus node belong to
/// `QuickAddBar`'s state, which outlives every rebuild of this.
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

  /// Only on a shop tab -- on "All" there is no shop colour to show.
  final bool showShopDot;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Read from *this* context, which sits inside WaveThemed's gated Theme
    // (decisions #90), so the dot and cursor ride the shop-colour wave.
    final theme = Theme.of(context);
    final shopColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        children: [
          if (showShopDot) ...[
            Container(
              key: const ValueKey('quick-add-dot'),
              width: AppSizes.shopDot,
              height: AppSizes.shopDot,
              decoration: BoxDecoration(
                color: shopColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 11),
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
