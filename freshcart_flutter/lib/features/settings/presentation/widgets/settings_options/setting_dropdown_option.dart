import 'package:flutter/material.dart';

/// A settings row that opens a dialog to pick one of [options].
class SettingDropdownOption<T> extends StatelessWidget {
  const SettingDropdownOption({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      style: ListTileStyle.list,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      title: Text(title),
      trailing: Text(options[value] ?? value.toString()),
      onTap: () async {
        final chosen = await showDialog<T>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: options.entries
                .map(
                  (entry) => ListTile(
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(entry.value),
                    ),
                    trailing: entry.key == value
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(entry.key),
                  ),
                )
                .toList(),
          ),
        );
        if (chosen != null) onChanged(chosen);
      },
    );
  }
}
