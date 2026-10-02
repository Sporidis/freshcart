import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The ink bar that replaces the list header in Select and Rearrange mode.
///
/// Inverting the header is the mode signal: while it's ink, taps on rows
/// mean "select" or "drag", not "check off". It uses the ink-on-paper
/// button colours, so it inverts in dark mode like the primary button.
class ModeBar extends StatelessWidget {
  const ModeBar({
    required this.title,
    this.subtitle,
    this.onClose,
    this.closeLabel,
    this.actions = const [],
    super.key,
  });

  /// "3 selected" or "Drag to reorder".
  final Widget title;

  /// One line under the title, at 65%: the rearrange scope.
  final String? subtitle;

  /// Shows a × on the left when set (Select mode). Rearrange has none; it
  /// ends with its Done pill.
  final VoidCallback? onClose;
  final String? closeLabel;
  final List<ModeBarPill> actions;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final colors = ModeBarColors.of(context);
    final subtitle = this.subtitle;
    final onClose = this.onClose;
    return Material(
      color: colors.background,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.foreground),
            child: Row(
              children: [
                if (onClose != null)
                  Semantics(
                    button: true,
                    label: closeLabel,
                    excludeSemantics: true,
                    child: TapTarget(
                      onTap: onClose,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.foreground,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        child: title,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.foreground.withValues(alpha: .65),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: 6),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 38px pill on the [ModeBar]: Move, Delete, Done.
class ModeBarPill extends StatelessWidget {
  const ModeBarPill({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.emphasized = false,
    super.key,
  });

  final String label;

  /// Null disables it (40% opacity), like Move with nothing selected.
  final VoidCallback? onTap;
  final bool destructive;

  /// Bold, for the pill that ends the mode (Done).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = ModeBarColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: TapTarget(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? .4 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: emphasized ? 18 : 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.pill,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                color: destructive ? colors.danger : colors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mode bar's colours, which invert with the theme.
class ModeBarColors {
  const ModeBarColors._({
    required this.background,
    required this.foreground,
    required this.pill,
    required this.danger,
  });

  factory ModeBarColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const ModeBarColors._(
            background: AppColors.textPrimaryDark,
            foreground: AppColors.ink,
            pill: Color(0x14000000), // black 8%
            danger: Color(0xFFB03A2E),
          )
        : const ModeBarColors._(
            background: AppColors.ink,
            foreground: Colors.white,
            pill: Color(0x24FFFFFF), // white 14%
            danger: Color(0xFFF08A7E),
          );
  }

  final Color background;
  final Color foreground;
  final Color pill;

  /// Delete. A softer red than [AppColors.destructive], because it sits on
  /// ink, where the full red would be too dark to read.
  final Color danger;
}

@Preview(group: 'Core', name: 'Mode bar', size: Size(393, 140))
Widget modeBarPreview() => previewPiece(
  Column(
    children: [
      ModeBar(
        title: const Text('3 selected'),
        onClose: () {},
        actions: [
          ModeBarPill(label: 'Move', onTap: () {}),
          ModeBarPill(label: 'Delete', onTap: () {}, destructive: true),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ModeBar(
        title: const Text('Drag to reorder'),
        subtitle: 'Order for Colruyt',
        actions: [ModeBarPill(label: 'Done', onTap: () {}, emphasized: true)],
      ),
    ],
  ),
);
