import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/search_controller.dart';
import 'package:freshcart_flutter/features/items/application/selection_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/shop_filter_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// One shopping list.
///
/// Shows the list's identity, its members and its join code. The items live
/// here too, but they arrive in phase 6 — this screen is the slot they drop
/// into, and proving the route, the fetch and the failure paths work is what
/// phase 5 is for.
class ListDetailScreen extends ConsumerStatefulWidget {
  /// Creates the detail screen for [listId].
  const ListDetailScreen({required this.listId, super.key});

  /// Which list to show.
  final ListId listId;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  /// Captured while the widget is still mounted.
  ///
  /// `ref` cannot be used from `dispose` — the element is already deactivated
  /// by then — so the notifier is held onto here instead.
  ActiveSeedColor? _seedColor;

  /// Backs the header's search field once it is open. Its own controller
  /// rather than `TextEditingController(text: ...)` rebuilt from provider
  /// state every frame, which would fight the user's cursor position on
  /// every keystroke.
  final TextEditingController _searchField = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seedColor = ref.read(activeSeedColorProvider.notifier);
  }

  @override
  void dispose() {
    // Leaving the list drops its shop colour, so the lists screen is not left
    // wearing the theme of a shop the user is no longer looking at. Deferred to
    // a microtask because a provider must not be written during teardown.
    //
    // selectIfAlive, not select: the same guard as _refreshIfAlive elsewhere.
    // A fast pop-then-navigate-away can dispose activeSeedColorProvider
    // itself before this microtask runs (nothing else on the destination
    // watches it), and writing to a torn-down provider throws.
    final notifier = _seedColor;
    if (notifier != null) {
      scheduleMicrotask(() => notifier.selectIfAlive(null));
    }
    _searchField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listId = widget.listId;
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final list = ref.watch(listByIdProvider(listId));

    // A failed *load* is the screen tier: the list is what this route is for,
    // so without it there is no screen to decorate with an error message.
    // It replaces the Scaffold rather than sitting inside its body.
    final loadFailure = switch (list) {
      AsyncError<Result<ShoppingList>>() => const Failure.unexpected(),
      AsyncOutcome<ShoppingList>(value: Err<ShoppingList>(:final failure)) =>
        failure,
      _ => null,
    };
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () => context.go(Routes.lists),
      );
    }

    // The theme follows the active shop. Done as a listener rather than by
    // deriving the seed inside the theme provider, because the theme is global
    // while the filter belongs to whichever list is open — the screen is the
    // only place that knows both.
    //
    // Registered only once there is a list to show. On the error path the
    // filter and shop providers have nothing keeping them alive, so they
    // dispose as this frame builds, and a listener still firing into that
    // teardown writes to a provider that is already gone.
    ref.listen<HexColor?>(activeShopColorProvider(listId), (previous, next) {
      ref.read(activeSeedColorProvider.notifier).select(next);
    });

    final loaded = switch (list) {
      AsyncOutcome<ShoppingList>(value: Ok<ShoppingList>(:final value)) =>
        value,
      _ => null,
    };

    final selection = ref.watch(selectionControllerProvider(listId));
    final selectionMode = selection.isNotEmpty;
    final selectionNotifier = ref.read(
      selectionControllerProvider(listId).notifier,
    );

    final search = ref.watch(searchControllerProvider(listId));
    final searchNotifier = ref.read(searchControllerProvider(listId).notifier);
    // Both clear the field alongside the provider: without it, the next time
    // search opens it would flash whatever was typed the time before.
    void openSearch() {
      _searchField.clear();
      searchNotifier.open();
    }

    void closeSearch() {
      _searchField.clear();
      searchNotifier.close();
    }

    return Scaffold(
      // Only once there is a list to switch away from — the drawer's own
      // content needs nothing else, but opening it over a loading or error
      // screen would offer a way out of a state that already has one.
      drawer: loaded == null ? null : ListsDrawer(currentListId: listId),
      appBar: AppBar(
        // Selection mode replaces the drawer's hamburger with a way out of
        // selection instead -- opening the list switcher mid-select would
        // abandon the selection with no way back to it. Search does the
        // same, for the same reason.
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: t.common.cancel,
                onPressed: selectionNotifier.clear,
              )
            : search.active
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: t.common.cancel,
                onPressed: closeSearch,
              )
            : null,
        title: AnimatedSwitcher(
          // 280 ms per §16 -- its own value, distinct from the 260 ms token
          // the selection cross-fade uses; one switcher can only run one
          // duration, so this is what both transitions share.
          duration: AppMotion.durationFor(
            context,
            const Duration(milliseconds: 280),
          ),
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.enter,
          // The header cross-fades into the contextual bar (§10) or the
          // search field (§16) rather than being replaced by a whole
          // separate widget tree, so it reads as one bar changing what it
          // says, not a screen change.
          child: selectionMode
              ? Text(
                  t.items.selectedCount(n: selection.length),
                  key: const ValueKey('selection'),
                )
              : search.active
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchField,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t.search.hint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: searchNotifier.updateQuery,
                )
              : KeyedSubtree(
                  key: const ValueKey('normal'),
                  child: loaded == null
                      ? Text(t.appName)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The app's own name as a small kicker over the
                            // list's, the way the design's every list screen
                            // carries it — this is whose product this is,
                            // not what kind of screen it is.
                            Text(
                              t.appName,
                              style: AppTextStyles.labelStrong.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            EditableListTitle(
                              name: loaded.name,
                              onRename: (name) async {
                                final result = await ref
                                    .read(listsControllerProvider.notifier)
                                    .rename(loaded.id, name);
                                return switch (result) {
                                  Ok<ShoppingList>() => null,
                                  Err<ShoppingList>(:final failure) =>
                                    failure.toMessage(t),
                                };
                              },
                            ),
                          ],
                        ),
                ),
        ),
        actions: selectionMode
            ? [
                // "Move" is left out here: it would need a shop-picker
                // sheet, and there isn't one anywhere in the app yet to
                // reuse — building the app's first one just for this one
                // button is its own piece of work, not this one.
                TextButton(
                  onPressed: () async {
                    final failure = await ref
                        .read(itemsControllerProvider(listId).notifier)
                        .removeSelected(selection);
                    if (!context.mounted) return;
                    if (failure == null) {
                      selectionNotifier.clear();
                    } else {
                      showFailureSnackBar(context, failure: failure, t: t);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                  ),
                  child: Text(t.common.delete),
                ),
              ]
            // The field itself takes the actions' place while searching --
            // nothing here is meaningful mid-search, and the back arrow in
            // leading is already the way out.
            : search.active
            ? const []
            : [
                if (loaded != null) ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: t.search.hint,
                    onPressed: openSearch,
                  ),
                  _MemberAvatar(list: loaded),
                  _ListMenu(list: loaded, t: t),
                ],
              ],
      ),
      body: switch (list) {
        AsyncLoading<Result<ShoppingList>>() => const Center(
          child: CircularProgressIndicator(),
        ),
        // Both failure arms are handled above, as the screen tier.
        AsyncError<Result<ShoppingList>>() => const SizedBox.shrink(),
        AsyncOutcome<ShoppingList>(:final value?) => switch (value) {
          Err<ShoppingList>() => const SizedBox.shrink(),
          Ok<ShoppingList>(value: final shoppingList) => Column(
            children: [
              // The stakes are real here: this list is shared, so losing the
              // session would lose access to it.
              const UpgradeNudge(),
              // The tab strip slides away while searching (§16): search
              // results already span every shop, so a filter that would only
              // narrow them back down has nothing to do here.
              AnimatedSize(
                duration: AppMotion.durationFor(context, AppMotion.standard),
                curve: AppMotion.enter,
                child: search.active
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        children: [
                          ShopFilterBar(listId: listId),
                          const Divider(height: 1),
                        ],
                      ),
              ),
              Expanded(child: ItemsSection(list: shoppingList)),
            ],
          ),
        },
      },
    );
  }
}

