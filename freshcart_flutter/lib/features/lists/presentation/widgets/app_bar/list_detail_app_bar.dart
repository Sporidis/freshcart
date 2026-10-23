import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/items_progress_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/items_rearrange_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/items_search_button.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/items_search_row.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/items_select_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/list_browse_row.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/tint_wave.dart';

/// The list screen's header (design v3).
///
/// Its background carries the tab's colour, faintly: the shop's colour at
/// 10% (18% in dark), or ink at 3.5% on All. It changes with the same wave
/// as the items, from the same point ([TintWave]).
///
/// The top row follows the items' [ItemsMode]: browsing shows the list
/// ([ListBrowseRow]); searching, selecting and rearranging swap in the
/// items' own rows, so the whole header reads as "you're in a mode". The
/// tab's progress bar sits underneath.
///
/// This widget only composes: what each mode's row does belongs to the
/// items feature. [list] is null while loading; then only the app name
/// shows.
class ListDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ListDetailAppBar({
    required this.list,
    required this.waveOrigin,
    super.key,
  });

  /// Where the shop-switch wave started; see [TintWave.originOf].
  final Offset? Function() waveOrigin;

  final ShoppingList? list;

  static const double _progressHeight = 22;

  @override
  Size get preferredSize =>
      const Size.fromHeight(ModeBar.height + _progressHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final list = this.list;
    final (mode, activeShop) = list == null
        ? (ItemsMode.browse, null)
        : ref.watch(
            itemsSectionControllerProvider(
              list,
            ).select((s) => (s.mode, s.activeShop)),
          );

    final Widget row = list == null
        ? ListBrowseRow(key: const ValueKey('loading'), list: null, t: t)
        : switch (mode) {
            ItemsMode.browse => ListBrowseRow(
              key: const ValueKey('browse'),
              list: list,
              t: t,
              searchButton: ItemsSearchButton(list: list),
            ),
            ItemsMode.search => ItemsSearchRow(
              key: const ValueKey('search'),
              list: list,
            ),
            ItemsMode.select => ItemsSelectBar(
              key: const ValueKey('select'),
              list: list,
            ),
            ItemsMode.rearrange => ItemsRearrangeBar(
              key: const ValueKey('rearrange'),
              list: list,
            ),
          };

    final accent = activeShop?.color.toColor() ?? theme.colorScheme.onSurface;
    final tintAlpha = activeShop == null
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
      toolbarHeight: ModeBar.height,
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
      bottom: list == null
          ? const PreferredSize(
              preferredSize: Size.fromHeight(_progressHeight),
              child: SizedBox.shrink(),
            )
          : ItemsProgressBar(list: list, height: _progressHeight),
    );
  }
}
