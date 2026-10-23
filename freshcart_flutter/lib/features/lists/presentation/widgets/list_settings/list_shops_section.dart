import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Shops on this list": each shop with its colour dot and an on/off switch
/// for its tab.
///
/// Always shown, even with no shops, because it has the "Add a shop" row.
class ListShopsSection extends StatelessWidget {
  const ListShopsSection({
    required this.shops,
    required this.onToggle,
    required this.onAdd,
    required this.onManage,
    required this.t,
    super.key,
  });

  final List<Shop> shops;
  final ValueChanged<Shop> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onManage;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SettingsSection(
      label: t.lists.shopsOnList,
      subtitle: t.lists.shopsOnListBody,
      children: [
        for (final shop in shops)
          MergeSemantics(
            child: SettingRow(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: shop.color.toColor(),
                  shape: BoxShape.circle,
                ),
              ),
              title: shop.name,
              onTap: () => onToggle(shop),
              trailing: Switch(
                value: shop.isActive,
                onChanged: (_) => onToggle(shop),
              ),
            ),
          ),
        SettingRow(
          leading: Icon(Icons.add, size: 18, color: muted),
          title: t.shops.add,
          titleStyle: AppTextStyles.body.copyWith(color: muted),
          onTap: onAdd,
        ),
        if (shops.isNotEmpty)
          SettingOption(title: t.lists.renameShops, onTap: onManage),
      ],
    );
  }
}
