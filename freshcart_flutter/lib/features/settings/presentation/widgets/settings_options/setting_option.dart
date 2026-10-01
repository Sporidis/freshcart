import 'package:flutter/material.dart';

/// One tappable settings row: a title, an optional stack of trailing avatar
/// icons, and a chevron.
class SettingOption extends StatelessWidget {
  const SettingOption({
    super.key,
    required this.title,
    required this.onTap,
    this.trailingIcons,
  });

  final String title;
  final VoidCallback onTap;
  final List<Widget>? trailingIcons;

  @override
  Widget build(BuildContext context) {
    final icons = trailingIcons;
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icons case final values? when values.isNotEmpty)
            SizedBox(
              width: 24 + ((values.length - 1) * 12),
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < values.length; i++)
                    Positioned(
                      left: i * 12,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: values[i],
                      ),
                    ),
                ],
              ),
            ),
          if (icons?.isNotEmpty ?? false) const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
