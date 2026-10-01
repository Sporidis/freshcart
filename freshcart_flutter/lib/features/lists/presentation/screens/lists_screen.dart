import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/name_prompt_dialog.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// Landed on only long enough to decide where a signed-in user actually
/// belongs — there is no "all lists" screen in the design (Flow 10: "the
/// drawer answers 'which list?' and nothing else"), so this route exists
/// for exactly two real states: briefly, while [listsControllerProvider]
/// is still loading, and genuinely, for the one case the design *does*
/// call for — someone with no lists at all (only reachable by deleting
/// their last one; §11's "No lists yet" empty state). Anyone with at least
/// one list is sent straight to it and never sees this screen render its
/// populated case, because there isn't one any more.
class ListsScreen extends ConsumerStatefulWidget {
  /// Creates the lists screen.
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) listsRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    listsRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // Fired when this screen is revealed because the route above it (list
  // detail, or one of its own sub-routes) was popped -- crucially including
  // the OS back-swipe gesture, which nothing else here observes. Forces a
  // fresh fetch rather than trusting whatever this screen's listsController
  // was left showing: an action taken from the detail screen (leave, delete,
  // rename) invalidates it and navigates away without waiting, so a swipe
  // back can land here mid-refresh -- or, rarer, atop a refresh that got
  // orphaned entirely (autoDispose can tear a provider down mid-fetch with
  // nothing left to deliver its result to). Either way this is exactly what
  // the manual Retry button already does by hand; see also
  // SessionResumeObserver, the same recovery for the background/foreground
  // case.
  @override
  void didPopNext() {
    // Deferred: this can fire mid-build (the pop notification is flushed
    // from inside the Navigator's own rebuild), and invalidating a provider
    // synchronously there violates Flutter's "no setState during build" rule.
    // The microtask runs after the current build finishes either way.
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

    // Where to land is decided in `listsLandingTarget`; this only performs
    // the navigation, and only while this route is the visible one.
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
      // Three states, three meanings: genuinely still loading (no previous
      // value at all), completed-and-failed (an expected Failure), and
      // completed-with-data -- which a refresh-in-flight also counts as, so
      // it doesn't get blanked by a spinner every time didPopNext forces one.
      // AsyncError is reserved for genuine bugs — see core/async/async_outcome.dart.
      body: switch (lists) {
        AsyncLoading<Result<List<ShoppingList>>>(value: null) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<Result<List<ShoppingList>>>() => _failure(
          const Failure.unexpected(),
          t,
        ),
        // Covers both a settled AsyncData and an AsyncLoading that's
        // refreshing with a previous value still attached -- .value is
        // non-null either way, so both render identically. A `when` guard
        // doesn't count toward exhaustiveness the way a type/field pattern
        // does, which is why the first case above needs pairing with this
        // one rather than an unconditional AsyncLoading case of its own.
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
            // The one empty that earns two actions: reached only by
            // deleting your last list, so a single exit would strand
            // anyone who got here by joining rather than creating.
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => showCreateListDialog(
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
        // Reachable for at most one frame: the ref.listen above redirects
        // away the instant items is non-empty, so there is nothing worth
        // building here beyond the same spinner the loading case shows —
        // building the actual list would be dead code, visible to no one.
        Ok<List<ShoppingList>>() => const Center(
          child: CircularProgressIndicator(),
        ),
      };
}

/// Opens the "New list" dialog. Top-level (not a method on [ListsScreen]) so
/// [ListsDrawer]'s own inline "New list" row can call the exact same flow
/// rather than a second copy of it -- one dialog, two entry points, the same
/// reasoning as decisions #63's item sheet.
///
/// Takes the [ProviderContainer] itself rather than a [WidgetRef]: the
/// drawer's own row pops the drawer (closing, and eventually disposing, the
/// widget whose `ref` that would otherwise be) before this dialog's
/// `onSubmit` ever runs, sometimes seconds later once someone actually
/// types a name -- a `WidgetRef` captured from that widget is unsafe to read
/// by then, `Riverpod` says so explicitly (`ConsumerWidgetElement.read`
/// asserts the element is not disposed). The container itself has no such
/// lifecycle tied to one widget, so grabbing it once via
/// `ProviderScope.containerOf(context, listen: false)`, before anything
/// pops, sidesteps the whole problem.
Future<void> showCreateListDialog(
  BuildContext context,
  ProviderContainer container,
  Translations t,
) async {
  ShoppingList? created;
  await showDialog<bool>(
    context: context,
    builder: (context) => NamePromptDialog(
      title: t.lists.create,
      label: t.lists.title,
      submitLabel: t.common.save,
      cancelLabel: t.common.cancel,
      onSubmit: (value) async => container
          .read(listsControllerProvider.notifier)
          .create(value)
          .then((r) => r.map<void>((list) => created = list)),
    ),
  );
  if (created case final list?) await _openNewList(container, list.id);
}

/// Opens the "Join a list" dialog. Top-level for the same reason as
/// [showCreateListDialog], and takes a [ProviderContainer] for the same
/// reason too.
Future<void> showJoinListDialog(
  BuildContext context,
  ProviderContainer container,
  Translations t,
) async {
  ShoppingList? joined;
  await showDialog<bool>(
    context: context,
    builder: (context) => NamePromptDialog(
      title: t.lists.join,
      label: t.lists.joinCodeLabel,
      submitLabel: t.common.save,
      cancelLabel: t.common.cancel,
      capitalization: TextCapitalization.characters,
      onSubmit: (value) async => container
          .read(listsControllerProvider.notifier)
          .join(value)
          .then((r) => r.map<void>((list) => joined = list)),
    ),
  );
  if (joined case final list?) await _openNewList(container, list.id);
}

/// Takes the user straight into a list they just created or joined -- the
/// whole point of making one is to start filling it.
///
/// Through the router itself, not a `BuildContext`: by now the widget that
/// opened the dialog may be gone (the drawer closes before the dialog even
/// opens), the same lifecycle problem the [ProviderContainer] parameter
/// already solves. Also remembered as the last-opened list, exactly as
/// opening it from the drawer is, so a cold start comes back here too.
Future<void> _openNewList(ProviderContainer container, ListId id) async {
  container.read(appRouterProvider).go(Routes.listDetail(id));
  await container.read(lastOpenedListControllerProvider.notifier).select(id);
}
