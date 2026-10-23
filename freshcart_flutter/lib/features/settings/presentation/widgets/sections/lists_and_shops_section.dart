import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/create_or_join_list.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_list_row.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The "Lists & shops" section in Settings: a row per list (opens that
/// list's settings), and a "New list" row.
///
/// Just draws [rows]. `SettingsScreenController` already worked out the
/// counts and "Open now".
class ListsAndShopsSection extends StatelessWidget {
  const ListsAndShopsSection({required this.t, required this.rows, super.key});

  final Translations t;
  final List<SettingsListRow> rows;

  /// Builds "Open now · 2 shops · 2 members" as one string, so it wraps
  /// nicely instead of overflowing.
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
        // Always shown, even with no lists. Opens the same "new list"
        // dialog as the drawer and the empty lists screen.
        SettingRow(
          leading: Icon(Icons.add, color: primary),
          title: t.lists.create,
          titleStyle: AppTextStyles.bodyStrong.copyWith(color: primary),
          onTap: () => showCreateListSheet(
            context,
            ProviderScope.containerOf(context, listen: false),
            t,
          ),
        ),
      ],
    );
  }
}
