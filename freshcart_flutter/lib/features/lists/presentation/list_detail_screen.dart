import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
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
    final notifier = _seedColor;
    if (notifier != null) {
      scheduleMicrotask(() => notifier.select(null));
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (list) {
          AsyncOutcome<ShoppingList>(value: Ok<ShoppingList>(:final value)) =>
            value.name,
          _ => t.appName,
        }),
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
              _Detail(list: shoppingList, t: t),
              ShopFilterBar(listId: listId),
              const Divider(height: 1),
              Expanded(child: ItemsSection(list: shoppingList)),
            ],
          ),
        },
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(t.lists.memberCount(n: list.members.length)),
      subtitle: Text('${t.lists.joinCodeLabel}: ${list.joinCode.value}'),
      children: [
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: Text(t.lists.joinCodeLabel),
          subtitle: SelectableText(
            list.joinCode.value,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            t.lists.memberCount(n: list.members.length),
            style: theme.textTheme.titleSmall,
          ),
        ),
        for (final member in list.members)
          ListTile(
            leading: CircleAvatar(
              child: Text(
                member.displayName.characters.firstOrNull?.toUpperCase() ?? '?',
              ),
            ),
            title: Text(member.displayName),
            trailing: member.isOwner ? const Icon(Icons.star_outline) : null,
          ),
      ],
    );
  }
}
