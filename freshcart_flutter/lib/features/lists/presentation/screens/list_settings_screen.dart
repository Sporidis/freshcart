import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/member_avatar_stack.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/lists/application/list_settings_screen/list_settings_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// A list's own settings: the single home for everything list-scoped
/// (Flow 10) -- its name, its shops, its household, its behaviour, and
/// leaving or deleting it.
///
/// Reached from each list's own row in Settings' "Lists & shops" group.
/// The "Managing" card at the top re-scopes the whole screen to another
/// list in place, so nobody goes back out just to switch.
///
/// Household and shop *management* are doors -- rows that open the existing
/// `HouseholdScreen` and `ManageShopsScreen` (decisions #69) -- rather than
/// second copies of those screens rebuilt inline here. Which shops are *on*
/// this list is the one shop question answered here, as switches.
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
  late final FocusNode _nameFocus;
  Failure? _nameFailure;
  bool _savingName = false;

  /// The name as last saved (or loaded) -- what "unsaved" is measured
  /// against, so leaving or blurring only writes when something changed.
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    // There is no Save button for the name, so it must not depend on the
    // keyboard's submit key alone: tapping elsewhere saves it too.
    _nameFocus = FocusNode()
      ..addListener(() {
        // Two guards, each against one save happening twice:
        // - not while a save is running: submitting disables the field,
        //   which itself drops focus;
        // - not while the route is closing: leaving drops focus too, and
        //   PopScope below already owns the save on the way out.
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (!_nameFocus.hasFocus && _nameIsDirty && !_savingName && isCurrent) {
          unawaited(_saveName());
        }
      });
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listId == widget.listId) return;
    _savedName = null;
    _name.clear();
  }

  bool get _nameIsDirty {
    final saved = _savedName;
    return saved != null && _name.text.trim() != saved;
  }

  // Same reasoning as EditProfileScreen's own _nameSeeded: the list is
  // async, so the field cannot be seeded synchronously in initState --
  // seeded instead the first time build actually sees a loaded list.
  void _seedNameOnce(String name) {
    if (_savedName != null) return;
    _savedName = name;
    _name.text = name;
  }

  Future<void> _saveName() async {
    final name = _name.text;
    setState(() {
      _savingName = true;
      _nameFailure = null;
    });
    final result = await _vm.rename(name);
    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameFailure = result;
      if (result == null) _savedName = name.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(listSettingsScreenControllerProvider(widget.listId));
    final theme = Theme.of(context);

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

    return PopScope(
      // Leaving with an unsaved name saves it on the way out rather than
      // dropping it silently. The write goes through the app-wide lists
      // controller, so it lands even after this screen is gone.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _nameIsDirty) unawaited(_vm.rename(_name.text));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.lists.settingsTitle),
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        body: list == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  _ManagingSwitcher(
                    current: list,
                    lists: s.allLists,
                    t: t,
                    onPick: (id) => context.go(Routes.listSettings(id)),
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  Text(t.lists.nameLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.gapSmall),
                  TextField(
                    key: const Key('listNameField'),
                    controller: _name,
                    focusNode: _nameFocus,
                    enabled: !_savingName,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      errorText: _nameFailure?.toMessage(t),
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  _ShopsSection(
                    shops: s.shops,
                    onToggle: (shop) async =>
                        report(await _vm.toggleShopActive(shop)),
                    // The same create flow as ManageShopsScreen and the
                    // shop strip's "+" pill -- one flow, every entry point.
                    onAdd: () => addShop(context, ref, widget.listId, s.shops),
                    onManage: () =>
                        context.push(Routes.manageShops(widget.listId)),
                    t: t,
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  SettingsSection(
                    label: t.household.title,
                    children: [
                      SettingRow(
                        title: t.household.title,
                        subtitle: t.settings.memberCount(
                          n: list.members.length,
                        ),
                        onTap: () =>
                            context.push(Routes.household(widget.listId)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatarStack(members: list.members),
                            const SettingChevron(),
                          ],
                        ),
                      ),
                      // The household screen is where the invite code
                      // lives -- this is a second, plainer door to it.
                      SettingRow(
                        leading: Icon(
                          Icons.person_add_alt_1_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: t.household.inviteSomeone,
                        titleStyle: AppTextStyles.bodyStrong.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        onTap: () =>
                            context.push(Routes.household(widget.listId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  SettingsSection(
                    label: t.lists.behaviour,
                    children: [
                      SettingToggleOption(
                        title: t.lists.clearCheckedAfterShopping,
                        description: t.lists.clearCheckedAfterShoppingBody,
                        value: list.clearCheckedAfterShopping,
                        onChanged: (value) async => report(
                          await _vm.setClearCheckedAfterShopping(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  // "Destructive actions sit alone at the bottom with a rule
                  // above them" -- the design's own words for this screen.
                  const Divider(),
                  if (s.isOwner)
                    _DangerRow(
                      title: t.lists.deleteForEveryone,
                      onTap: () => confirmDeleteList(
                        context,
                        list: list,
                        itemCount: _vm.itemCountForDialog(),
                        t: t,
                        delete: _vm.deleteList,
                      ),
                    )
                  else
                    _DangerRow(
                      title: t.lists.leave,
                      onTap: () => confirmLeaveList(
                        context,
                        list: list,
                        t: t,
                        leave: _vm.leaveList,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// "Shops on this list": which shops this list has a tab for, with each
/// shop's dot -- the only place its colour shows on this screen.
///
/// Always drawn, even with no shops: its "Add a shop" row is exactly what a
/// list with none needs (it used to vanish along with the rest).
class _ShopsSection extends StatelessWidget {
  const _ShopsSection({
    required this.shops,
    required this.onToggle,
    required this.onAdd,
    required this.onManage,
    required this.t,
  });

  final List<Shop> shops;
  final ValueChanged<Shop> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onManage;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SettingsSection(
      label: t.lists.shopsOnList,
      subtitle: t.lists.shopsOnListBody,
      children: [
        for (final shop in shops)
          MergeSemantics(
            child: SettingRow(
              leading: Container(
                width: AppSizes.shopDotLarge,
                height: AppSizes.shopDotLarge,
                decoration: BoxDecoration(
                  color: shop.color.toColor(),
                  shape: BoxShape.circle,
                ),
              ),
              title: shop.name,
              onTap: () => onToggle(shop),
              trailing: Switch(
                value: shop.isActive,
                onChanged: (_) => onToggle(shop),
              ),
            ),
          ),
        SettingRow(
          leading: Icon(Icons.add, color: primary),
          title: t.shops.add,
          titleStyle: AppTextStyles.bodyStrong.copyWith(color: primary),
          onTap: onAdd,
        ),
        if (shops.isNotEmpty)
          SettingOption(title: t.lists.renameShops, onTap: onManage),
      ],
    );
  }
}

/// The design's "Managing" card: which list this screen is about, and --
/// with more than one list -- a switcher that expands in place, no sheet and
/// no route change of its own, each row carrying that list's member count.
///
/// Replaces a Material `DropdownMenu`, which is a text field underneath:
/// it invited typing into the list's name, and sized itself off the screen
/// width rather than the layout.
class _ManagingSwitcher extends StatefulWidget {
  const _ManagingSwitcher({
    required this.current,
    required this.lists,
    required this.t,
    required this.onPick,
  });

  final ShoppingList current;
  final List<ShoppingList> lists;
  final Translations t;
  final ValueChanged<ListId> onPick;

  @override
  State<_ManagingSwitcher> createState() => _ManagingSwitcherState();
}

class _ManagingSwitcherState extends State<_ManagingSwitcher> {
  bool _open = false;

  /// The card's border: the design's 1.5 px, heavier than a row's hairline
  /// so it reads as a control rather than a row.
  static const double _border = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.t;
    final canSwitch = widget.lists.length > 1;
    final openFill = theme.colorScheme.surfaceContainer;
    final duration = AppMotion.durationFor(context, AppMotion.standard);

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.enter,
      decoration: BoxDecoration(
        color: _open ? openFill : theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: _border,
        ),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: canSwitch ? () => setState(() => _open = !_open) : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gap),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.lists.managing.toUpperCase(),
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            widget.current.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    if (canSwitch)
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: duration,
                        curve: AppMotion.enter,
                        child: Icon(
                          Icons.expand_more,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      children: [
                        for (final list in widget.lists) ...[
                          const Divider(),
                          _SwitcherRow(
                            list: list,
                            isCurrent: list.id == widget.current.id,
                            t: t,
                            onTap: () {
                              setState(() => _open = false);
                              if (list.id != widget.current.id) {
                                widget.onPick(list.id);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitcherRow extends StatelessWidget {
  const _SwitcherRow({
    required this.list,
    required this.isCurrent,
    required this.t,
    required this.onTap,
  });

  final ShoppingList list;
  final bool isCurrent;
  final Translations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: isCurrent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap,
            vertical: AppSpacing.rowVertical,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: isCurrent
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyLarge,
                    ),
                    Text(
                      t.settings.memberCount(n: list.members.length),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Icon(Icons.check, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

/// A destructive row: red, no chevron (it ends something rather than going
/// somewhere), always behind a confirm.
class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SettingRow(
    title: title,
    titleStyle: AppTextStyles.body.copyWith(
      color: Theme.of(context).colorScheme.error,
    ),
    onTap: onTap,
  );
}
