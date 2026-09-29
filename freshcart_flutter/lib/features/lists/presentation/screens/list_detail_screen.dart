import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/list_detail_app_bar.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_filter_bar.dart';
import 'package:freshcart_flutter/features/sync/presentation/widgets/offline_banner.dart';
import 'package:go_router/go_router.dart';

/// One shopping list: the route shell around [ListDetailAppBar] and the
/// items.
///
/// Reads [ListDetailScreenController]; owns only what must outlive a
/// rebuild -- the search field's controller and the colour reveal's key.
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
    final t = ref.watch(translationsProvider);
    final s = ref.watch(listDetailScreenControllerProvider(widget.listId));

    // A failed *load* is the screen tier: the list is what this route is for,
    // so without it there is no screen to decorate with an error message.
    // It replaces the Scaffold rather than sitting inside its body.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        // Refreshed before navigating, not just after: /lists redirects
        // straight to whichever list comes first in the cached collection,
        // so if this list's own disappearance never made it into that
        // cache, the redirect would bounce straight back into the same
        // error. Refreshing first lets it find a still-valid list instead
        // (or the real empty state, if none are left).
        onExit: () {
          unawaited(
            ref
                .read(
                  listDetailScreenControllerProvider(widget.listId).notifier,
                )
                .refreshLists(),
          );
          context.go(Routes.lists);
        },
      );
    }

    final list = s.list;

    return Scaffold(
      drawer: s.canOpenDrawer
          ? ListsDrawer(currentListId: widget.listId)
          : null,
      appBar: ListDetailAppBar(list: list, searchField: _searchField),
      // Everything under body/ — tabs, checks, focused inputs, the quick-add
      // control, empty-state tint — sees the active shop's colour. The
      // drawer and app bar above are siblings of this, not descendants, so
      // they stay on the app's own neutral theme regardless.
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : _Body(
              list: list,
              showFilter: s.showShopFilter,
              // Scoped, not global: this is the one piece of the screen that
              // tints with the active shop. Null means "All" -- the neutral
              // brand seed, same as the rest of the app.
              seed: s.activeShopColor?.toColor() ?? AppTheme.brandSeed,
              hapticsOn: ref.watch(hapticsControllerProvider).value ?? true,
              revealKey: _revealKey,
            ),
    );
  }
}

/// The loaded screen: the shop filter strip (hidden while searching or
/// rearranging) above the items.
class _Body extends StatelessWidget {
  const _Body({
    required this.list,
    required this.showFilter,
    required this.seed,
    required this.hapticsOn,
    required this.revealKey,
  });

  final ShoppingList list;
  final bool showFilter;
  final Color seed;
  final bool hapticsOn;
  final GlobalKey<ShopThemeRevealState> revealKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The tab strip slides away while searching (§16): search results
        // already span every shop, so a filter that would only narrow them
        // back down has nothing to do here.
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
                  duration: AppMotion.durationFor(context, AppMotion.quick),
                  curve: AppMotion.enter,
                  child: Column(
                    children: [
                      ShopFilterBar(listId: list.id, revealKey: revealKey),
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
            child: ItemsSection(list: list),
          ),
        ),
      ],
    );
  }
}
