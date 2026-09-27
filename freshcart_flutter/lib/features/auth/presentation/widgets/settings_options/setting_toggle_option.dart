import 'package:flutter/material.dart';

/// A settings row backed by a switch, with an optional description line.
class SettingToggleOption extends StatelessWidget {
  const SettingToggleOption({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      title: Text(title),
      subtitle: description != null
          ? Text(description!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
