import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The row of suggestion chips above the field (like "Olive oil",
/// "Olives"), shown once enough is typed.
class SuggestionRow extends StatelessWidget {
  const SuggestionRow({
    required this.suggestions,
    required this.onTap,
    super.key,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      // The row is 44 px high (easy to tap). Each chip is smaller and
      // centred; its TapTarget makes the space above and below tappable too.
      child: SizedBox(
        height: AppSpacing.minTapTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return TapTarget(
              onTap: () => onTap(suggestion),
              child: Material(
                color: theme.colorScheme.surface,
                shape: StadiumBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                elevation: 1,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onTap(suggestion),
                  // v3 suggestion chip: 36px, 14px text.
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text(
                        suggestion,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
