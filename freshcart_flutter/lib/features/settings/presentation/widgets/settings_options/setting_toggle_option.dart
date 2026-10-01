import 'package:flutter/material.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/settings_options/setting_row.dart';

/// A settings row backed by a switch, with an optional description line.
///
/// The whole row toggles, not just the switch -- the switch is the smallest
/// thing in the row, and a 44 px row that only reacts on its far-right
/// corner reads as broken.
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
    // One announcement ("Haptics, switch, on"), not a label and a separate
    // unlabeled switch.
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
