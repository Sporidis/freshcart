import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';

/// The search field with Cancel, in place of the list header's top row.
///
/// Owns its text: each time search opens, the header builds a new row, so
/// the field starts empty (closing search also clears the query).
class ItemsSearchRow extends ConsumerStatefulWidget {
  /// Creates the row that searches [list]'s items.
  const ItemsSearchRow({required this.list, super.key});

  final ShoppingList list;

  @override
  ConsumerState<ItemsSearchRow> createState() => _ItemsSearchRowState();
}

class _ItemsSearchRowState extends ConsumerState<ItemsSearchRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final vm = ref.read(itemsSectionControllerProvider(widget.list).notifier);
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: theme.colorScheme.onSurface),
    );
    return SizedBox(
      height: ModeBar.height,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.screen),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: t.search.hint,
                isDense: true,
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: vm.updateQuery,
            ),
          ),
          TextButton(onPressed: vm.closeSearch, child: Text(t.common.cancel)),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
