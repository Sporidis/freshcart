import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
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
/// Deliberately missing: "Clear checked after shopping." The design shows
/// it as a toggle, but nothing about *when a shop is done* exists in the
/// domain yet — it would need a real decision about what "after shopping"
/// means (all items checked? every shop tab clear? a person tapping
/// something explicit?) and a new field on `ShoppingList`, not just a
/// switch on a settings row. Left out rather than wired to a guess.
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

    final currentUser = ref.watch(currentUserIdProvider).dataOrNull;
    // Until the identity resolves, assume membership rather than ownership --
    // the same default _ListMenu uses, for the same reason: the reversible
    // action (leave) is the safe one to offer.
    final isOwner =
        loaded != null && currentUser != null && loaded.isOwnedBy(currentUser);

    final shopCount = ref
        .watch(shopsControllerProvider(widget.listId))
        .dataOrNull
        ?.length;

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
                Text(
                  t.lists.nameLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  enabled: !_savingName,
                  decoration: InputDecoration(errorText: _nameError),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _savingName ? null : _saveName,
                    child: Text(t.common.save),
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsRow(
                  title: t.settings.household,
                  onTap: () => context.push(Routes.household(widget.listId)),
                ),
                _SettingsRow(
                  title: t.shops.manage,
                  trailing: shopCount?.toString(),
                  onTap: () => context.push(Routes.manageShops(widget.listId)),
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String title;
  final VoidCallback onTap;
  final String? trailing;
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(trailing!, style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
          ],
          if (!destructive) const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
