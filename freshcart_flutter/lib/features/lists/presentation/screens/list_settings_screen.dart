import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/lists/application/list_settings_screen/list_settings_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/error_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// Settings for one list: name, shops, household, behavior, and leave or
/// delete.
///
/// Opened from a list's row in Settings. The "Managing" card at the top
/// lets you switch to another list without leaving this screen.
///
/// Household and shop management are links to their own screens
/// (`HouseholdScreen`, `ManageShopsScreen`), not copies of them
/// (decisions.md #69). Here you can only turn shops on or off.
///
/// "Clear checked after shopping" (decisions.md #79): when every item is
/// checked, the checked items are removed right away, without asking, and
/// the "all done" card isn't shown.
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

  /// The name as last saved. Used to check if the name changed, so we only
  /// save when it did.
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    // There's no Save button for the name, so tapping somewhere else saves
    // it too (not only the keyboard's Done key).
    _nameFocus = FocusNode()
      ..addListener(() {
        // Don't save twice:
        // - not while already saving (saving also removes focus);
        // - not while leaving the screen (PopScope below saves then).
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

  // The list may still be loading in initState, so the name is filled in
  // the first time build() has the list (same as EditProfileSheet).
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

    // If the list couldn't load, show an error screen. Without the list
    // there's no form to show.
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

    // Copied into a local variable, so Dart knows it's not null after the
    // check below.
    final list = s.list;
    if (list != null) _seedNameOnce(list.name);

    return PopScope(
      // Leaving with an unsaved name: save it. It goes through the lists
      // controller, which keeps existing after this screen closes.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _nameIsDirty) unawaited(_vm.rename(_name.text));
      },
      child: Scaffold(
        // v3: the bar only holds Back; the title is large, in the page.
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        body: list == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  0,
                  AppSpacing.screen,
                  40,
                ),
                children: [
                  Text(t.lists.settingsTitle, style: AppTextStyles.largeTitle),
                  const SizedBox(height: AppSpacing.xl),
                  _ManagingSwitcher(
                    current: list,
                    lists: s.allLists,
                    t: t,
                    onPick: (id) => context.go(Routes.listSettings(id)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: _sectionGap),
                  _ShopsSection(
                    shops: s.shops,
                    onToggle: (shop) async =>
                        report(await _vm.toggleShopActive(shop)),
                    // Same "add shop" flow as everywhere else.
                    onAdd: () => addShop(context, ref, widget.listId, s.shops),
                    onManage: () =>
                        context.push(Routes.manageShops(widget.listId)),
                    t: t,
                  ),
                  const SizedBox(height: _sectionGap),
                  SettingsSection(
                    label: t.household.title,
                    children: [
                      // Each member opens Household, where members are
                      // managed (decisions.md #69: link, don't copy).
                      for (final member in list.members)
                        _MemberRow(
                          member: member,
                          t: t,
                          onTap: () =>
                              context.push(Routes.household(widget.listId)),
                        ),
                      // v3: the code is right here, no need to go to
                      // Household to find it. Tap to copy.
                      _InviteCodeRow(code: list.joinCode.value, t: t),
                    ],
                  ),
                  const SizedBox(height: _sectionGap),
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
                  const SizedBox(height: _sectionGap),
                  // Leave/delete: their own card at the very bottom, away
                  // from everything else.
                  SettingsSection(
                    children: [
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
                ],
              ),
      ),
    );
  }

  /// Space above each section title (v3: 22).
  static const double _sectionGap = 22;
}

/// "Shops on this list": each shop with its colour dot and an on/off switch
/// for its tab.
///
/// Always shown, even with no shops, because it has the "Add a shop" row.
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SettingsSection(
      label: t.lists.shopsOnList,
      subtitle: t.lists.shopsOnListBody,
      children: [
        for (final shop in shops)
          MergeSemantics(
            child: SettingRow(
              leading: Container(
                width: 12,
                height: 12,
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
          leading: Icon(Icons.add, size: 18, color: muted),
          title: t.shops.add,
          titleStyle: AppTextStyles.body.copyWith(color: muted),
          onTap: onAdd,
        ),
        if (shops.isNotEmpty)
          SettingOption(title: t.lists.renameShops, onTap: onManage),
      ],
    );
  }
}

/// The "Managing" card at the top: which list you're editing. With more
/// than one list, tapping it opens a list to switch to (in place, with each
/// list's member count).
///
/// Not a Material `DropdownMenu`: that one is a text field underneath, so
/// it looked like you could type in it.
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

  /// Border width (1.5 px). Thicker than normal rows, so it looks tappable.
  static const double _border = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.t;
    final canSwitch = widget.lists.length > 1;
    final openFill = theme.colorScheme.fill;
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

/// A red row for leave/delete. No ">" arrow. Always asks "are you sure?"
/// first.
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

/// One household member: avatar, name, and "Owner" for the owner. Opens
/// Household.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.t,
    required this.onTap,
  });

  final ListMember member;
  final Translations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingRow(
      leading: UserAvatar(
        seed: member.userId.value,
        initial: initialFor(member.displayName),
        photoUrl: member.avatarPhotoUrl,
        color: member.avatarColor,
        radius: AppSizes.avatarSmall / 2,
      ),
      title: member.displayName,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.isOwner)
            Text(
              t.household.owner,
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SettingChevron(),
        ],
      ),
    );
  }
}

/// "Invite code   K7M2Q" in mono. Tapping copies the code; the code is
/// swapped for "Copied" for a moment, so the user sees it worked without a
/// toast covering the screen (same idea as `InviteCard`).
class _InviteCodeRow extends ConsumerStatefulWidget {
  const _InviteCodeRow({required this.code, required this.t});

  final String code;
  final Translations t;

  @override
  ConsumerState<_InviteCodeRow> createState() => _InviteCodeRowState();
}

class _InviteCodeRowState extends ConsumerState<_InviteCodeRow> {
  static const Duration _held = Duration(milliseconds: 1600);

  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    ref.haptic(HapticFeedback.lightImpact);
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_held, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = widget.t;
    return Semantics(
      hint: t.household.copyCode,
      child: SettingRow(
        title: t.household.inviteCode,
        titleStyle: AppTextStyles.body.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        onTap: _copy,
        trailing: AnimatedSwitcher(
          duration: AppMotion.durationFor(context, AppMotion.quick),
          child: _copied
              ? Text(
                  t.household.copied,
                  key: const ValueKey('copied'),
                  style: AppTextStyles.labelStrong.copyWith(
                    color: AppColors.success,
                  ),
                )
              : Text(
                  widget.code,
                  key: const ValueKey('code'),
                  style: AppTextStyles.code.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
