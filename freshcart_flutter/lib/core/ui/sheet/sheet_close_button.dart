import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';

/// A 30px round × on the fill colour, inside a 44px target. Pops the sheet.
///
/// Public because sheets with their own header (the product sheet) put it
/// in their own row.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox.square(
          dimension: AppSpacing.minTapTarget,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.fill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
