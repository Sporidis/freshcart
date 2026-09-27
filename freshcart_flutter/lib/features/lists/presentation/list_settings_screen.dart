import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/lists/application/list_membership_provider.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// A list's own settings — name, and doors to its members and shops.
///
/// Reached from Settings' "Manage lists" row (`docs/decisions.md` #69), not
/// from the list's own header — the design puts a near-identical screen
/// there too ("reached from the list's own header, not from global
/// settings"), but that entry point does not exist yet in this app's nav;
/// this is the one door in today, for whichever list Settings currently
/// treats as the active one.
///
/// Members and shops are rows that open the existing `HouseholdScreen` and
/// `ManageShopsScreen`, not sections rebuilt inline here — the design draws
/// them merged into one screen, but those two already work, are already
/// reachable elsewhere, and duplicating their content here would be a
/// second copy of both to keep in sync for no reader benefit.
///
/// "Clear checked after shopping" (decisions #79) means the whole list
/// becoming fully checked, the same moment `ItemsSection`'s own completion
/// celebration already detects -- turning this on suppresses that card
/// entirely for this list and clears checked items the instant the trigger
/// fires, with no prompt.
class ListSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [listId].
  const ListSettingsScreen({required this.listId, super.key});

  /// Which list this is.
  final ListId listId;

  @override
  ConsumerState<ListSettingsScreen> createState() => _ListSettingsScreenState();
}

class _ListSettingsScreenState extends ConsumerState<ListSettingsScreen> {
  late final TextEditingController _name;
  String? _nameError;
  bool _savingName = false;

  // Same reasoning as EditProfileScreen's own _nameSeeded: listByIdProvider
  // is async, so the field cannot be seeded synchronously in initState --
  // seeded instead the first time build actually sees a loaded list.
  bool _nameSeeded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listId == widget.listId) return;
    _nameSeeded = false;
    _name.clear();
  }

  void _seedNameOnce(String name) {
    if (_nameSeeded) return;
    _nameSeeded = true;
    _name.text = name;
  }

  Future<void> _saveName() async {
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    final result = await ref
        .read(listsControllerProvider.notifier)
        .rename(widget.listId, _name.text);
    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameError = switch (result) {
        Ok() => null,
        Err(:final failure) => failure.toMessage(
          ref.read(translationsProvider),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final list = ref.watch(listByIdProvider(widget.listId));
    final allUserLists =
        ref.watch(listsControllerProvider).dataOrNull ?? const [];

    final loadFailure = list.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () {
          unawaited(ref.read(listsControllerProvider.notifier).refresh());
          context.go(Routes.lists);
        },
      );
    }

    final loaded = list.dataOrNull;
    if (loaded != null) _seedNameOnce(loaded.name);

    // False until the identity resolves -- see isListOwner for why that's
    // the safe default.
    final isOwner = loaded != null && ref.watch(isListOwnerProvider(loaded));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.lists.settingsTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: loaded == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _ListDropdown(
                  currentListId: widget.listId,
                  allUserLists: allUserLists,
                  t: t,
                ),
                const SizedBox(height: 24),
                Text(
                  t.lists.nameLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('listNameField'),
                  controller: _name,
                  enabled: !_savingName,
                  decoration: InputDecoration(errorText: _nameError),
                  onSubmitted: (value) async {
                    await _saveName();
                  },
                ),
                const SizedBox(height: 24),
                _ShopsSection(
                  listId: widget.listId,
                  t: t,
                ),
                const SizedBox(height: 12),
                _ClearCheckedAfterShoppingOption(
                  listId: widget.listId,
                  value: loaded.clearCheckedAfterShopping,
                  t: t,
                ),
                const SizedBox(height: 24),
                // "Destructive actions sit alone at the bottom with a rule
                // above them" -- the design's own words for this screen.
                const Divider(),
                const SizedBox(height: 12),
                if (isOwner)
                  _SettingsRow(
                    title: t.lists.delete,
                    destructive: true,
                    onTap: () => confirmDeleteList(context, ref, loaded, t),
                  )
                else
                  _SettingsRow(
                    title: t.lists.leave,
                    destructive: true,
                    onTap: () => confirmLeaveList(context, ref, loaded, t),
                  ),
              ],
            ),
    );
  }
}

class _ShopsSection extends ConsumerWidget {
  const _ShopsSection({required this.listId, required this.t});

  final ListId listId;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUserShops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    if (allUserShops.isNotEmpty) {
      return Column(
        children: [
          Text(
            'Shops on this list'.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Each becomes a tab. Colours are shared across all your lists.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Column(
            children: allUserShops.map(
              (shop) {
                return _ShopOption(
                  shop: shop,
                  listId: listId,
                  t: t,
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              //TODO: Add logic to add a shop here
            },
            child: Text(
              'Add a shop',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _ShopOption extends ConsumerWidget {
  const _ShopOption({
    required this.shop,
    required this.listId,
    required this.t,
  });

  final Shop shop;
  final ListId listId;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: shop.isActive,
      onChanged: (_) =>
          ref.read(shopsControllerProvider(listId).notifier).toggleActive(shop),
      title: Text(shop.name),
    );
  }
}

/// The one preference to survive the "keep checked / clear checked" overlap
/// (decisions #64/#69/#79) -- per list, not global, and with a real trigger
/// behind it: the whole list becoming fully checked, the same moment
/// `ItemsSection`'s completion celebration already detects.
class _ClearCheckedAfterShoppingOption extends ConsumerWidget {
  const _ClearCheckedAfterShoppingOption({
    required this.listId,
    required this.value,
    required this.t,
  });

  final ListId listId;
  final bool value;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: value,
      onChanged: (next) => ref
          .read(listsControllerProvider.notifier)
          .setClearCheckedAfterShopping(listId, next),
      title: Text(t.lists.clearCheckedAfterShopping),
      subtitle: Text(t.lists.clearCheckedAfterShoppingBody),
    );
  }
}

class _ListDropdown extends StatelessWidget {
  const _ListDropdown({
    required this.currentListId,
    required this.allUserLists,
    required this.t,
  });

  final ListId currentListId;
  final List<ShoppingList> allUserLists;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    String? selectedListName;
    for (final list in allUserLists) {
      if (list.id == currentListId) {
        selectedListName = list.name;
        break;
      }
    }

    return DropdownMenu<ListId>(
      key: ValueKey('${currentListId.value}:$selectedListName'),
      width: MediaQuery.of(context).size.width * 0.9,
      initialSelection: currentListId,
      label: Text(
        t.lists.title,
      ),
      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),

      dropdownMenuEntries: allUserLists
          .map(
            (list) => DropdownMenuEntry<ListId>(
              value: list.id,
              label: list.name,
            ),
          )
          .toList(),
      onSelected: (selectedListId) {
        if (selectedListId == null || selectedListId == currentListId) {
          return;
        }
        context.go(Routes.listSettings(selectedListId));
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? AppColors.destructive : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      trailing: !destructive ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
