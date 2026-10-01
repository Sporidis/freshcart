import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart'
    show showCreateListDialog;
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "Lists & shops" group: doors into each list's
/// settings, and into making a new one. Draws [rows] as given -- counts and
/// "Open now" are already decided by `SettingsScreenController`.
class ListsAndShopsSection extends StatelessWidget {
  const ListsAndShopsSection({required this.t, required this.rows, super.key});

  final Translations t;
  final List<SettingsListRow> rows;

  /// "Open now · 2 shops · 2 members" -- one string, so a long list name's
  /// summary wraps or truncates as a unit instead of overflowing a Row.
  String _summary(SettingsListRow row) {
    final members = row.list.members.length;
    final shopCount = row.shopCount;
    return [
      if (row.isOpen) t.settings.openNow,
      if (shopCount != null) t.settings.shopCount(n: shopCount),
      if (members > 0) t.settings.memberCount(n: members),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SettingsSection(
      label: t.settings.listsAndShops,
      subtitle: t.settings.listsAndShopsSubtitle,
      children: [
        for (final row in rows)
          SettingOption(
            title: row.list.name,
            subtitle: _summary(row),
            onTap: () => context.push(Routes.listSettings(row.list.id)),
          ),
        // Always present -- it used to render only when at least one list
        // already existed, which hid the one door someone with *no* lists
        // needs. Same dialog the drawer and the empty lists screen open:
        // one flow, three doors. Styled like the drawer's own inline action.
        SettingRow(
          leading: Icon(Icons.add, color: primary),
          title: t.lists.create,
          titleStyle: AppTextStyles.bodyStrong.copyWith(color: primary),
          onTap: () => showCreateListDialog(
            context,
            ProviderScope.containerOf(context, listen: false),
            t,
          ),
        ),
      ],
    );
  }
}
