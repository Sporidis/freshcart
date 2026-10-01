import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart'
    show showCreateListDialog;
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_state.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/settings_options/section_label.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "Lists & shops" group: doors into each list's
/// settings, and into making a new one. Draws [rows] as given -- counts and
/// "Open now" are already decided by `SettingsScreenController`.
class ListsAndShopsSection extends StatelessWidget {
  const ListsAndShopsSection({required this.t, required this.rows, super.key});

  final Translations t;
  final List<SettingsListRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          text: t.settings.listsAndShops.toUpperCase(),
          subtitle: t.settings.listsAndShopsSubtitle,
        ),
        const SizedBox(height: 12),
        if (rows.isNotEmpty) ...[
          for (final row in rows)
            _ListOption(
              t: t,
              row: row,
              onTap: () => context.push(Routes.listSettings(row.list.id)),
            ),
          TextButton(
            // The same dialog the drawer and the empty lists screen open --
            // one flow, three doors.
            onPressed: () => showCreateListDialog(
              context,
              ProviderScope.containerOf(context, listen: false),
              t,
            ),
            child: Text(
              t.lists.create,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListOption extends StatelessWidget {
  const _ListOption({required this.t, required this.row, required this.onTap});

  final Translations t;
  final SettingsListRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = row.list.members.length;
    final shopCount = row.shopCount;
    return ListTile(
      title: Text(row.list.name),
      subtitle: Row(
        children: [
          if (row.isOpen) Text('${t.settings.openNow} · '),
          if (shopCount != null) Text(t.settings.shopCount(n: shopCount)),
          if (members > 0) Text(' · ${t.settings.memberCount(n: members)}'),
        ],
      ),
      onTap: onTap,
    );
  }
}
