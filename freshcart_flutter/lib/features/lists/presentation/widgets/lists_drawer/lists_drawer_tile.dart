import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_drawer/lists_drawer_row.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// One list (design v3): its name and shop dots, and a 3px ink progress bar
/// with "4/10". The open list sits on the fill colour.
///
/// Stateful because it keeps a [GlobalKey] to [EditableListTitleState] (for
/// long-press rename). A key made inside `build()` would be new every
/// rebuild.
class ListsDrawerTile extends ConsumerStatefulWidget {
  const ListsDrawerTile({
    required this.row,
    required this.isCurrent,
    required this.onTap,
    required this.t,
    super.key,
  });

  final ListsDrawerRow row;
  final bool isCurrent;

  /// Opens the list, with where its name is on screen right now.
  final ValueChanged<Rect?> onTap;
  final Translations t;

  @override
  ConsumerState<ListsDrawerTile> createState() => _ListsDrawerTileState();
}

class _ListsDrawerTileState extends ConsumerState<ListsDrawerTile> {
  /// Lets a long-press start renaming. (A tap opens the list, so
  /// `tapToEdit` is false.)
  final _titleKey = GlobalKey<EditableListTitleState>();

  /// The name's box in global coordinates, for the title flight.
  Rect? _titleRect() {
    final box = _titleKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = widget.row;
    final list = row.list;
    final summary = row.summary;
    // Only the owner can rename. If not allowed, `startEditing` does
    // nothing.
    final isOwner = ref.watch(isListOwnerProvider(list));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: widget.isCurrent ? scheme.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => widget.onTap(_titleRect()),
          onLongPress: () => _titleKey.currentState?.startEditing(),
          child: Semantics(
            selected: widget.isCurrent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: EditableListTitle(
                          key: _titleKey,
                          name: list.name,
                          enabled: isOwner,
                          tapToEdit: false,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: scheme.onSurface,
                          ),
                          onRename: (name) async {
                            final result = await ref
                                .read(listsControllerProvider.notifier)
                                .rename(list.id, name);
                            return switch (result) {
                              Ok() => null,
                              Err(:final failure) => failure.toMessage(
                                widget.t,
                              ),
                            };
                          },
                        ),
                      ),
                      for (final color in row.shopColors)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color.toColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Until the counts load, the member count stands in.
                  if (summary == null)
                    Text(
                      widget.t.lists.memberCount(n: list.members.length),
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    _Progress(summary: summary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 3px ink bar and "4/10".
class _Progress extends StatelessWidget {
  const _Progress({required this.summary});

  final ListSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = summary.total == 0
        ? 0.0
        : summary.checkedCount / summary.total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: scheme.fill,
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
                    child: ColoredBox(color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${summary.checkedCount}/${summary.total}',
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
