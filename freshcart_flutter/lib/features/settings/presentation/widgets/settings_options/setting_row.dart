import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The one settings row every option widget is built on: title, optional
/// subtitle, optional leading and trailing slots, optional tap.
///
/// The option widgets (`SettingOption`, `SettingToggleOption`,
/// `SettingDropdownOption`, `SettingStatusOption`) used to wrap three
/// different Material tiles, each overriding its own padding and drawing
/// its own divider. They drifted on height, inset, divider colour and value
/// styling. Now they only decide what goes in [trailing]; geometry lives
/// here once.
///
/// No horizontal padding: rows share their left edge with the section label
/// above them (the screen's own side padding sets that edge). No divider
/// either -- `SettingsSection` draws those *between* rows, so a group's last
/// row never gets one, matching the design.
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

  /// Null makes the row inert (no ripple, nothing for a screen reader to
  /// announce as a button) -- right for a read-only status row.
  final VoidCallback? onTap;

  /// Overrides the title's style -- for action rows ("New list") and the
  /// destructive "Sign out".
  final TextStyle? titleStyle;

  /// The design's hairline gap between title and subtitle -- tighter than
  /// any spacing token, which are all for gaps *between* things.
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

/// The "this opens something" chevron.
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
