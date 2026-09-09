import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/add_item_field.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_editor_dialog.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';

/// The items of one list, with the add field pinned underneath.
class ItemsSection extends ConsumerWidget {
  /// Creates the section for [list].
  const ItemsSection({required this.list, super.key});

  /// The list whose items to show. Members come from here so a checked-off
  /// item can name the person who ticked it without another request.
  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final items = ref.watch(itemsControllerProvider(list.id));
    final controller = ref.read(itemsControllerProvider(list.id).notifier);

    /// Shows the message behind a rolled-back optimistic update.
    ///
    /// Without this a row would tick, untick itself and leave the user
    /// wondering whether they mis-tapped.
    void report(Failure? failure) {
      if (failure == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.toMessage(t))),
      );
    }

    return Column(
      children: [
        Expanded(
          child: switch (items) {
            AsyncLoading<Result<List<ShoppingItem>>>() => const Center(
              child: CircularProgressIndicator(),
            ),
            AsyncError<Result<List<ShoppingItem>>>() => Center(
              child: Text(t.errors.unexpected),
            ),
            AsyncOutcome<List<ShoppingItem>>(:final value?) => switch (value) {
              Err<List<ShoppingItem>>(:final failure) => Center(
                child: Text(failure.toMessage(t)),
              ),
              Ok<List<ShoppingItem>>(value: final rows) when rows.isEmpty =>
                Center(child: Text(t.items.empty)),
              Ok<List<ShoppingItem>>(value: final rows) => RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    return ItemTile(
                      item: item,
                      t: t,
                      checkedByName: _nameFor(item.checkedBy),
                      onToggle: () async =>
                          report(await controller.toggle(item)),
                      onDelete: () async =>
                          report(await controller.remove(item)),
                      onEdit: () async {
                        final edit = await showDialog<ItemEdit>(
                          context: context,
                          builder: (context) =>
                              ItemEditorDialog(item: item, t: t),
                        );
                        if (edit == null) return;
                        report(
                          await controller.save(
                            _applyEdit(item, edit, ref),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            },
          },
        ),
        AddItemField(
          t: t,
          onSubmit: (name) async {
            final failure = await controller.add(name: name);
            report(failure);
            return failure == null;
          },
        ),
      ],
    );
  }

  /// Resolves a user id to a member's display name using the list we already
  /// hold, rather than spending a request per checked row.
  String? _nameFor(UserId? userId) {
    if (userId == null) return null;
    return list.memberFor(userId)?.displayName;
  }

  ShoppingItem _applyEdit(ShoppingItem item, ItemEdit edit, WidgetRef ref) {
    final trimmedNote = edit.noteText?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    return item.copyWith(
      name: edit.name.trim(),
      quantity: edit.quantity,
      // A note's author is whoever last wrote it; the timestamp is local only
      // until the server echoes the stored row back.
      note: hasNote
          ? Note(
              text: trimmedNote,
              authorId: item.note?.authorId ?? item.addedBy,
              updatedAt: DateTime.now().toUtc(),
            )
          : null,
    );
  }
}
