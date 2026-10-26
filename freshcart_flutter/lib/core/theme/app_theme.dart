import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_sizes.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';

/// Builds the app's [ThemeData].
///
/// [light] and [dark] are the normal neutral theme, used everywhere that
/// isn't about one specific shop.
///
/// [forShop] is the same theme, but the accent colour (selected tab, check
/// circles, FAB, focused input) is the shop's colour. Backgrounds, text and
/// main buttons don't change. Use it only around the part of the screen
/// that belongs to that shop:
///
///   Theme(
///     data: AppTheme.forShop(shop.color, Theme.of(context).brightness),
///     child: ProductListView(shop: shop),
///   )
///
/// Never change the whole app's theme to a shop colour.
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

  /// White or ink (near-black), whichever is readable on [background].
  ///
  /// Checks how light the colour is. Public because shop pills also need it.
  static Color onColorFor(Color background) =>
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
    // Use the exact shop colour. Material's generated `primary` would shift
    // it slightly, so it wouldn't match the colour the user picked.
    final primary = isNeutralTheme ? ink : seed;
    final subtleSurface = isDark ? AppColors.subtleDark : AppColors.subtleLight;
    // Text on top of the primary colour. Light mode: white on black.
    // Dark mode: black on white.
    // Careful: use `AppColors.ink` here, NOT the local `ink` variable. In
    // dark mode that one is white, which would give white text on white.
    final onNeutralPrimary = isDark ? AppColors.ink : Colors.white;
    final scheme = generatedScheme.copyWith(
      primary: primary,
      onPrimary: isNeutralTheme ? onNeutralPrimary : onColorFor(primary),
      secondary: isNeutralTheme ? ink : generatedScheme.secondary,
      onSecondary: isNeutralTheme ? onNeutralPrimary : null,
      tertiary: isNeutralTheme ? ink : generatedScheme.tertiary,
      onTertiary: isNeutralTheme ? onNeutralPrimary : null,
      surface: surface,
      onSurface: ink,
      error: AppColors.destructive,
      onError: Colors.white,
      // Set these by hand to our neutral colours. If left to
      // ColorScheme.fromSeed, they come out slightly green.
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: subtleSurface,
      surfaceContainerHigh: subtleSurface,
      surfaceContainerHighest: subtleSurface,
      surfaceTint: Colors.transparent,
      // Same for lines and secondary text: set by hand so they stay neutral.
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
        dragHandleSize: const Size(36, 5),
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
        // In this design, labels are a separate Text above the field.
        // Don't use labelText or floating labels.
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(scheme.primary),
        errorBorder: _inputBorder(AppColors.destructive),
        focusedErrorBorder: _inputBorder(AppColors.destructive),
        errorStyle: AppTextStyles.captionStrong.copyWith(
          color: AppColors.destructive,
        ),
      ),

      // Shop tab pills. Inside AppTheme.forShop(), the selected one is filled
      // with the shop's colour.
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary,
        disabledColor: Colors.transparent,
        // The label colour changes when selected, so it stays readable on
        // the filled background. This must be done here in `labelStyle`:
        // Flutter's Chip ignores `secondaryLabelStyle`, even though the name
        // suggests otherwise.
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
        // Background of the selected row, e.g. the open list in the drawer.
        selectedTileColor: isDark
            ? AppColors.selectedRowDark
            : AppColors.selectedRowLight,
      ),

      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),

      // v3 toast: the ink-on-paper button colours, so it inverts in dark
      // mode like the primary button. Actions (Retry) use the same text
      // colour; the old orange accent had poor contrast on a light toast.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: buttonBg,
        contentTextStyle: AppTextStyles.label.copyWith(color: buttonFg),
        actionTextColor: buttonFg,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
        titleTextStyle: AppTextStyles.sheetTitle.copyWith(
          color: ink,
          fontSize: 18,
        ),
        contentTextStyle: AppTextStyles.label.copyWith(
          color: secondaryText,
          height: 1.5,
        ),
      ),

      // The "..." menu on a list. Styled to match our dialogs and sheets
      // (flat, no shadow) instead of Material's default look.
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
        width: 300,
        shape: const RoundedRectangleBorder(),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? buttonBg
              : (isDark ? Colors.white24 : Colors.black12),
        ),
        // When the switch is on, the thumb uses the button text colour, so
        // it's visible on the track in both light and dark mode.
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
