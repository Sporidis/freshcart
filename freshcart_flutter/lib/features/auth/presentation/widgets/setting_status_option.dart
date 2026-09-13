import 'package:flutter/material.dart';

/// A settings row that only reports a value — no switch, no tap target.
///
/// For a preference with nothing behind it to toggle, like reduce motion:
/// that state comes straight from the OS (`AppMotion.reduced`), so an
/// interactive-looking row would invite a tap that does nothing
/// (`docs/design-gap-plan.md`'s own decision on this: "read-only status, not
/// a toggle"). [SettingToggleOption] and [SettingDropdownOption] both look
/// tappable because they are; this one deliberately doesn't.
class SettingStatusOption extends StatelessWidget {
  const SettingStatusOption({
    super.key,
    required this.title,
    required this.status,
  });

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      title: Text(title),
      trailing: Text(
        status,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
