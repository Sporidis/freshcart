import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_value_text.dart';

/// A settings row that only reports a value — no switch, no tap target.
///
/// For settings the app can't change itself, like reduce motion, which
/// comes from the phone's settings. It doesn't look tappable, because
/// tapping it wouldn't do anything.
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
