import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/member_avatar_stack.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// Menu · eyebrow and list name · search · avatars.
class ListBrowseRow extends StatelessWidget {
  const ListBrowseRow({
    required this.list,
    required this.t,
    this.searchButton,
    super.key,
  });

  final ShoppingList? list;
  final Translations t;

  /// The items' search button; null while the list is loading.
  final Widget? searchButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = this.list;
    return SizedBox(
      height: ModeBar.height,
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
                  ListTitle(list: list, t: t, style: _titleStyle(theme)),
              ],
            ),
          ),
          ?searchButton,
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
