import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
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
class ListsScreen extends ConsumerWidget {
  /// Creates the lists screen.
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);

    // The one-shot redirect: as soon as there's at least one list, this is
    // not where the user is meant to be. Mirrors SplashScreen's own
    // ref.listen-and-context.go idiom for the same reason — a route that
    // exists only to decide where to actually go next.
    ref.listen<AsyncValue<Result<List<ShoppingList>>>>(
      listsControllerProvider,
      (
        previous,
        next,
      ) {
        // Riverpod keeps the *previous* value visible via .value while a
        // refresh is in flight (ref.invalidateSelf() does this deliberately,
        // so the old list doesn't flash away during a reload) — acting on
        // that here would redirect into a list mid-delete, using data that's
        // about to be superseded. Only a genuinely settled result counts.
        if (next.isLoading) return;
        if (next.value case Ok<List<ShoppingList>>(
          value: final items,
        ) when items.isNotEmpty) {
          context.go(Routes.listDetail(items.first.id));
        }
      },
    );

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
      // Three states, three meanings: still loading, completed-and-failed
      // (an expected Failure), and completed-with-data. AsyncError is reserved
      // for genuine bugs — see core/async/async_outcome.dart.
      body: switch (lists) {
        AsyncLoading<Result<List<ShoppingList>>>() => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError<Result<List<ShoppingList>>>() => _Message(
          text: t.errors.unexpected,
          onRetry: () => ref.read(listsControllerProvider.notifier).refresh(),
          retryLabel: t.common.retry,
        ),
        AsyncOutcome<List<ShoppingList>>(:final value?) => switch (value) {
          Err<List<ShoppingList>>(:final failure) => _Message(
            text: failure.toMessage(t),
            onRetry: () => ref.read(listsControllerProvider.notifier).refresh(),
            retryLabel: t.common.retry,
          ),
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
                  const SizedBox(height: 9),
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
        },
      },
    );
  }
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
) => showDialog<bool>(
  context: context,
  builder: (context) => NamePromptDialog(
    title: t.lists.create,
    label: t.lists.title,
    submitLabel: t.common.save,
    cancelLabel: t.common.cancel,
    onSubmit: (value) async => container
        .read(listsControllerProvider.notifier)
        .create(value)
        .then((r) => r.map<void>((_) {})),
  ),
);

/// Opens the "Join a list" dialog. Top-level for the same reason as
/// [showCreateListDialog], and takes a [ProviderContainer] for the same
/// reason too.
Future<void> showJoinListDialog(
  BuildContext context,
  ProviderContainer container,
  Translations t,
) => showDialog<bool>(
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
        .then((r) => r.map<void>((_) {})),
  ),
);

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.onRetry,
    required this.retryLabel,
  });

  final String text;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}
