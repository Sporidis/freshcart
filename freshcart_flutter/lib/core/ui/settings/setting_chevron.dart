import 'package:flutter/material.dart';

/// The ">" arrow that means "tap to open".
class SettingChevron extends StatelessWidget {
  /// Creates the chevron.
  const SettingChevron({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline);
}
