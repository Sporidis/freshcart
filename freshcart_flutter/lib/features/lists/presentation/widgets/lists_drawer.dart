import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/lists_screen.dart'
    show showCreateListDialog, showJoinListDialog;
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
    // "The avatars of who else is in them" (design's own words) -- excludes
    // the viewer's own row from each list's stack. Falls back to showing
    // everyone for the one frame before this resolves, rather than blocking
    // the whole drawer on it; keepAlive means that frame is rare in
    // practice, not just theoretical.
    final myId = switch (ref.watch(currentUserIdProvider)) {
      AsyncValue<Result<UserId>>(value: Ok<UserId>(:final value)) => value,
      _ => null,
    };

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
                          othersInList: myId == null
                              ? list.members
                              : [
                                  for (final member in list.members)
                                    if (member.userId != myId) member,
                                ],
                          onTap: () => openList(list.id),
                        ),
                      // Inline, not tucked into the footer below: the design
                      // draws these as part of the scrollable list of lists
                      // itself, not alongside Settings -- they add to *this*
                      // collection, so they read as one more thing you can
                      // do with it, not an unrelated app-level action.
                      _InlineAction(
                        icon: Icons.add,
                        label: t.lists.create,
                        onTap: () async {
                          // Grabbed before the pop below, not a WidgetRef --
                          // popping the drawer unmounts this widget, and by
                          // the time the dialog's onSubmit actually runs
                          // (once someone types a name), a ref captured from
                          // an unmounted widget would already be unsafe to
                          // read. See showCreateListDialog's own doc.
                          final container = ProviderScope.containerOf(
                            context,
                            listen: false,
                          );
                          Navigator.of(context).pop();
                          await showCreateListDialog(context, container, t);
                        },
                      ),
                      _InlineAction(
                        icon: Icons.group_add_outlined,
                        label: t.lists.join,
                        onTap: () async {
                          final container = ProviderScope.containerOf(
                            context,
                            listen: false,
                          );
                          Navigator.of(context).pop();
                          await showJoinListDialog(context, container, t);
                        },
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
    required this.othersInList,
    required this.onTap,
  });

  final ShoppingList list;
  final bool isCurrent;
  final String memberLabel;

  /// Every member of [list] except the viewer -- "the avatars of who else
  /// is in them" (design's own words).
  final List<ListMember> othersInList;
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
    final initial = member.displayName.trim().isEmpty
        ? '?'
        : member.displayName.trim()[0].toUpperCase();
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarColorFor(member.userId.value),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        initial,
        style: AppTextStyles.captionStrong.copyWith(color: Colors.white),
      ),
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
