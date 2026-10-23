import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/ui/feedback/empty_state.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_state.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/create_or_join_list.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The `/lists` route. There's no "all lists" screen in the app (the
/// drawer does that), so this only shows two things:
/// - a spinner while the lists load;
/// - "No lists yet", if the user has no lists (only after deleting the
///   last one).
///
/// If the user has a list, this screen opens it straight away.
class ListsScreen extends ConsumerStatefulWidget {
  /// Creates the lists screen.
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> with RouteAware {
  // Kept here, because `ref` can't be used in dispose.
  late final _routeObserver = ref.read(listsRouteObserverProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) _routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when the user comes back to this screen (back button or back
  // swipe). Reloads the lists, because an action on the list screen (leave,
  // delete, rename) may have changed them. Same idea as
  // SessionResumeObserver, which does it when the app comes back.
  @override
  void didPopNext() {
    // Run it a moment later (in a microtask). This can be called while
    // Flutter is building, and changing a provider during a build isn't
    // allowed.
    unawaited(
      Future.microtask(
        () => ref.read(listsControllerProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);

    // `listsLandingTarget` decides which list to open. This just goes
    // there, but only while this screen is the one on top.
    ref.listen(listsLandingTargetProvider, (_, target) {
      if (target == null) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      context.go(Routes.listDetail(target));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.lists.title),
        actions: [
          IconButton(
            tooltip: t.lists.join,
            onPressed: () => showJoinListDialog(
              context,
              ProviderScope.containerOf(context, listen: false),
              t,
            ),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      // Three cases:
      // - first load, no data yet: spinner;
      // - loaded but failed: error;
      // - has data (also while reloading, so it doesn't flash a spinner).
      // AsyncError means a bug, see core/async/async_outcome.dart.
      body: switch (lists) {
        AsyncLoading<Result<List<ShoppingList>>>(value: null) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<Result<List<ShoppingList>>>() => _failure(
          const Failure.unexpected(),
          t,
        ),
        // Has data: either loaded, or reloading with the old data still
        // there. (Needed because a `when` check doesn't count for the
        // "every case handled" check, so the first case can't cover it.)
        AsyncOutcome<List<ShoppingList>>(:final value?) => _buildOutcome(
          value,
          t,
        ),
      },
    );
  }

  Widget _failure(Failure failure, Translations t) => FailureState(
    failure: failure,
    t: t,
    action: ElevatedButton(
      onPressed: () => ref.read(listsControllerProvider.notifier).refresh(),
      child: Text(t.common.retry),
    ),
  );

  Widget _buildOutcome(Result<List<ShoppingList>> value, Translations t) =>
      switch (value) {
        Err<List<ShoppingList>>(:final failure) => _failure(failure, t),
        Ok<List<ShoppingList>>(value: final items) when items.isEmpty =>
          EmptyState(
            icon: Icons.checklist_outlined,
            title: t.lists.emptyTitle,
            body: t.lists.emptyBody,
            // Two buttons here (create and join), so the user isn't stuck
            // with only one option.
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => showCreateListSheet(
                      context,
                      ProviderScope.containerOf(context, listen: false),
                      t,
                    ),
                    child: Text(t.lists.create),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showJoinListDialog(
                      context,
                      ProviderScope.containerOf(context, listen: false),
                      t,
                    ),
                    child: Text(t.lists.join),
                  ),
                ),
              ],
            ),
          ),
        // The user has lists: the listener above opens one right away. So
        // this only shows for one frame, a spinner is enough.
        Ok<List<ShoppingList>>() => const Center(
          child: CircularProgressIndicator(),
        ),
      };
}
