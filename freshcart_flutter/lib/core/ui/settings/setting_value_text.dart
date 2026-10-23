import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';

/// The muted value a row shows on its right: "System", "On", "English".
class SettingValueText extends StatelessWidget {
  /// Shows [text].
  const SettingValueText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
