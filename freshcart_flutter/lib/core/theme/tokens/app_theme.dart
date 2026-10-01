import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';

/// Basket type scale. Sizes and weights match the design one-for-one:
/// 28/26 titles · 22 sheet titles · 16-17 body · 14-15 secondary · 12-13 caption.
class AppTextStyles {
  AppTextStyles._();

  /// Swap for a bundled family when you ship; the system face is the design's
  /// reference rendering on iOS.
  static const String fontFamily = '.SF Pro Text';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.12,
  );
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.15,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle secondaryStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle captionStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Section eyebrows: LISTS, DONE · 3, THIS WEEK.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  /// Invite links and codes.
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle codeLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );
}

/// Corner radii used across the app. Nothing else is legal.
class AppRadii {
  AppRadii._();
  static const double sheet = 24; // bottom sheets
  static const double celebration = 20; // the one raised card
  static const double card = 14; // rows, list cards, buttons
  static const double button = 14;
  static const double input = 12;
  static const double snackbar = 12;
  static const double pill = 999; // tabs, chips, avatars
}

class AppSpacing {
  AppSpacing._();
  static const double screen = 20; // horizontal screen padding
  static const double sheetH = 20;
  static const double gap = 12;
  static const double gapSmall = 8;
  static const double rowVertical = 13;
  static const double minTapTarget = 44;
}

class AppSizes {
  AppSizes._();
  static const double checkCircle = 22;
  static const double shopDot = 7; // in list rows
  static const double shopDotLarge = 14; // in shop rows / pickers
  static const double tabDot = 8;
  static const double avatarSmall = 30;
  static const double avatar = 32;
  static const double avatarLarge = 52;
  static const double buttonHeight = 52;
  static const double quantityIcon = 18;
}

/// Basket theming.
///
/// [light] / [dark] are the neutral, shop-agnostic default — onboarding,
/// settings, the "All" tab, anything not scoped to one shop.
///
/// [forShop] re-seeds the scheme from the colour the USER picked when they
/// created that shop, so accents (selected tab pill, check fill, FAB,
/// focused input, refresh indicator) tint to it while surfaces, text and
/// primary buttons stay identical. Scope it per subtree:
///
///   Theme(
///     data: AppTheme.forShop(shop.color, Theme.of(context).brightness),
///     child: ProductListView(shop: shop),
///   )
///
/// Never swap the whole MaterialApp theme per shop — the chrome must not move.
class AppTheme {
  AppTheme._();

  static const Color brandSeed = AppColors.ink;

  static ThemeData light(Color seed) => _build(
    brightness: Brightness.light,
    seed: seed,
  );
  static ThemeData dark(Color seed) => _build(
    brightness: Brightness.dark,
    seed: seed,
  );

  static ThemeData forShop(Color? shopColor, Brightness brightness) => _build(
    brightness: brightness,
    seed: shopColor ?? AppColors.shopColorFallback,
  );

