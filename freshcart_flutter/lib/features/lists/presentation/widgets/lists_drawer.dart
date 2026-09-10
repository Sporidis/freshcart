import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:go_router/go_router.dart';

// No @Preview here: this widget's only content comes from
// listsControllerProvider, which reaches the real ListRepository.
// previewApp deliberately takes no overrides (see preview_harness.dart), so
// showing this with real-looking data needs an in-memory fake living in
// lib/ — the same gap already noted for screen-level previews, not
// something to improvise as a side effect of this change.

/// Switches between the user's lists without a trip back to the Lists screen.
///
/// Deliberately just a switcher: creating and joining lists already have a
/// home on [ListsScreen][], and duplicating that flow here would be a second
/// place to keep in sync for no reader benefit — "All lists" at the bottom is
/// the door back to it, alongside "Settings" for whatever is not list-scoped.
class ListsDrawer extends ConsumerWidget {
  /// Creates the drawer, highlighting [currentListId] among the others.
  const ListsDrawer({required this.currentListId, super.key});

  /// The list already open, so it reads as the current one rather than a
  /// plain entry to tap.
  final ListId currentListId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);

    void openList(ListId id) {
      Navigator.of(context).pop();
      if (id != currentListId) context.go(Routes.listDetail(id));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                24,
                AppSpacing.screen,
                16,
              ),
              child: Text(t.lists.title, style: theme.textTheme.headlineSmall),
            ),
            Expanded(
              child: switch (lists) {
                AsyncOutcome<List<ShoppingList>>(
                  value: Ok<List<ShoppingList>>(:final value),
                ) =>
                  ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    children: [
                      for (final list in value)
                        _ListRow(
                          list: list,
                          isCurrent: list.id == currentListId,
                          memberLabel: t.lists.memberCount(
                            n: list.members.length,
                          ),
                          onTap: () => openList(list.id),
                        ),
                    ],
                  ),
                // A load failure here is not worth its own screen tier — the
                // drawer just falls back to "nothing to switch to", and the
                // list already open keeps working regardless.
                _ => const SizedBox.shrink(),
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _DrawerAction(
                    icon: Icons.list_alt_outlined,
                    label: t.lists.allLists,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(Routes.lists);
                    },
                  ),
                  _DrawerAction(
                    icon: Icons.settings_outlined,
                    label: t.settings.title,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await context.push(Routes.settings);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One list, with a monogram avatar rather than a bare radio glyph — the
/// same visual language Household already uses for member rows, so a row
/// that means "a specific list" or "a specific person" reads the same way
/// everywhere in the app.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.isCurrent,
    required this.memberLabel,
    required this.onTap,
  });

  final ShoppingList list;
  final bool isCurrent;
  final String memberLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = list.name.trim().isEmpty
        ? '?'
        : list.name.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        selected: isCurrent,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isCurrent
              ? AppColors.ink
              : theme.colorScheme.outlineVariant,
          foregroundColor: isCurrent
              ? Colors.white
              : theme.colorScheme.onSurface,
          child: Text(initial, style: AppTextStyles.bodyStrong),
        ),
        title: Text(
          list.name,
          style: isCurrent ? AppTextStyles.bodyStrong : AppTextStyles.body,
        ),
        subtitle: Text(memberLabel),
        trailing: isCurrent
            ? Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// A footer row: "All lists", "Settings". Same shape, so the two read as a
/// pair rather than one being an afterthought under the other.
class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    ),
  );
}
