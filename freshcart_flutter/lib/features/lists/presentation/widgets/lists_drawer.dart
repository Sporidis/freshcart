import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/cascade_in.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/edit_profile_sheet.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart'
    show showCreateListDialog, showJoinListDialog;
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
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
    final rows = ref.watch(listsDrawerControllerProvider);

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
      await ref.read(listsDrawerControllerProvider.notifier).openList(id);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(t: t),
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

/// The top of the drawer (design v3): your avatar and name, with "Edit
/// profile" under it. Tap to edit your profile.
class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader({required this.t});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(profileControllerProvider).value?.valueOrNull;

    return InkWell(
      onTap: () async {
        // Close the drawer first, so the sheet rises over the list.
        Navigator.of(context).pop();
        await showEditProfileSheet(context);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          18,
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    me?.displayName ?? '',
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    t.profile.title,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
            child: _ListTile(
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
          onTap: () => _popThen(context, showCreateListDialog),
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

/// One list (design v3): its name and shop dots, and a 3px ink progress bar
/// with "4/10". The open list sits on the fill colour.
///
/// Stateful because it keeps a [GlobalKey] to [EditableListTitleState] (for
/// long-press rename). A key made inside `build()` would be new every
/// rebuild.
class _ListTile extends ConsumerStatefulWidget {
  const _ListTile({
    required this.row,
    required this.isCurrent,
    required this.onTap,
    required this.t,
  });

  final ListsDrawerRow row;
  final bool isCurrent;

  /// Opens the list, with where its name is on screen right now.
  final ValueChanged<Rect?> onTap;
  final Translations t;

  @override
  ConsumerState<_ListTile> createState() => _ListTileState();
}

class _ListTileState extends ConsumerState<_ListTile> {
  /// Lets a long-press start renaming. (A tap opens the list, so
  /// `tapToEdit` is false.)
  final _titleKey = GlobalKey<EditableListTitleState>();

  /// The name's box in global coordinates, for the title flight.
  Rect? _titleRect() {
    final box = _titleKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = widget.row;
    final list = row.list;
    final summary = row.summary;
    // Only the owner can rename. If not allowed, `startEditing` does
    // nothing.
    final isOwner = ref.watch(isListOwnerProvider(list));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: widget.isCurrent ? scheme.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => widget.onTap(_titleRect()),
          onLongPress: () => _titleKey.currentState?.startEditing(),
          child: Semantics(
            selected: widget.isCurrent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: EditableListTitle(
                          key: _titleKey,
                          name: list.name,
                          enabled: isOwner,
                          tapToEdit: false,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: scheme.onSurface,
                          ),
                          onRename: (name) async {
                            final result = await ref
                                .read(listsControllerProvider.notifier)
                                .rename(list.id, name);
                            return switch (result) {
                              Ok() => null,
                              Err(:final failure) => failure.toMessage(
                                widget.t,
                              ),
                            };
                          },
                        ),
                      ),
                      for (final color in row.shopColors)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color.toColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Until the counts load, the member count stands in.
                  if (summary == null)
                    Text(
                      widget.t.lists.memberCount(n: list.members.length),
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    _Progress(summary: summary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 3px ink bar and "4/10".
class _Progress extends StatelessWidget {
  const _Progress({required this.summary});

  final ListSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = summary.total == 0
        ? 0.0
        : summary.checkedCount / summary.total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: scheme.fill,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: AppMotion.durationFor(
                    context,
                    const Duration(milliseconds: 420),
                  ),
                  curve: AppMotion.enter,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: ColoredBox(color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${summary.checkedCount}/${summary.total}',
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
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
