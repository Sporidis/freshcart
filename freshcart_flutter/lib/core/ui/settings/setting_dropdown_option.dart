import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';

/// A settings row showing its current choice, which opens a dialog to pick
/// one of [options].
///
/// Looks the same as a [SettingOption] (value, then an arrow).
class SettingDropdownOption<T> extends StatelessWidget {
  const SettingDropdownOption({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  Future<void> _pick(BuildContext context) async {
    final chosen = await showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final MapEntry(:key, value: label) in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(key),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  if (key == value) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) => SettingOption(
    title: title,
    value: options[value] ?? value.toString(),
    onTap: () => _pick(context),
  );
}
