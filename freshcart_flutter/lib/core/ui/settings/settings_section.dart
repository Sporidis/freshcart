import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';

/// A group of settings rows (design v3): a small mono title, an optional
/// explanation, then [children] on one rounded card with a thin line
/// between each row.
///
/// Every settings screen uses this, so they all get the same grouped look.
/// The card is the surface colour on the page background, with a 1px
/// border, so it stands out in dark mode too. The rows bring their own side
/// padding (see `SettingRow`), so their tap highlight still fills the card.
class SettingsSection extends StatelessWidget {
  /// Creates the section.
  const SettingsSection({
    required this.children,
    this.label,
    this.subtitle,
    super.key,
  });

  /// The mono title above the card. Null for a card with no title, like
  /// the leave/delete card at the bottom of List settings.
  final String? label;

  /// A short line under the label explaining what the group is for.
  final String? subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = this.label;
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(subtitle, style: theme.textTheme.bodySmall),
          ),
        // Material, not a Container: the rows' InkWells paint their tap
        // highlight on the nearest Material, and the shape clips it to the
        // rounded corners.
        Material(
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const Divider(),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

@Preview(group: 'Settings', name: 'Settings section', size: Size(393, 260))
Widget settingsSectionPreview() => previewPiece(
  Padding(
    padding: const EdgeInsets.all(AppSpacing.screen),
    child: SettingsSection(
      label: 'Behaviour',
      subtitle: 'How this list behaves for everyone.',
      children: [
        SettingRow(title: 'Rename shops & colours', onTap: () {}),
        const SettingRow(
          title: 'Clear checked items automatically',
          subtitle: 'Once the whole list is checked off.',
        ),
      ],
    ),
  ),
);
