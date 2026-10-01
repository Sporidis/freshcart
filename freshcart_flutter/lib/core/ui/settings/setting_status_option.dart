import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';

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
    required this.title,
    required this.status,
    this.description,
    super.key,
  });

  final String title;
  final String status;

  /// Says where the value comes from ("Follows your system setting").
  final String? description;

  @override
  Widget build(BuildContext context) => SettingRow(
    title: title,
    subtitle: description,
    trailing: SettingValueText(status),
  );
}
