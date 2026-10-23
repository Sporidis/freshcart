import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/move_to_shop_sheet.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/member_avatar_stack.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/mode_bar.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/mode_bar_pill.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/tint_wave.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The list screen's header (design v3).
///
/// Its background carries the tab's colour, faintly: the shop's colour at
/// 10% (18% in dark), or ink at 3.5% on All. It changes with the same wave
/// as the items, from the same point ([TintWave]).
///
/// Browsing: menu · "Basket" eyebrow over the list name · search · the
/// household's avatars (→ List settings), with the tab's progress bar
/// underneath. Selecting or rearranging: the ink [ModeBar] takes the top
/// row's place, so the whole header reads as "you're in a mode". Searching:
/// a search field.
///
/// It reads the [ItemsMode] from [ItemsSectionController], same as the
/// items. [list] is null while loading; then only the app name shows.
class ListDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ListDetailAppBar({
    required this.list,
    required this.searchField,
    required this.waveOrigin,
    super.key,
  });

  /// Where the shop-switch wave started; see [TintWave.originOf].
  final Offset? Function() waveOrigin;

  final ShoppingList? list;

  /// The search text controller (owned by the screen). Cleared when search
  /// opens or closes, so old text never shows.
  final TextEditingController searchField;

  static const double _rowHeight = ModeBar.height;
  static const double _progressHeight = 22;

  @override
  Size get preferredSize => const Size.fromHeight(_rowHeight + _progressHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final list = this.list;
    final items = list == null
        ? null
        : ref.watch(itemsSectionControllerProvider(list));
    final vm = list == null
        ? null
        : ref.read(itemsSectionControllerProvider(list).notifier);
    final mode = items?.mode ?? ItemsMode.browse;

    void report(Failure? failure) =>
        showFailureSnackBar(context, failure: failure, t: t);

    Future<void> moveSelected() async {
      // Cancelled (null): keep the selection as it was.
      final outcome = await showMoveToShopSheet(
        context,
        shops: items?.shops ?? const <Shop>[],
        t: t,
      );
      if (outcome == null || vm == null) return;
      final previous = vm.shopsOfSelection();
      final failure = await vm.moveSelected(outcome.shopId);
      if (!context.mounted) return;
      if (failure != null) return report(failure);
      final to = outcome.shopId;
      showUndoToast(
        context,
        message: t.items.moved(
          n: previous.length,
          shop: to == null
              ? t.shops.none
              : items?.shopFor(to)?.name ?? t.shops.none,
        ),
        t: t,
        onUndo: () async => report(await vm.moveBack(previous)),
      );
    }

    void deleteSelected() {
      if (vm == null) return;
      final (:count, :undo) = vm.deleteSelectedWithUndo();
      showUndoToast(
        context,
        message: t.items.deleted(n: count),
        t: t,
        onUndo: undo,
        // Visible exactly as long as Undo still works.
        duration: ItemsController.swipeUndoWindow,
      );
    }

    void finishRearrange() {
      vm?.stopRearrange();
      showUndoToast(context, message: t.items.orderSaved, t: t, tick: true);
    }

    final Widget row;
    if (list == null || items == null || vm == null) {
      row = _BrowseRow(key: const ValueKey('loading'), list: null, t: t);
    } else {
      final hasSelection = items.selection.isNotEmpty;
      row = switch (mode) {
        ItemsMode.browse => _BrowseRow(
          key: const ValueKey('browse'),
          list: list,
          t: t,
          onSearch: () {
            searchField.clear();
            vm.openSearch();
          },
        ),
        ItemsMode.search => _SearchRow(
          key: const ValueKey('search'),
          controller: searchField,
          t: t,
          onChanged: vm.updateQuery,
          onCancel: () {
            searchField.clear();
            vm.closeSearch();
          },
        ),
        ItemsMode.select => ModeBar(
          key: const ValueKey('select'),
          title: Text(t.items.selectedCount(n: items.selection.length)),
          onClose: vm.clearSelection,
          closeLabel: t.common.cancel,
          actions: [
            ModeBarPill(
              label: t.common.move,
              onTap: hasSelection ? moveSelected : null,
            ),
            ModeBarPill(
              label: t.common.delete,
              destructive: true,
              onTap: hasSelection ? deleteSelected : null,
            ),
          ],
        ),
        ItemsMode.rearrange => ModeBar(
          key: const ValueKey('rearrange'),
          title: Text(t.items.rearrangeHeader),
          subtitle: switch (items.activeShop) {
            null => t.items.rearrangeScopeAll(list: list.name),
            final shop => t.items.rearrangeScopeShop(shop: shop.name),
          },
          actions: [
            ModeBarPill(
              label: t.common.done,
              emphasized: true,
              onTap: finishRearrange,
            ),
          ],
        ),
      };
    }

    final accent =
        items?.activeShop?.color.toColor() ?? theme.colorScheme.onSurface;
    final tintAlpha = items?.activeShop == null
        ? .035
        : theme.brightness == Brightness.dark
        ? .18
        : .10;
    final tint = Color.alphaBlend(
      accent.withValues(alpha: tintAlpha),
      theme.scaffoldBackgroundColor,
    );

    return AppBar(
      automaticallyImplyLeading: false,
      // Under the status bar too, as one tinted block with the header.
      flexibleSpace: TintWave(color: tint, originOf: waveOrigin),
      toolbarHeight: _rowHeight,
      // The row widgets lay themselves out edge to edge, so the mode bar's
      // ink reaches both sides.
      titleSpacing: 0,
      title: AnimatedSwitcher(
        duration: AppMotion.durationFor(context, AppMotion.modeBar),
        switchInCurve: AppMotion.ios,
        switchOutCurve: AppMotion.exitStd,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        child: row,
      ),
      bottom: _ProgressBar(
        height: _progressHeight,
        // Search looks across every tab, so the tab's progress means
        // nothing there.
        visible: items != null && mode != ItemsMode.search,
        done: items?.checkedCount ?? 0,
        total: items?.visibleCount ?? 0,
        color: items?.activeShop?.color.toColor() ?? theme.colorScheme.primary,
        t: t,
      ),
    );
  }
}

