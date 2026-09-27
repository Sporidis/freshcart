import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/haptics/haptics_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_view_model.dart';
import 'package:freshcart_flutter/features/items/application/items_view_state.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/shop_filter_bar.dart';
import 'package:freshcart_flutter/features/sync/presentation/widgets/offline_banner.dart';
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

  /// Lets [ShopFilterBar], a sibling of the reveal rather than a
  /// descendant of it, reach across to trigger the items area's colour
  /// reveal from wherever the shop-filter tap or swipe landed.
  final GlobalKey<ShopThemeRevealState> _revealKey =
      GlobalKey<ShopThemeRevealState>();

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
    final hapticsOn = ref.watch(hapticsControllerProvider).value ?? true;

    final loaded = list.dataOrNull;

    // The header reads the same view model ItemsSection does -- one mode,
    // so the title, actions and the items area can never disagree about
    // whether we're selecting, searching or rearranging. Only once the list
    // has loaded: the view model is keyed by it.
    final items = loaded == null
        ? null
        : ref.watch(itemsViewModelProvider(loaded));
    final vm = loaded == null
        ? null
        : ref.read(itemsViewModelProvider(loaded).notifier);
    final mode = items?.mode ?? ItemsMode.browse;

    // Both clear the field alongside the view model: without it, the next
    // time search opens it would flash whatever was typed the time before.
    void openSearch() {
      _searchField.clear();
      vm?.openSearch();
    }

    void closeSearch() {
      _searchField.clear();
      vm?.closeSearch();
    }

    return Scaffold(
      // Only once there is a list to switch away from, and never while
      // selecting or rearranging -- switching lists mid-way would abandon
      // that work with no way back to it.
      drawer:
          loaded == null ||
              mode == ItemsMode.select ||
              mode == ItemsMode.rearrange
          ? null
          : ListsDrawer(currentListId: listId),
      appBar: AppBar(
        leading: _buildLeading(
          t: t,
          mode: mode,
          onCancelSelection: () => vm?.clearSelection(),
        ),
        title: _buildTitle(
          context,
          theme: theme,
          t: t,
          mode: mode,
          selectionCount: items?.selection.length ?? 0,
          onSearchChanged: (query) => vm?.updateQuery(query),
          loaded: loaded,
        ),
        actions: _buildActions(
          context,
          t: t,
          mode: mode,
          loaded: loaded,
          vm: vm,
          shops: items?.shops ?? const <Shop>[],
          onOpenSearch: openSearch,
          onCloseSearch: closeSearch,
        ),
      ),
      // Everything under body/ — tabs, checks, focused inputs, the quick-add
      // control, empty-state tint — sees the active shop's colour. The
      // drawer and app bar above are siblings of this, not descendants, so
      // they stay on the app's own neutral theme regardless.
      body: _buildBody(
        context,
        list: list,
        listId: listId,
        // Results already span every shop, and rearrange has its own header;
        // a filter strip has nothing to do in either.
        showFilter: mode == ItemsMode.browse || mode == ItemsMode.select,
        seed: scopedSeed,
        hapticsOn: hapticsOn,
        revealKey: _revealKey,
      ),
    );
  }

  /// The app bar's leading slot: a way out of selection mode. Opening the
  /// list switcher mid-select would abandon the selection with no way back
  /// to it, so the drawer hamburger is replaced with a close icon instead.
  /// Search has its own way out -- the trailing "Cancel" in [_buildActions]
  /// -- so it does not touch this slot at all. Neither active: null, so
  /// [Scaffold] falls back to its own drawer hamburger.
  Widget? _buildLeading({
    required Translations t,
    required ItemsMode mode,
    required VoidCallback onCancelSelection,
  }) {
    if (mode == ItemsMode.select) {
      return IconButton(
        icon: const Icon(Icons.close),
        tooltip: t.common.cancel,
        onPressed: onCancelSelection,
      );
    }
    // No leading icon while searching -- the reference's own search header
    // is just the bordered field plus a "Cancel" text action in the
    // trailing slot (see _buildActions), not a second way out.
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
    required ItemsMode mode,
    required int selectionCount,
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
      child: switch (mode) {
        ItemsMode.rearrange => Text(
          t.items.rearrangeHeader,
          key: const ValueKey('rearrange'),
        ),
        ItemsMode.select => Text(
          t.items.selectedCount(n: selectionCount),
          key: const ValueKey('selection'),
        ),
        ItemsMode.search => TextField(
          key: const ValueKey('search'),
          controller: _searchField,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: t.search.hint,
            isDense: true,
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface,
                width: 1.5,
              ),
            ),
          ),
          onChanged: onSearchChanged,
        ),
        ItemsMode.browse => KeyedSubtree(
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
      },
    );
  }

  /// The app bar's actions: the selection contextual bar's move/delete
  /// buttons while selecting; nothing while searching, since the field
  /// itself takes the actions' place and the back arrow in [_buildLeading]
  /// is already the way out; otherwise search/member/menu.
  List<Widget> _buildActions(
    BuildContext context, {
    required Translations t,
    required ItemsMode mode,
    required ShoppingList? loaded,
    required ItemsViewModel? vm,
    required List<Shop> shops,
    required VoidCallback onOpenSearch,
    required VoidCallback onCloseSearch,
  }) {
    void report(Failure? failure) {
      if (failure == null || !context.mounted) return;
      showFailureSnackBar(context, failure: failure, t: t);
    }

    Future<void> handleMove() async {
      // Cancelling (null) leaves the selection exactly as it was -- the
      // sheet is a detour, not a commitment the moment it opens.
      final outcome = await showModalBottomSheet<_MoveToShopOutcome>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MoveToShopSheet(shops: shops, t: t),
      );
      if (outcome == null || vm == null) return;
      report(await vm.moveSelected(outcome.shopId));
    }

    if (loaded == null || vm == null) return const [];
    return switch (mode) {
      ItemsMode.rearrange => [
        TextButton(onPressed: vm.stopRearrange, child: Text(t.common.done)),
      ],
      ItemsMode.select => [
        TextButton(onPressed: handleMove, child: Text(t.common.move)),
        TextButton(
          onPressed: () async => report(await vm.deleteSelected()),
          style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
          child: Text(t.common.delete),
        ),
      ],
      // The reference's own search header: the bordered field plus this one
      // text action, no separate leading back-arrow (_buildLeading).
      ItemsMode.search => [
        TextButton(onPressed: onCloseSearch, child: Text(t.common.cancel)),
      ],
      ItemsMode.browse => [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: t.search.hint,
          onPressed: onOpenSearch,
        ),
        _MemberAvatar(list: loaded),
        _ListMenu(list: loaded, t: t),
      ],
    };
  }

  /// The scaffold body: the loading spinner while the list is still
  /// fetching, then the shop filter (hidden while searching -- results
  /// already span every shop, so a filter that would only narrow them back
  /// down has nothing to do here) above the items.
  Widget _buildBody(
    BuildContext context, {
    required AsyncOutcome<ShoppingList> list,
    required ListId listId,
    required bool showFilter,
    required Color seed,
    required bool hapticsOn,
    required GlobalKey<ShopThemeRevealState> revealKey,
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
            // The tab strip slides away while searching (§16): search
            // results already span every shop, so a filter that would only
            // narrow them back down has nothing to do here.
            AnimatedSize(
              duration: AppMotion.durationFor(context, AppMotion.standard),
              curve: AppMotion.enter,
              child: !showFilter
                  ? const SizedBox(width: double.infinity)
                  // A plain AnimatedTheme, not ShopThemeReveal: this strip
                  // is small, low-saturation chrome (outline/onSurface
                  // tones), not the flat colour blocks the spatial reveal
                  // exists for, and it has to stay live the whole time so
                  // ShopTabPill's own active/inactive AnimatedContainer
                  // transition is never hidden under the reveal's frozen
                  // snapshot -- see decisions #86.
                  : AnimatedTheme(
                      data: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.dark(seed)
                          : AppTheme.light(seed),
                      duration: AppMotion.durationFor(
                        context,
                        AppMotion.quick,
                      ),
                      curve: AppMotion.enter,
                      child: Column(
                        children: [
                          ShopFilterBar(listId: listId, revealKey: revealKey),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
            ),
            const OfflineSyncingBanner(),
            Expanded(
              child: ShopThemeReveal(
                key: revealKey,
                seed: seed,
                hapticsOn: hapticsOn,
                child: ItemsSection(list: shoppingList),
              ),
            ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go(Routes.household(list.id)),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: me == null
              ? const CircleAvatar(radius: 16, child: Text('?'))
              : UserAvatar(
                  seed: me.userId.value,
                  initial:
                      me.displayName.characters.firstOrNull?.toUpperCase() ??
                      '?',
                  photoUrl: me.avatarPhotoUrl,
                  color: me.avatarColor,
                  radius: 16,
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

/// What [_MoveToShopSheet] resolved to -- distinct from `null`, which means
/// "dismissed without choosing", so a caller can tell "moved to no shop"
/// (untagged, a real choice) apart from "cancelled" (do nothing at all).
class _MoveToShopOutcome {
  const _MoveToShopOutcome(this.shopId);

  final ShopId? shopId;
}

/// The multi-select "Move" sheet: the same `ChoiceChip` shop picker
/// `ItemSheet` already uses for one item at a time, offered here for a
/// whole selection instead. Not extracted into a shared widget between the
/// two -- `ItemSheet`'s picker is one field among several inside a form
/// with its own save/remove flow, while this is the sheet's entire content
/// -- but the same shape (a "No shop" chip first, then one per shop, each
/// tinted with its own colour) on purpose, so the picture looks the same
/// wherever it is offered.
class _MoveToShopSheet extends StatelessWidget {
  const _MoveToShopSheet({required this.shops, required this.t});

  final List<Shop> shops;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sheetH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.items.moveTo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.shops.none),
                  selected: false,
                  onSelected: (_) => Navigator.of(
                    context,
                  ).pop(const _MoveToShopOutcome(null)),
                ),
                for (final shop in shops)
                  ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(shop.color.argb),
                      radius: 8,
                    ),
                    label: Text(shop.name),
                    selected: false,
                    onSelected: (_) => Navigator.of(
                      context,
                    ).pop(_MoveToShopOutcome(shop.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
