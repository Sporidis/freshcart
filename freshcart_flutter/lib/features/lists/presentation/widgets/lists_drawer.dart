import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/member_avatar_stack.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart'
    show showCreateListDialog, showJoinListDialog;
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

// No @Preview here: the drawer gets its data from the real ListRepository,
// and previews can't override providers (see preview_harness.dart).

/// The side drawer to switch between lists. It's the only place that shows
/// all your lists (decisions.md #68).
///
/// "New list" and "Join a list" are rows in the list (decisions.md #65).
/// At the bottom there's "Settings".
class ListsDrawer extends ConsumerWidget {
  /// Creates the drawer, highlighting [currentListId] among the others.
  const ListsDrawer({required this.currentListId, super.key});

  /// The list that's open now, so it can be highlighted.
  final ListId currentListId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final rows = ref.watch(listsDrawerControllerProvider);

    Future<void> openList(ListId id) async {
      Navigator.of(context).pop();
      if (id != currentListId) context.go(Routes.listDetail(id));
      await ref.read(listsDrawerControllerProvider.notifier).openList(id);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(rows: rows, t: t),
            const Divider(height: 1),
            Expanded(
              child: rows == null
                  ? const SizedBox.shrink()
                  : _ListRows(
                      rows: rows,
                      currentListId: currentListId,
                      t: t,
                      onOpen: openList,
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _DrawerAction(
                icon: Icons.settings_outlined,
                label: t.settings.title,
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.push(Routes.settings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of the drawer: your avatar, name, and "N lists · N people".
/// Tap to open Settings.
class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader({required this.rows, required this.t});

  /// Null while loading. Then the "N lists · N people" line is hidden.
  final List<ListsDrawerRow>? rows;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(profileControllerProvider).value?.valueOrNull;

    final rows = this.rows;
    String? summary;
    if (rows != null) {
      // Count each person once across all lists, including yourself.
      final people = <UserId>{};
      for (final row in rows) {
        for (final member in row.list.members) {
          people.add(member.userId);
        }
      }
      summary =
          '${t.lists.countLabel(n: rows.length)} · '
          '${t.lists.memberCount(n: people.length)}';
    }

    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        await context.push(Routes.settings);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Row(
          children: [
            UserAvatar(
              seed: me?.id.value ?? '',
              initial: initialFor(me?.displayName ?? ''),
              photoUrl: me?.avatarPhotoUrl,
              color: me?.avatarColor,
              radius: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    me?.displayName ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (summary != null)
                    Text(
                      summary,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The scrollable part: one row per list, then "New list" and "Join a list".
class _ListRows extends StatelessWidget {
  const _ListRows({
    required this.rows,
    required this.currentListId,
    required this.t,
    required this.onOpen,
  });

  final List<ListsDrawerRow> rows;
  final ListId currentListId;
  final Translations t;
  final void Function(ListId id) onOpen;

  String _subtitle(ListsDrawerRow row) {
    final summary = row.summary;
    if (summary == null) return t.lists.memberCount(n: row.list.members.length);
    return summary.allDone
        ? t.lists.allDone
        : t.lists.itemsLeft(n: summary.remaining);
  }

  /// Closes the drawer, then opens [dialog].
  ///
  /// Gets the [ProviderContainer] BEFORE closing, because after closing the
  /// drawer's `ref` can't be used. See `showCreateListDialog`.
  Future<void> _popThen(
    BuildContext context,
    Future<void> Function(BuildContext, ProviderContainer, Translations) dialog,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.of(context).pop();
    await dialog(context, container, t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Text(
            t.lists.title.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final row in rows)
          _ListRow(
            key: ValueKey(row.list.id.value),
            list: row.list,
            isCurrent: row.list.id == currentListId,
            subtitleLabel: _subtitle(row),
            othersInList: row.othersInList,
            onTap: () => onOpen(row.list.id),
            t: t,
          ),
        // Part of the scrolling list (not the footer), because they add to
        // these lists.
        _InlineAction(
          icon: Icons.add,
          label: t.lists.create,
          onTap: () => _popThen(context, showCreateListDialog),
        ),
        _InlineAction(
          icon: Icons.group_add_outlined,
          label: t.lists.join,
          onTap: () => _popThen(context, showJoinListDialog),
        ),
      ],
    );
  }
}

/// One list in the drawer, with a letter avatar (like member rows in
/// Household).
///
/// Stateful because it keeps a [GlobalKey] to [EditableListTitleState] (for
/// long-press rename). A key made inside `build()` would be new every
/// rebuild.
class _ListRow extends ConsumerStatefulWidget {
  const _ListRow({
    required this.list,
    required this.isCurrent,
    required this.subtitleLabel,
    required this.othersInList,
    required this.onTap,
    required this.t,
    super.key,
  });

  final ShoppingList list;
  final bool isCurrent;

  /// The second line: "6 left" / "All done", or the member count until the
  /// item counts load.
  final String subtitleLabel;

  /// Everyone on [list] except you. Shown as avatars.
  final List<ListMember> othersInList;
  final VoidCallback onTap;
  final Translations t;

  @override
  ConsumerState<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends ConsumerState<_ListRow> {
  /// Lets a long-press start renaming. (A normal tap opens the list, so
  /// `tapToEdit` is false.)
  final _titleKey = GlobalKey<EditableListTitleState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = initialFor(widget.list.name);
    // Only the owner can rename. If not allowed, `startEditing` does
    // nothing.
    final isOwner = ref.watch(isListOwnerProvider(widget.list));

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
        selected: widget.isCurrent,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: widget.isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          foregroundColor: widget.isCurrent
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          child: Text(initial, style: AppTextStyles.bodyStrong),
        ),
        title: EditableListTitle(
          key: _titleKey,
          name: widget.list.name,
          enabled: isOwner,
          tapToEdit: false,
          style: widget.isCurrent
              ? AppTextStyles.bodyStrong
              : AppTextStyles.body,
          onRename: (name) async {
            final result = await ref
                .read(listsControllerProvider.notifier)
                .rename(widget.list.id, name);
            return switch (result) {
              Ok() => null,
              Err(:final failure) => failure.toMessage(widget.t),
            };
          },
        ),
        subtitle: Text(widget.subtitleLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.othersInList.isNotEmpty) ...[
              MemberAvatarStack(members: widget.othersInList),
              const SizedBox(width: 8),
            ],
            if (widget.isCurrent)
              Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
          ],
        ),
        onTap: widget.onTap,
        onLongPress: () => _titleKey.currentState?.startEditing(),
      ),
    );
  }
}

/// The "New list" / "Join a list" rows, shown with the lists. Styled like a
/// link, not like a normal row.
class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
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
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(color: color),
        ),
        onTap: onTap,
      ),
    );
  }
}

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
