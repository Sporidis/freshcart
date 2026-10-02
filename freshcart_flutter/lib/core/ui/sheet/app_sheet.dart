import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/cascade_in.dart';

/// Opens a v3 bottom sheet: edge-to-edge, radius 24 on top (from the theme),
/// opening in [AppMotion.sheetOpen] on the iOS curve and closing in
/// [AppMotion.sheetClose].
///
/// Every sheet in the app goes through this, so they all move the same.
/// Pair it with [AppSheetScaffold], which draws the handle, title and close
/// button. Material's own drag handle is off for that reason.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final reduced = AppMotion.reduced(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    sheetAnimationStyle: reduced
        ? const AnimationStyle(
            duration: AppMotion.micro,
            reverseDuration: AppMotion.micro,
          )
        : const AnimationStyle(
            curve: AppMotion.ios,
            duration: AppMotion.sheetOpen,
            reverseCurve: AppMotion.exitStd,
            reverseDuration: AppMotion.sheetClose,
          ),
    builder: builder,
  );
}

/// The inside of every sheet: a 36×5 handle, an optional title row with a
/// round close button, an optional [subtitle], then [children] arriving in
/// a cascade (45ms apart, starting at 110ms).
///
/// It handles the insets too: the keyboard when it's open, otherwise the
/// home indicator, plus the standard gap below the last child. The body
/// scrolls, so a tall sheet still fits on a small phone with the keyboard up.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    required this.children,
    this.title,
    this.subtitle,
    this.showClose = true,
    super.key,
  });

  final String? title;
  final String? subtitle;

  /// Hide it when the sheet draws its own header (like the product sheet).
  final bool showClose;
  final List<Widget> children;

  static const Duration _cascadeStart = Duration(milliseconds: 110);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final homeIndicator = MediaQuery.viewPaddingOf(context).bottom;
    final title = this.title;
    final subtitle = this.subtitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        0,
        AppSpacing.sheetH,
        (keyboard > 0 ? keyboard : homeIndicator) + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineSmall),
                  ),
                  if (showClose) const SheetCloseButton(),
                ],
              ),
            ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxl),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed)
                    CascadeIn(index: i, start: _cascadeStart, child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 36×5 grab handle. The whole sheet drags; this only shows that it can.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 22,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .25),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

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
                color: scheme.surfaceContainer,
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

@Preview(group: 'Core', name: 'Sheet scaffold', size: Size(393, 320))
Widget appSheetScaffoldPreview() => previewPiece(
  const AppSheetScaffold(
    title: 'Add shop',
    subtitle: 'Each shop becomes a tab.',
    children: [
      TextField(decoration: InputDecoration(hintText: 'e.g. Lidl')),
      SizedBox(height: AppSpacing.xl),
      ElevatedButton(onPressed: null, child: Text('Add shop')),
    ],
  ),
);
