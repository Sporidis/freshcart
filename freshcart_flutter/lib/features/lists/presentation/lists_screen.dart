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

/// The app's home: every list the signed-in user belongs to.
class ListsScreen extends ConsumerWidget {
  /// Creates the lists screen.
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);
    final isEmpty = switch (lists) {
      AsyncValue<Result<List<ShoppingList>>>(
        value: Ok<List<ShoppingList>>(:final value),
      ) =>
        value.isEmpty,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.lists.title),
        actions: [
          IconButton(
            tooltip: t.lists.join,
            onPressed: () => _showJoinDialog(context, ref, t),
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
                      onPressed: () => _showCreateDialog(context, ref, t),
                      child: Text(t.lists.create),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showJoinDialog(context, ref, t),
                      child: Text(t.lists.join),
                    ),
                  ),
                ],
              ),
            ),
          Ok<List<ShoppingList>>(value: final items) => RefreshIndicator(
            onRefresh: () =>
                ref.read(listsControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _ListTile(list: items[index], t: t),
            ),
          ),
        },
      },
      // Hidden while the empty state is up: that screen already offers New
      // list as one of its two exits, and the same action twice reads as two
      // different actions.
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref, t),
              icon: const Icon(Icons.add),
              label: Text(t.lists.create),
            ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    Translations t,
  ) => showDialog<bool>(
    context: context,
    builder: (context) => NamePromptDialog(
      title: t.lists.create,
      label: t.lists.title,
      submitLabel: t.common.save,
      cancelLabel: t.common.cancel,
      onSubmit: (value) async => ref
          .read(listsControllerProvider.notifier)
          .create(value)
          .then((r) => r.map<void>((_) {})),
    ),
  );

  Future<void> _showJoinDialog(
    BuildContext context,
    WidgetRef ref,
    Translations t,
  ) => showDialog<bool>(
    context: context,
    builder: (context) => NamePromptDialog(
      title: t.lists.join,
      label: t.lists.joinCodeLabel,
      submitLabel: t.common.save,
      cancelLabel: t.common.cancel,
      capitalization: TextCapitalization.characters,
      onSubmit: (value) async => ref
          .read(listsControllerProvider.notifier)
          .join(value)
          .then((r) => r.map<void>((_) {})),
    ),
  );
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.shopping_basket_outlined),
    title: Text(list.name),
    subtitle: Text(t.lists.memberCount(n: list.members.length)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go(Routes.listDetail(list.id)),
  );
}

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