/// Menu · eyebrow and list name · search · avatars.
class _BrowseRow extends StatelessWidget {
  const _BrowseRow({
    required this.list,
    required this.t,
    this.onSearch,
    super.key,
  });

  final ShoppingList? list;
  final Translations t;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = this.list;
    final onSearch = this.onSearch;
    return SizedBox(
      height: ListDetailAppBar._rowHeight,
      child: Row(
        children: [
          const SizedBox(width: 2),
          const _MenuButton(),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.items.listEyebrow,
                  style: AppTextStyles.secondaryStrong.copyWith(
                    fontSize: 13,
                    height: 16 / 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (list == null)
                  Text(t.appName, style: _titleStyle(theme))
                else
                  _ListTitle(list: list, t: t, style: _titleStyle(theme)),
              ],
            ),
          ),
          if (onSearch != null)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: t.search.hint,
              onPressed: onSearch,
            ),
          if (list != null) _MembersButton(list: list, t: t),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  static TextStyle _titleStyle(ThemeData theme) =>
      AppTextStyles.screenTitle.copyWith(
        height: 32 / 26,
        letterSpacing: -0.4,
        color: theme.colorScheme.onSurface,
      );
}

/// The menu glyph: two full lines and a short one, so it reads as "lists",
/// not as a generic hamburger. Opens the drawer when there is one.
///
/// An [IconButton] with the standard drawer tooltip, so screen readers (and
/// tests) know it by name rather than by its look.
class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    Widget line(double width) => Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(1),
      ),
    );
    final scaffold = Scaffold.maybeOf(context);
    return IconButton(
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: scaffold != null && scaffold.hasDrawer
          ? scaffold.openDrawer
          : null,
      icon: SizedBox(
        width: 18,
        height: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [line(18), line(18), line(11)],
        ),
      ),
    );
  }
}

