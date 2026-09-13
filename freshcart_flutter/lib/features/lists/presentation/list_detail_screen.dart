import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
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
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
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
  /// Backs the header's search field once it is open. Its own controller
  /// rather than `TextEditingController(text: ...)` rebuilt from provider
  /// state every frame, which would fight the user's cursor position on
  /// every keystroke.
  final TextEditingController _searchField = TextEditingController();

  @override
  void dispose() {
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
    final loadFailure = list.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        // Refreshed before navigating, not just after: /lists now redirects
        // straight to whichever list comes first in listsControllerProvider
        // (there is no browser screen to land on any more), so if this
        // list's own disappearance never made it into that cached
        // collection, the redirect would just bounce straight back into the
        // same error — refreshing first is what lets it find a different,
        // still-valid list instead (or the real empty state, if none are
        // left).
        onExit: () {
          unawaited(ref.read(listsControllerProvider.notifier).refresh());
          context.go(Routes.lists);
        },
      );
    }

    // Scoped, not global: this is the one piece of the screen that tints
    // with the active shop, so it is the one place that reads this. Null
    // means "All" or no shop selected yet -- the neutral brand seed, same
    // as the rest of the app.
    final activeShopColor = ref.watch(activeShopColorProvider(listId));
    final scopedSeed = activeShopColor == null
        ? AppTheme.brandSeed
        : Color(activeShopColor.argb);

    final loaded = list.dataOrNull;

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
        leading: _buildLeading(
          t: t,
          selectionMode: selectionMode,
          searchActive: search.active,
          onCancelSelection: selectionNotifier.clear,
          onCloseSearch: closeSearch,
        ),
        title: _buildTitle(
          context,
          theme: theme,
          t: t,
          selectionMode: selectionMode,
          selectionCount: selection.length,
          search: search,
          onSearchChanged: searchNotifier.updateQuery,
          loaded: loaded,
        ),
        actions: _buildActions(
          context,
          t: t,
          selectionMode: selectionMode,
          searchActive: search.active,
          loaded: loaded,
          listId: listId,
          selection: selection,
          onClearSelection: selectionNotifier.clear,
          onOpenSearch: openSearch,
        ),
      ),
      // Everything under body/ — tabs, checks, focused inputs, the quick-add
      // control, empty-state tint — sees the active shop's colour. The
      // drawer and app bar above are siblings of this, not descendants, so
      // they stay on the app's own neutral theme regardless.
      body: AnimatedTheme(
        data: theme.brightness == Brightness.dark
            ? AppTheme.dark(scopedSeed)
            : AppTheme.light(scopedSeed),
        // Same token as the app-wide tint this replaces (decisions #71):
        // "colour tint" is `quick`, 180ms easeOutCubic.
        duration: AppMotion.durationFor(context, AppMotion.quick),
        curve: AppMotion.enter,
        child: _buildBody(
          context,
          list: list,
          listId: listId,
          searchActive: search.active,
        ),
      ),
    );
  }

  /// The app bar's leading slot: a way out of selection mode or search when
  /// either is active. Selection mode replaces the drawer's hamburger with a
  /// way out of selection instead -- opening the list switcher mid-select
  /// would abandon the selection with no way back to it. Search does the
  /// same, for the same reason. Neither active: null, so [Scaffold] falls
  /// back to its own drawer hamburger.
  Widget? _buildLeading({
    required Translations t,
    required bool selectionMode,
    required bool searchActive,
    required VoidCallback onCancelSelection,
    required VoidCallback onCloseSearch,
  }) {
    if (selectionMode) {
      return IconButton(
        icon: const Icon(Icons.close),
        tooltip: t.common.cancel,
        onPressed: onCancelSelection,
      );
    }
    if (searchActive) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: t.common.cancel,
        onPressed: onCloseSearch,
      );
    }
    return null;
  }

  /// The app bar's title. Cross-fades between the normal list-name header,
  /// the selection count, and the search field (§16) rather than being
  /// replaced by a whole separate widget tree, so it reads as one bar
  /// changing what it says, not a screen change.
  Widget _buildTitle(
    BuildContext context, {
    required ThemeData theme,
    required Translations t,
    required bool selectionMode,
    required int selectionCount,
    required ({bool active, String query}) search,
    required ValueChanged<String> onSearchChanged,
    required ShoppingList? loaded,
  }) {
    return AnimatedSwitcher(
      // 280 ms per §16 -- its own value, distinct from the 260 ms token
      // the selection cross-fade uses; one switcher can only run one
      // duration, so this is what both transitions share.
      duration: AppMotion.durationFor(
        context,
        const Duration(milliseconds: 280),
      ),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.enter,
      child: selectionMode
          ? Text(
              t.items.selectedCount(n: selectionCount),
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
              onChanged: onSearchChanged,
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
    );
  }

  /// The app bar's actions: the selection contextual bar's delete button
  /// while selecting; nothing while searching, since the field itself takes
  /// the actions' place and the back arrow in [_buildLeading] is already the
  /// way out; otherwise search/member/menu.
  List<Widget> _buildActions(
    BuildContext context, {
    required Translations t,
    required bool selectionMode,
    required bool searchActive,
    required ShoppingList? loaded,
    required ListId listId,
    required Set<ItemId> selection,
    required VoidCallback onClearSelection,
    required VoidCallback onOpenSearch,
  }) {
    if (selectionMode) {
      // "Move" is left out here: it would need a shop-picker sheet, and
      // there isn't one anywhere in the app yet to reuse — building the
      // app's first one just for this one button is its own piece of work,
      // not this one.
      return [
        TextButton(
          onPressed: () async {
            final failure = await ref
                .read(itemsControllerProvider(listId).notifier)
                .removeSelected(selection);
            if (!context.mounted) return;
            if (failure == null) {
              onClearSelection();
            } else {
              showFailureSnackBar(context, failure: failure, t: t);
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
          child: Text(t.common.delete),
        ),
      ];
    }
    if (searchActive) return const [];
    if (loaded == null) return const [];
    return [
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: t.search.hint,
        onPressed: onOpenSearch,
      ),
      _MemberAvatar(list: loaded),
      _ListMenu(list: loaded, t: t),
    ];
  }

  /// The scaffold body: the loading spinner while the list is still
  /// fetching, then the shop filter (hidden while searching -- results
  /// already span every shop, so a filter that would only narrow them back
  /// down has nothing to do here) above the items.
  Widget _buildBody(
    BuildContext context, {
    required AsyncOutcome<ShoppingList> list,
    required ListId listId,
    required bool searchActive,
  }) {
    return switch (list) {
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
              child: searchActive
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
    };
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
    final currentUser = ref.watch(currentUserIdProvider).dataOrNull;
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
    final currentUser = ref.watch(currentUserIdProvider).dataOrNull;
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
            onTap: () => confirmDeleteList(context, ref, list, t),
            child: Text(t.lists.delete),
          )
        else
          PopupMenuItem<void>(
            onTap: () => confirmLeaveList(context, ref, list, t),
            child: Text(t.lists.leave),
          ),
      ],
    );
  }
}
