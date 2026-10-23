import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';

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