/// The household's avatars. Tapping them opens List settings, where the
/// household, shops and the list's own actions live.
class _MembersButton extends StatelessWidget {
  const _MembersButton({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: t.lists.settingsTitle,
    excludeSemantics: true,
    child: TapTarget(
      onTap: () => context.push(Routes.listSettings(list.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: MemberAvatarStack(
          members: list.members,
          diameter: 30,
          overlap: 8,
          borderColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    ),
  );
}

/// The search field with Cancel.
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.t,
    required this.onChanged,
    required this.onCancel,
    super.key,
  });

  final TextEditingController controller;
  final Translations t;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: theme.colorScheme.onSurface),
    );
    return SizedBox(
      height: ListDetailAppBar._rowHeight,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.screen),
          Expanded(
            child: TextField(
              controller: controller,
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
              onChanged: onChanged,
            ),
          ),
          TextButton(onPressed: onCancel, child: Text(t.common.cancel)),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// The tab's progress: a 4px bar in the tab's colour and "3 of 10". Lined
/// up with the title (60px in), not the menu button.
class _ProgressBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProgressBar({
    required this.height,
    required this.visible,
    required this.done,
    required this.total,
    required this.color,
    required this.t,
  });

  final double height;
  final bool visible;
  final int done;
  final int total;
  final Color color;
  final Translations t;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : done / total;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.durationFor(context, AppMotion.quick),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 0, AppSpacing.screen, 6),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: ColoredBox(
                    color: theme.colorScheme.fill,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fraction),
                      duration: AppMotion.durationFor(
                        context,
                        const Duration(milliseconds: 420),
                      ),
                      curve: AppMotion.enter,
                      builder: (context, value, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: AnimatedContainer(
                          duration: AppMotion.durationFor(
                            context,
                            AppMotion.standard,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                t.items.progressOf(done: done, total: total),
                style: AppTextStyles.secondaryStrong.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The list name; tap to rename. A separate widget because it uses
/// [ListDetailScreenController], while the app bar uses the items
/// controller (rule: one controller per widget).
class _ListTitle extends ConsumerStatefulWidget {
  const _ListTitle({required this.list, required this.t, required this.style});

  final ShoppingList list;
  final Translations t;
  final TextStyle style;

  @override
  ConsumerState<_ListTitle> createState() => _ListTitleState();
}

/// Plays the drawer's title flight, if this screen was opened by one: the
/// title stays hidden while a copy of the name flies into its place, then
/// shows. Once per screen.
class _ListTitleState extends ConsumerState<_ListTitle> {
  bool _flying = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    final flight = ListTitleFlight.of(context);
    if (flight == null || AppMotion.reduced(context)) return;
    _flying = true;
    // Where the title will be is only known after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Checked before touching `context`: if the title is gone by now,
      // reading its render object would throw, and in an async callback
      // that's an unhandled error (the debugger stops on it).
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        setState(() => _flying = false);
        return;
      }
      await flyListTitle(
        context,
        text: widget.list.name,
        style: widget.style,
        from: flight.from,
        to: box.localToGlobal(Offset.zero) & box.size,
      );
      if (mounted) setState(() => _flying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    // Only the owner can rename.
    final isOwner = ref.watch(
      listDetailScreenControllerProvider(list.id).select((s) => s.isOwner),
    );
    return Opacity(
      opacity: _flying ? 0 : 1,
      child: EditableListTitle(
        name: list.name,
        enabled: isOwner,
        style: widget.style,
        onRename: (name) async {
          final failure = await ref
              .read(listDetailScreenControllerProvider(list.id).notifier)
              .rename(name);
          return failure?.toMessage(widget.t);
        },
      ),
    );
  }
}
