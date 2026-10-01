import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart'
    show showCreateListDialog, showJoinListDialog;
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

// No @Preview here: this widget's only content comes from
// listsDrawerControllerProvider, which reaches the real ListRepository.
// previewApp deliberately takes no overrides (see preview_harness.dart), so
// showing this with real-looking data needs an in-memory fake living in
// lib/ — the same gap already noted for screen-level previews, not
// something to improvise as a side effect of this change.

/// Switches between the user's lists — per the design (Flow 10), the *only*
/// place that answers "which list?" at all. There is no separate "all lists"
/// screen to be a door back to any more (decisions.md #68): creating and
/// joining are inline rows in this same scrollable list (decisions #65), and
/// "Settings" is the one footer action left for whatever isn't list-scoped.
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

/// The scrollable part: one row per list, then the inline create/join rows.
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

  /// Pops the drawer, then opens [dialog]. The container is grabbed *before*
  /// the pop, not a WidgetRef: popping unmounts the drawer, and by the time
  /// the dialog's onSubmit runs (once someone types), a ref from an
  /// unmounted widget is unsafe to read. See showCreateListDialog's doc.
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        for (final row in rows)
          _ListRow(
            list: row.list,
            isCurrent: row.list.id == currentListId,
            subtitleLabel: _subtitle(row),
            othersInList: row.othersInList,
            onTap: () => onOpen(row.list.id),
          ),
        // Inline, not in the footer: the design draws these as part of the
        // scrollable list of lists itself -- they add to *this* collection.
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

/// One list, with a monogram avatar rather than a bare radio glyph — the
/// same visual language Household already uses for member rows, so a row
/// that means "a specific list" or "a specific person" reads the same way
/// everywhere in the app.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.isCurrent,
    required this.subtitleLabel,
    required this.othersInList,
    required this.onTap,
  });

  final ShoppingList list;
  final bool isCurrent;

  /// The row's subtitle: a remaining-item count ("6 left" / "All done") once
  /// its summary has loaded, the member count as a placeholder until then.
  final String subtitleLabel;

  /// Every member of [list] except the viewer -- "the avatars of who else
  /// is in them" (design's own words).
  final List<ListMember> othersInList;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = initialFor(list.name);

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
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          foregroundColor: isCurrent
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          child: Text(initial, style: AppTextStyles.bodyStrong),
        ),
        title: Text(
          list.name,
          style: isCurrent ? AppTextStyles.bodyStrong : AppTextStyles.body,
        ),
        subtitle: Text(subtitleLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (othersInList.isNotEmpty) ...[
              _MemberAvatarStack(members: othersInList),
              const SizedBox(width: 8),
            ],
            if (isCurrent)
              Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Overlapping monogram avatars for who else is on a list -- capped at
/// three with a "+N" cap for the rest, since the drawer row has room for a
/// glance, not a roster (that is what Household/List settings are for).
class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.members});

  final List<ListMember> members;

  static const int _maxShown = 3;
  static const double _diameter = 22;
  static const double _overlap = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = members.take(_maxShown).toList();
    final overflow = members.length - shown.length;
    return SizedBox(
      height: _diameter,
      width:
          _diameter +
          (shown.length - 1 + (overflow > 0 ? 1 : 0)) * (_diameter - _overlap),
      child: Stack(
        children: [
          for (final (index, member) in shown.indexed)
            Positioned(
              left: index * (_diameter - _overlap),
              child: _MemberAvatar(
                member: member,
                borderColor: theme.colorScheme.surface,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (_diameter - _overlap),
              child: Container(
                width: _diameter,
                height: _diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.outlineVariant,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '+$overflow',
                  style: AppTextStyles.captionStrong.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.borderColor});

  final ListMember member;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final initial = initialFor(member.displayName);
    return UserAvatar(
      seed: member.userId.value,
      initial: initial,
      photoUrl: member.avatarPhotoUrl,
      color: member.avatarColor,
      radius: 11,
      border: Border.all(color: borderColor, width: 1.5),
    );
  }
}

/// A footer row: "All lists", "Settings". Same shape, so the two read as a
/// pair rather than one being an afterthought under the other.
/// "New list" / "Join a list" -- drawn inline with the lists themselves
/// (design's own frame), in the same accent colour as any other link-style
/// action in the app, rather than the neutral ink of an ordinary row.
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
