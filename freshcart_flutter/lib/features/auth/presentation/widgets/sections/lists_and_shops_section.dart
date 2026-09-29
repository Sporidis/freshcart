import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/settings_options/section_label.dart';
import 'package:freshcart_flutter/features/lists/application/list_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "Lists & shops" group: doors into managing lists,
/// shops, and the household for [firstList].
class ListsAndShopsSection extends ConsumerWidget {
  const ListsAndShopsSection({required this.t, this.allUserLists, super.key});

  final Translations t;
  final List<ShoppingList>? allUserLists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          text: t.settings.listsAndShops.toUpperCase(),
          subtitle: t.settings.listsAndShopsSubtitle,
        ),
        const SizedBox(height: 12),
        if (allUserLists != null && allUserLists!.isNotEmpty) ...[
          for (final list in allUserLists!)
            _ListOption(
              id: list.id,
              onTap: () => context.push(Routes.listSettings(list.id)),
              isOpen: list.id == allUserLists!.first.id,
            ),

          TextButton(
            onPressed: () {},
            // onPressed: () => context.push(Routes.createList),
            child: Text(
              t.lists.create,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListOption extends ConsumerWidget {
  const _ListOption({
    required this.id,
    required this.onTap,
    this.isOpen = false,
  });

  final ListId id;
  final VoidCallback onTap;
  final bool isOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(listByIdProvider(id)).dataOrNull;

    final shops = ref.watch(shopsControllerProvider(id)).dataOrNull;
    final members = list?.members ?? [];

    return ListTile(
      title: Text(list?.name ?? ''),
      subtitle: Row(
        children: [
          if (isOpen) Text('${t.settings.openNow} · '),
          if (shops != null) Text(t.settings.shopCount(n: shops.length)),
          if (members.isNotEmpty)
            Text(' · ${t.settings.memberCount(n: members.length)}'),
        ],
      ),
      onTap: onTap,
    );
  }
}
