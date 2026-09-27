import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/items/application/screen/items_screen_controller.dart';
import 'package:freshcart_flutter/features/items/application/screen/items_screen_state.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_detail_app_bar.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/shop_filter_bar.dart';
import 'package:freshcart_flutter/features/sync/presentation/widgets/offline_banner.dart';
import 'package:go_router/go_router.dart';

/// One shopping list: the route shell around [ListDetailAppBar] and the
/// items.
///
/// Owns what outlives a rebuild -- the search field's controller, the
/// colour reveal's key -- plus loading and the screen-tier load failure.
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
        : activeShopColor.toColor();
    final hapticsOn = ref.watch(hapticsControllerProvider).value ?? true;

    final loaded = list.dataOrNull;

    // The drawer and filter strip only need the mode; the app bar and the
    // items area read the rest of this controller themselves.
    final mode = loaded == null
        ? ItemsMode.browse
        : ref.watch(
            itemsScreenControllerProvider(loaded).select((s) => s.mode),
          );

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
      appBar: ListDetailAppBar(list: loaded, searchField: _searchField),
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
