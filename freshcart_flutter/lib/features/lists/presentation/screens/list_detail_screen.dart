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
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_filter_bar.dart';
import 'package:freshcart_flutter/features/sync/presentation/widgets/offline_banner.dart';
import 'package:go_router/go_router.dart';

/// The screen for one shopping list: the app bar ([ListDetailAppBar]) and
/// the items.
///
/// Data comes from [ListDetailScreenController]. This widget only keeps
/// things that must survive a rebuild: the search text controller and the
/// colour wave's key.
class ListDetailScreen extends ConsumerStatefulWidget {
  /// Creates the detail screen for [listId].
  const ListDetailScreen({
    required this.listId,
    this.titleFlight,
    super.key,
  });

  /// Which list to show.
  final ListId listId;

  /// Set when this list was picked in the drawer: its name flies into the
  /// header (design v3).
  final ListTitleFlight? titleFlight;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  /// The search field's text controller. Kept here, not recreated on every
  /// build, otherwise the cursor would jump while typing.
  final TextEditingController _searchField = TextEditingController();

  /// Lets [ShopFilterBar] start the colour wave in the items area. It needs
  /// a key because the bar isn't inside the wave widget.
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

    // If the list couldn't load, show a full error screen instead of the
    // normal one.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        // Reload the lists BEFORE going to /lists. If the old lists still
        // contain this broken list, /lists would send us straight back
        // here, to the same error.
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

    return ListTitleFlight.scope(
      flight: widget.titleFlight,
      child: Scaffold(
        // v3: the drawer dims the list to 42%.
        drawerScrimColor: const Color(0x6B141412),
        drawer: s.canOpenDrawer
            ? ListsDrawer(currentListId: widget.listId)
            : null,
        appBar: ListDetailAppBar(
          list: list,
          searchField: _searchField,
          // The header's tint grows from wherever the items' wave did.
          waveOrigin: () => _revealKey.currentState?.lastGlobalOrigin,
        ),
        // Everything in the body uses the selected shop's colour. The drawer
        // and app bar are outside it, so they stay neutral.
        body: list == null
            ? const Center(child: CircularProgressIndicator())
            : _Body(
                list: list,
                showFilter: s.showShopFilter,
                // Only this part changes colour with the shop. Null means
                // "All" (neutral colours).
                seed: s.activeShopColor?.toColor() ?? AppTheme.brandSeed,
                hapticsOn: ref.watch(hapticsControllerProvider).value ?? true,
                revealKey: _revealKey,
              ),
      ),
    );
  }
}

/// The screen once loaded: shop tabs (hidden while searching or
/// rearranging), with the items below.
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
        // The tabs slide away while searching, because search looks in
        // all shops anyway.
        AnimatedSize(
          duration: AppMotion.durationFor(context, AppMotion.standard),
          curve: AppMotion.enter,
          child: !showFilter
              ? const SizedBox(width: double.infinity)
              // A simple fade here, not the colour wave. The tabs have
              // their own selected/unselected animation, and the wave's
              // screenshot would hide it. See decisions.md #86.
              : AnimatedTheme(
                  data: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.dark(seed)
                      : AppTheme.light(seed),
                  duration: AppMotion.durationFor(context, AppMotion.quick),
                  curve: AppMotion.enter,
                  // No divider below: in v3 the header's tint ends where
                  // the strip begins, which is separation enough.
                  child: ShopFilterBar(listId: list.id, revealKey: revealKey),
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
