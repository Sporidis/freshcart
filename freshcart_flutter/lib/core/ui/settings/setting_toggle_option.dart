import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';

/// A settings row backed by a switch, with an optional description line.
///
/// Tapping anywhere on the row toggles it, not only the switch itself.
class SettingToggleOption extends StatelessWidget {
  const SettingToggleOption({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    // Screen readers read the row as one thing: "Haptics, switch, on".
    return MergeSemantics(
      child: SettingRow(
        title: title,
        subtitle: description,
        onTap: () => onChanged(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