  /// A readable colour to draw text/icons in on top of [background].
  ///
  /// A plain luminance check rather than `generatedScheme.onPrimary`: once
  /// [background] is the shop's literal colour rather than an M3-generated
  /// tone, the two are no longer a matched pair, and pairing arbitrary text
  /// with the wrong one of them risks real contrast failures, not just a
  /// slightly-off hue.
  static Color _onColorFor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : AppColors.ink;

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
  }) {
    final isDark = brightness == Brightness.dark;

    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final mutedText = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    // Primary buttons are ink-on-paper in both modes, whatever the shop is.
    final buttonBg = isDark ? Colors.white : AppColors.ink;
    final buttonFg = isDark ? AppColors.ink : Colors.white;

    final generatedScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isNeutralTheme = seed == brandSeed;
    // The literal shop colour, not `generatedScheme.primary`: M3's seeding
    // snaps any input to the nearest tone on its own generated ramp, which
    // measurably shifts hue and saturation away from the swatch someone
    // actually picked. `presetShopColors` are curated, already-good colours
    // (AppColors' own doc comment), not raw user input that needs that
    // correction -- so the accent everywhere (FAB, checkboxes, the selected
    // chip) is the colour itself, matching the dot and chip that show it.
    final primary = isNeutralTheme ? ink : seed;
    final subtleSurface = isDark ? AppColors.subtleDark : AppColors.subtleLight;
    // Ink-on-paper both modes, matching buttonBg/buttonFg above: light mode
    // is a near-black primary with white "on" content; dark mode inverts to
    // a white primary with near-black "on" content. Deliberately
    // `AppColors.ink` here, not the local `ink` variable a few lines up --
    // that local is "whichever text colour suits this brightness" (white in
    // dark mode), so using it for onPrimary/onSecondary/onTertiary made
    // `primary == onPrimary` (both white) in dark mode with no shop active,
    // which is the app's default state on most screens. Background and
    // foreground being the same colour is why a FilledButton/FAB/checkbox
    // in dark mode read as "unreadable" rather than merely off-brand.
    final onNeutralPrimary = isDark ? AppColors.ink : Colors.white;
    final scheme = generatedScheme.copyWith(
      primary: primary,
      onPrimary: isNeutralTheme ? onNeutralPrimary : _onColorFor(primary),
      secondary: isNeutralTheme ? ink : generatedScheme.secondary,
      onSecondary: isNeutralTheme ? onNeutralPrimary : null,
      tertiary: isNeutralTheme ? ink : generatedScheme.tertiary,
      onTertiary: isNeutralTheme ? onNeutralPrimary : null,
      surface: surface,
      onSurface: ink,
      error: AppColors.destructive,
      onError: Colors.white,
      // The chrome is neutral ink-on-paper regardless of the active shop
      // (this file's own governing rule, stated at the top) -- these tonal
      // surfaces were left to whatever ColorScheme.fromSeed derived from the
      // seed, which is how a bar as plain as the add-item field ended up
      // tinted a stray olive-green. Pinned to the app's own neutral tokens
      // instead of the generated ramp, same as `surface` just above.
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: subtleSurface,
      surfaceContainerHigh: subtleSurface,
      surfaceContainerHighest: subtleSurface,
      surfaceTint: Colors.transparent,
      // Same reasoning for the lines and secondary ink: generated from the
      // seed, they came out olive in light mode (the warm ink seed tints the
      // whole ramp), on every divider and settings row border. Pinned to
      // the app's own neutral tokens like the surfaces above.
      outline: border,
      outlineVariant: border,
      onSurfaceVariant: secondaryText,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.largeTitle.copyWith(color: ink),
      displaySmall: AppTextStyles.screenTitle.copyWith(color: ink),
      headlineLarge: AppTextStyles.screenTitle.copyWith(color: ink),
      headlineMedium: AppTextStyles.sheetTitle.copyWith(color: ink),
      headlineSmall: AppTextStyles.sheetTitle.copyWith(color: ink),
      titleLarge: AppTextStyles.sheetTitle.copyWith(color: ink),
      titleMedium: AppTextStyles.bodyStrong.copyWith(color: ink),
      titleSmall: AppTextStyles.secondaryStrong.copyWith(color: ink),
      bodyLarge: AppTextStyles.body.copyWith(color: ink),
      bodyMedium: AppTextStyles.secondary.copyWith(color: secondaryText),
      labelLarge: AppTextStyles.labelStrong.copyWith(color: ink),
      labelMedium: AppTextStyles.label.copyWith(color: secondaryText),
      bodySmall: AppTextStyles.caption.copyWith(color: mutedText),
      labelSmall: AppTextStyles.eyebrow.copyWith(color: mutedText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        centerTitle: false,
        titleTextStyle: AppTextStyles.screenTitle.copyWith(color: ink),
        iconTheme: IconThemeData(color: ink, size: 22),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: const Color(0x59141412),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        showDragHandle: true,
        dragHandleSize: const Size(36, 4),
        dragHandleColor: isDark ? Colors.white24 : Colors.black12,
      ),

      // Primary CTA: Continue, Get started, Create shop tab, Add.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonFg,
          disabledBackgroundColor: buttonBg.withValues(alpha: 0.35),
          disabledForegroundColor: buttonFg.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTextStyles.bodyStrong,
          elevation: 0,
        ),
      ),

      // Secondary CTA: Keep list, Copy link, Share, Cancel-in-dialog.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border, width: 1),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      ),

      // Tertiary: Skip for now, I have an invite code, Clear checked.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mutedText,
          textStyle: AppTextStyles.labelStrong,
          minimumSize: const Size(0, AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: isDark,
        fillColor: isDark ? AppColors.subtleDark : Colors.transparent,
        contentPadding: const EdgeInsets.all(14),
        hintStyle: AppTextStyles.body.copyWith(color: mutedText),
        // Labels sit ABOVE the field as plain Text in this design —
        // do not use labelText / floating labels.
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(scheme.primary),
        errorBorder: _inputBorder(AppColors.destructive),
        focusedErrorBorder: _inputBorder(AppColors.destructive),
        errorStyle: AppTextStyles.captionStrong.copyWith(
          color: AppColors.destructive,
        ),
      ),

      // Shop tab pills. Selected background is the shop's own colour when the
      // subtree is wrapped in AppTheme.forShop().
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary,
        disabledColor: Colors.transparent,
        // A WidgetStateColor, not `secondaryLabelStyle`: that property looks
        // like the selected-state label style but Chip's own build method
        // never actually reads it (confirmed against the installed Flutter
        // SDK source) -- only `labelStyle` is consumed, resolved per-state.
        // Without this, a selected chip's translucent unselected-style ink
        // renders on top of `selectedColor` (near-black for the neutral
        // theme), which is what made a selected tab's own label invisible.
        labelStyle: AppTextStyles.label.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : secondaryText,
          ),
        ),
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
      ),

      // The round check circle on every product row.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(
          color: isDark ? Colors.white30 : Colors.black26,
          width: 1.5,
        ),
        shape: const CircleBorder(),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      listTileTheme: ListTileThemeData(
        textColor: ink,
        iconColor: ink,
        titleTextStyle: AppTextStyles.body.copyWith(color: ink),
        subtitleTextStyle: AppTextStyles.caption.copyWith(color: mutedText),
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        // AppColors.selectedRow{Light,Dark} were defined but never wired to
        // anything -- the drawer's "currently open" list row is the first
        // place that actually needs a selected-row treatment.
        selectedTileColor: isDark
            ? AppColors.selectedRowDark
            : AppColors.selectedRowLight,
      ),

      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.ink,
        contentTextStyle: AppTextStyles.label.copyWith(color: Colors.white),
        actionTextColor: AppColors.undoAccent,
        insetPadding: const EdgeInsets.all(16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.snackbar),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.sheetTitle.copyWith(
          color: ink,
          fontSize: 18,
        ),
        contentTextStyle: AppTextStyles.label.copyWith(
          color: secondaryText,
          height: 1.5,
        ),
      ),

      // The list's overflow menu (ListMenu). Left unthemed, PopupMenuButton
      // falls back to Material 3 defaults -- a tinted surface, its own
      // elevation shadow, 4px corners -- the one overlay in the app that
      // wouldn't match the zero-elevation, ink-on-paper language every other
      // surface (dialog, sheet, snackbar) is pinned to above.
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        textStyle: AppTextStyles.body.copyWith(color: ink),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 272,
        shape: const RoundedRectangleBorder(),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? buttonBg
              : (isDark ? Colors.white24 : Colors.black12),
        ),
        // On, the track is the ink-on-paper button colour -- white in dark
        // mode -- so a fixed white thumb vanished into it. The thumb takes
        // the button's own foreground instead, the same pair a primary
        // button uses, so it reads in both modes.
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? buttonFg : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 2,
      ),

      iconTheme: IconThemeData(color: ink, size: 22),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.input),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
