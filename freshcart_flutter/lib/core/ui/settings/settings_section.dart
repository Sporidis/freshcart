import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// A group of settings rows with a title: the small uppercase title, an
/// optional explanation, then [children] with a thin line between each.
///
/// The lines are only drawn between rows, so there's none after the last.
class SettingsSection extends StatelessWidget {
  /// Creates the section.
  const SettingsSection({
    required this.label,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String label;

  /// A short line under the label explaining what the group is for.
  final String? subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.gapSmall),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.gapSmall),
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const Divider(),
          child,
        ],
      ],
    );
  }
}
