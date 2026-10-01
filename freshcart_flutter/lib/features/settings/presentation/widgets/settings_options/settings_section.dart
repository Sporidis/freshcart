import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// A labelled group of settings rows: the eyebrow label, an optional
/// explanation, then [children] with a hairline between each.
///
/// Replaces `SectionLabel` plus each section laying itself out by hand --
/// which had given three sections three different labels (uppercase via
/// `SectionLabel`, a raw lowercase `Text`, and one centred). Dividers are
/// drawn here, *between* rows, so a group's last row never trails one.
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
