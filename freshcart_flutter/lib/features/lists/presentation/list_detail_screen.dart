import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// One shopping list.
///
/// Shows the list's identity, its members and its join code. The items live
/// here too, but they arrive in phase 6 — this screen is the slot they drop
/// into, and proving the route, the fetch and the failure paths work is what
/// phase 5 is for.
class ListDetailScreen extends ConsumerWidget {
  /// Creates the detail screen for [listId].
  const ListDetailScreen({required this.listId, super.key});

  /// Which list to show.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final list = ref.watch(listByIdProvider(listId));

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
        AsyncError<Result<ShoppingList>>() => Center(
          child: Text(t.errors.unexpected),
        ),
        AsyncOutcome<ShoppingList>(:final value?) => switch (value) {
          Err<ShoppingList>(:final failure) => Center(
            child: Text(failure.toMessage(t)),
          ),
          Ok<ShoppingList>(value: final shoppingList) => Column(
            children: [
              _Detail(list: shoppingList, t: t),
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
