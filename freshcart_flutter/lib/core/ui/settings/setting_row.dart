import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The basic settings row: title, optional subtitle, optional things on the
/// left and right, optional tap.
///
/// All the other setting widgets (`SettingOption`, `SettingToggleOption`,
/// ...) are built on this one and only choose what goes in [trailing]. That
/// way every settings row has the same size and spacing.
///
/// No side padding, so rows line up with the section title above them.
/// No divider either: `SettingsSection` draws those between rows.
class SettingRow extends StatelessWidget {
  /// Creates the row.
  const SettingRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleStyle,
    super.key,
  });

  final String title;

  /// A second, muted line under [title] -- a description or a summary.
  final String? subtitle;

  final Widget? leading;
  final Widget? trailing;

  /// If null, the row can't be tapped and screen readers won't call it a
  /// button. Use that for rows that only show information.
  final VoidCallback? onTap;

  /// A different style for the title, for example red for "Sign out".
  final TextStyle? titleStyle;

  /// The small gap between title and subtitle. Smaller than any value in
  /// `AppSpacing`.
  static const double _subtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final tileTheme = ListTileTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.rowVertical,
          ),
          child: Row(
            children: [
              if (leading case final leading?) ...[
                leading,
                const SizedBox(width: AppSpacing.gap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle ?? tileTheme.titleTextStyle),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: _subtitleGap),
                      Text(subtitle, style: tileTheme.subtitleTextStyle),
                    ],
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: AppSpacing.gap),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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

/// The ">" arrow that means "tap to open".
class SettingChevron extends StatelessWidget {
  /// Creates the chevron.
  const SettingChevron({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline);
}

@Preview(group: 'Settings', name: 'Setting row', size: Size(393, 220))
Widget settingRowPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SettingRow(
        title: 'Appearance',
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [SettingValueText('System'), SettingChevron()],
        ),
        onTap: () {},
      ),
      const Divider(),
      const SettingRow(
        title: 'Larger list text',
        subtitle: "Easier to read at arm's length in the aisle",
      ),
    ],
  ),
);
