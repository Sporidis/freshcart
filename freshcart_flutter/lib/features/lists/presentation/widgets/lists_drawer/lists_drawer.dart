import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/motion/cascade_in.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_row.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_section_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/create_or_join_list.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer/lists_drawer_header.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer/lists_drawer_tile.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The side drawer to switch between lists (design v3). It's the only place
/// that shows all your lists (decisions.md #68).
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
    final rows = ref.watch(listsDrawerSectionControllerProvider);

    // [titleAt] is where the tapped name sits, so it can fly into the new
    // list's header (design v3). Not under reduced motion.
    Future<void> openList(ListId id, Rect? titleAt) async {
      final flight = titleAt == null || AppMotion.reduced(context)
          ? null
          : ListTitleFlight(from: titleAt);
      Navigator.of(context).pop();
      if (id != currentListId) {
        context.go(Routes.listDetail(id), extra: flight);
      }
      await ref
          .read(listsDrawerSectionControllerProvider.notifier)
          .openList(id);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListsDrawerHeader(t: t),
            const Divider(height: 1, indent: 20, endIndent: 20),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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

/// The scrollable part: "YOUR LISTS", one tile per list, then "New list" and
/// "Join a list". The tiles cascade in, 40ms apart.
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
  final void Function(ListId id, Rect? titleAt) onOpen;

  /// Closes the drawer, then opens [dialog].
  ///
  /// Gets the [ProviderContainer] BEFORE closing, because after closing the
  /// drawer's `ref` can't be used. See `showCreateListSheet`.
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
    const step = Duration(milliseconds: 40);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Text(
            t.lists.title.toUpperCase(),
            textAlign: TextAlign.start,
            style: AppTextStyles.eyebrow.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .36),
            ),
          ),
        ),
        for (final (i, row) in rows.indexed)
          CascadeIn(
            key: ValueKey(row.list.id.value),
            index: i,
            step: step,
            child: ListsDrawerTile(
              row: row,
              isCurrent: row.list.id == currentListId,
              onTap: (titleAt) => onOpen(row.list.id, titleAt),
              t: t,
            ),
          ),
        const SizedBox(height: 6),
        _DrawerAction(
          icon: Icons.add,
          label: t.lists.create,
          strong: true,
          onTap: () => _popThen(context, showCreateListSheet),
        ),
        _DrawerAction(
          icon: Icons.login_rounded,
          label: t.lists.join,
          strong: true,
          onTap: () => _popThen(context, showJoinListDialog),
        ),
      ],
    );
  }
}

/// A 48px action row: New list and Join a list ([strong], ink), and
/// Settings in the footer (secondary ink).
class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = strong ? scheme.onSurface : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            // Expanded: long labels ("Join a list with a code", or longer
            // translations) would otherwise run off the 300px drawer.
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (strong ? AppTextStyles.bodyStrong : AppTextStyles.body)
                    .copyWith(fontSize: 15, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
