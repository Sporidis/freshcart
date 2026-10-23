import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The "Managing" card at the top: which list you're editing. With more
/// than one list, tapping it opens a list to switch to (in place, with each
/// list's member count).
///
/// Not a Material `DropdownMenu`: that one is a text field underneath, so
/// it looked like you could type in it.
class ListSwitcher extends StatefulWidget {
  const ListSwitcher({
    required this.current,
    required this.lists,
    required this.t,
    required this.onPick,
    super.key,
  });

  final ShoppingList current;
  final List<ShoppingList> lists;
  final Translations t;
  final ValueChanged<ListId> onPick;

  @override
  State<ListSwitcher> createState() => _ListSwitcherState();
}

class _ListSwitcherState extends State<ListSwitcher> {
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
                          _ListSwitcherRow(
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

class _ListSwitcherRow extends StatelessWidget {
  const _ListSwitcherRow({
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