/// The signed-in member's own avatar, opening Household on tap.
///
/// Membership and the join code used to live in an inline expansion tile on
/// this screen; both moved to Household, which the design reaches through
/// exactly this avatar. Duplicating that content here would be two places
/// showing the same thing, one of them stale the moment the other changes.
class _MemberAvatar extends ConsumerWidget {
  const _MemberAvatar({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = switch (ref.watch(currentUserIdProvider)) {
      AsyncValue<Result<UserId>>(value: Ok<UserId>(:final value)) => value,
      _ => null,
    };
    final me = currentUser == null
        ? null
        : list.members.where((m) => m.userId == currentUser).firstOrNull;
    final initial =
        me?.displayName.characters.firstOrNull?.toUpperCase() ?? '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go(Routes.household(list.id)),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

/// The list's overflow menu.
///
/// Owners and members see different verbs on purpose: leaving takes you out of
/// a list that carries on without you, while deleting ends it for the whole
/// household. Offering the wrong one is how someone destroys a shared list
/// meaning to walk away from it.
class _ListMenu extends ConsumerWidget {
  const _ListMenu({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = switch (ref.watch(currentUserIdProvider)) {
      AsyncValue<Result<UserId>>(value: Ok<UserId>(:final value)) => value,
      _ => null,
    };
    // Until the identity resolves, assume membership rather than ownership:
    // the reversible action is the safe default to offer.
    final isOwner = currentUser != null && list.isOwnedBy(currentUser);

    return PopupMenuButton<void>(
      itemBuilder: (context) => [
        // Household itself is reached through the avatar in the app bar now,
        // not the menu -- one door, not two, into the same screen.
        PopupMenuItem<void>(
          onTap: () => context.go(Routes.manageShops(list.id)),
          child: Text(t.shops.manage),
        ),
        // Owners delete, members leave -- one verb each, never both. The
        // wrong one on the wrong account is how a shared list gets destroyed
        // by somebody who only meant to walk away from it.
        if (isOwner)
          PopupMenuItem<void>(
            onTap: () => _confirmDelete(context, ref),
            child: Text(t.lists.delete),
          )
        else
          PopupMenuItem<void>(
            onTap: () => _confirmLeave(context, ref),
            child: Text(t.lists.leave),
          ),
      ],
    );
  }

  /// Deleting names the list, its member count and its item count, and is
  /// not undoable.
  ///
  /// The item count comes from [itemsControllerProvider], already watched by
  /// [ItemsSection] on this same screen — reading it here is free, not a
  /// second fetch. It is a plain read rather than a watch: the dialog is
  /// built once, when it opens, and does not need to react to a count that
  /// changes while it is up.
  ///
  /// A dialog rather than a snackbar with an undo, because there is nothing to
  /// undo: this one is genuinely permanent, so it is worth interrupting for.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final itemCount = switch (ref.read(itemsControllerProvider(list.id))) {
      AsyncValue<Result<List<ShoppingItem>>>(
        value: Ok<List<ShoppingItem>>(:final value),
      ) =>
        value.length,
      _ => 0,
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.lists.deleteConfirmTitle(name: list.name)),
        content: Text(
          t.lists.deleteConfirmBody(items: itemCount, n: list.members.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.lists.deleteForEveryone),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(listsControllerProvider.notifier)
        .delete(list.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok<void>():
        context.go(Routes.lists);
      case Err<void>(:final failure):
        showFailureSnackBar(context, failure: failure, t: t);
    }
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.lists.leaveConfirmTitle),
        content: Text(t.lists.leaveConfirmBody(name: list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.lists.leave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(listsControllerProvider.notifier)
        .leave(list.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok<void>():
        context.go(Routes.lists);
      case Err<void>(:final failure):
        showFailureSnackBar(context, failure: failure, t: t);
    }
  }
}
