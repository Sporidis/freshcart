import 'package:flutter/material.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/settings_options/setting_row.dart';

/// A settings row that opens something: title, optional subtitle and
/// current value, and a chevron.
class SettingOption extends StatelessWidget {
  const SettingOption({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  /// The current choice, shown muted before the chevron ("System").
  final String? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return SettingRow(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) SettingValueText(value),
          const SettingChevron(),
        ],
      ),
    );
  }
}
