import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/lists/application/list_settings_screen/list_settings_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
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
  ListSettingsScreenController get _vm =>
      ref.read(listSettingsScreenControllerProvider(widget.listId).notifier);

  late final TextEditingController _name;
  Failure? _nameFailure;
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
      _nameFailure = null;
    });
    final result = await _vm.rename(_name.text);
    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameFailure = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(listSettingsScreenControllerProvider(widget.listId));

    void report(Failure? failure) {
      if (failure == null || !mounted) return;
      showFailureSnackBar(context, failure: failure, t: t);
    }

    // A failed load is the screen tier: without the list there is no form
    // to show, so this replaces the Scaffold rather than spinning forever.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () {
          unawaited(_vm.refreshLists());
          context.go(Routes.lists);
        },
      );
    }

    // A local, not s.list, so the null check below promotes it.
    final list = s.list;
    if (list != null) _seedNameOnce(list.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.lists.settingsTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _ListDropdown(
                  currentList: list,
                  allUserLists: s.allLists,
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
                  decoration: InputDecoration(
                    errorText: _nameFailure?.toMessage(t),
                  ),
                  onSubmitted: (value) async {
                    await _saveName();
                  },
                ),
                const SizedBox(height: 24),
                _ShopsSection(
                  shops: s.shops,
                  onToggle: (shop) async =>
                      report(await _vm.toggleShopActive(shop)),
                  // The same create flow as ManageShopsScreen's FAB and the
                  // shop tab strip's "+" pill -- one flow, every entry point.
                  onAdd: () => addShop(context, ref, widget.listId, s.shops),
                  t: t,
                ),
                const SizedBox(height: 12),
                _ClearCheckedAfterShoppingOption(
                  value: list.clearCheckedAfterShopping,
                  onChanged: (value) async =>
                      report(await _vm.setClearCheckedAfterShopping(value)),
                  t: t,
                ),
                const SizedBox(height: 24),
                // "Destructive actions sit alone at the bottom with a rule
                // above them" -- the design's own words for this screen.
                const Divider(),
                const SizedBox(height: 12),
                if (s.isOwner)
                  _SettingsRow(
                    title: t.lists.delete,
                    destructive: true,
                    onTap: () => confirmDeleteList(
                      context,
                      list: list,
                      itemCount: _vm.itemCountForDialog(),
                      t: t,
                      delete: _vm.deleteList,
                    ),
                  )
                else
                  _SettingsRow(
                    title: t.lists.leave,
                    destructive: true,
                    onTap: () => confirmLeaveList(
                      context,
                      list: list,
                      t: t,
                      leave: _vm.leaveList,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ShopsSection extends StatelessWidget {
  const _ShopsSection({
    required this.shops,
    required this.onToggle,
    required this.onAdd,
    required this.t,
  });

  final List<Shop> shops;
  final ValueChanged<Shop> onToggle;
  final VoidCallback onAdd;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    if (shops.isNotEmpty) {
      return Column(
        children: [
          Text(
            t.lists.shopsOnList.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            t.lists.shopsOnListBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Column(
            children: shops.map(
              (shop) {
                return _ShopOption(shop: shop, onToggle: onToggle);
              },
            ).toList(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAdd,
            child: Text(
              t.shops.add,
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

class _ShopOption extends StatelessWidget {
  const _ShopOption({required this.shop, required this.onToggle});

  final Shop shop;
  final ValueChanged<Shop> onToggle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: shop.isActive,
      onChanged: (_) => onToggle(shop),
      title: Text(shop.name),
    );
  }
}

/// The one preference to survive the "keep checked / clear checked" overlap
/// (decisions #64/#69/#79) -- per list, not global, and with a real trigger
/// behind it: the whole list becoming fully checked, the same moment
/// `ItemsSection`'s completion celebration already detects.
class _ClearCheckedAfterShoppingOption extends StatelessWidget {
  const _ClearCheckedAfterShoppingOption({
    required this.value,
    required this.onChanged,
    required this.t,
  });

  final bool value;
  final Translations t;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(t.lists.clearCheckedAfterShopping),
      subtitle: Text(t.lists.clearCheckedAfterShoppingBody),
    );
  }
}

class _ListDropdown extends StatelessWidget {
  const _ListDropdown({
    required this.currentList,
    required this.allUserLists,
    required this.t,
  });

  final ShoppingList currentList;
  final List<ShoppingList> allUserLists;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final currentListId = currentList.id;
    return DropdownMenu<ListId>(
      // Keyed on the name too, so a rename rebuilds the menu's own text
      // field instead of leaving the old name showing.
      key: ValueKey('${currentListId.value}:${currentList.name}'),
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
