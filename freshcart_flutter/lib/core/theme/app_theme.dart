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
    final p = _Palette(brightness);
    final scheme = _colorScheme(p, seed);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
      textTheme: _textTheme(p),
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: p.ink, size: 22),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: _appBar(p),
      bottomSheetTheme: _bottomSheet(p),
      dialogTheme: _dialog(p),
      popupMenuTheme: _popupMenu(p),
      drawerTheme: _drawer(p),
      elevatedButtonTheme: _elevatedButton(p),
      outlinedButtonTheme: _outlinedButton(p),
      textButtonTheme: _textButton(p),
      floatingActionButtonTheme: _floatingActionButton(scheme),
      inputDecorationTheme: _inputDecoration(p, scheme),
      chipTheme: _chip(p, scheme),
      checkboxTheme: _checkbox(p, scheme),
      switchTheme: _switch(p),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 2,
      ),
      listTileTheme: _listTile(p),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      snackBarTheme: _snackBar(p),
    );
  }

  // ── Colours and text ────────────────────────────────────────────────────

  static ColorScheme _colorScheme(_Palette p, Color seed) {
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: p.brightness,
    );
    final isNeutralTheme = seed == brandSeed;
    // Use the exact shop colour. Material's generated `primary` would shift
    // it slightly, so it wouldn't match the colour the user picked.
    final primary = isNeutralTheme ? p.ink : seed;
    return generated.copyWith(
      primary: primary,
      onPrimary: isNeutralTheme ? p.onNeutralPrimary : onColorFor(primary),
      secondary: isNeutralTheme ? p.ink : generated.secondary,
      onSecondary: isNeutralTheme ? p.onNeutralPrimary : null,
      tertiary: isNeutralTheme ? p.ink : generated.tertiary,
      onTertiary: isNeutralTheme ? p.onNeutralPrimary : null,
      surface: p.surface,
      onSurface: p.ink,
      error: AppColors.destructive,
      onError: Colors.white,
      // Set these by hand to our neutral colours. If left to
      // ColorScheme.fromSeed, they come out slightly green.
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.subtleSurface,
      surfaceContainerHigh: p.subtleSurface,
      surfaceContainerHighest: p.subtleSurface,
      surfaceTint: Colors.transparent,
      // Same for lines and secondary text: set by hand so they stay neutral.
      outline: p.border,
      outlineVariant: p.border,
      onSurfaceVariant: p.secondaryText,
    );
  }

  static TextTheme _textTheme(_Palette p) => TextTheme(
    displayLarge: AppTextStyles.largeTitle.copyWith(color: p.ink),
    displaySmall: AppTextStyles.screenTitle.copyWith(color: p.ink),
    headlineLarge: AppTextStyles.screenTitle.copyWith(color: p.ink),
    headlineMedium: AppTextStyles.sheetTitle.copyWith(color: p.ink),
    headlineSmall: AppTextStyles.sheetTitle.copyWith(color: p.ink),
    titleLarge: AppTextStyles.sheetTitle.copyWith(color: p.ink),
    titleMedium: AppTextStyles.bodyStrong.copyWith(color: p.ink),
    titleSmall: AppTextStyles.secondaryStrong.copyWith(color: p.ink),
    bodyLarge: AppTextStyles.body.copyWith(color: p.ink),
    bodyMedium: AppTextStyles.secondary.copyWith(color: p.secondaryText),
    labelLarge: AppTextStyles.labelStrong.copyWith(color: p.ink),
    labelMedium: AppTextStyles.label.copyWith(color: p.secondaryText),
    bodySmall: AppTextStyles.caption.copyWith(color: p.mutedText),
    labelSmall: AppTextStyles.eyebrow.copyWith(color: p.mutedText),
  );

  // ── Surfaces: bars, sheets, dialogs, menus ─────────────────────────────

  static AppBarTheme _appBar(_Palette p) => AppBarTheme(
    backgroundColor: p.bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: p.ink,
    centerTitle: false,
    titleTextStyle: AppTextStyles.screenTitle.copyWith(color: p.ink),
    iconTheme: IconThemeData(color: p.ink, size: 22),
  );

  static BottomSheetThemeData _bottomSheet(_Palette p) => BottomSheetThemeData(
    backgroundColor: p.surface,
    modalBackgroundColor: p.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalBarrierColor: const Color(0x59141412),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    showDragHandle: true,
    dragHandleSize: const Size(36, 5),
    dragHandleColor: p.isDark ? Colors.white24 : Colors.black12,
  );

  static DialogThemeData _dialog(_Palette p) => DialogThemeData(
    backgroundColor: p.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.dialog),
    ),
    titleTextStyle: AppTextStyles.sheetTitle.copyWith(
      color: p.ink,
      fontSize: 18,
    ),
    contentTextStyle: AppTextStyles.label.copyWith(
      color: p.secondaryText,
      height: 1.5,
    ),
  );

  /// The "..." menu on a list. Styled to match our dialogs and sheets
  /// (flat, no shadow) instead of Material's default look.
  static PopupMenuThemeData _popupMenu(_Palette p) => PopupMenuThemeData(
    color: p.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    textStyle: AppTextStyles.body.copyWith(color: p.ink),
  );

  static DrawerThemeData _drawer(_Palette p) => DrawerThemeData(
    backgroundColor: p.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    width: 300,
    shape: const RoundedRectangleBorder(),
  );

  // ── Buttons ─────────────────────────────────────────────────────────────

  /// Primary CTA: Continue, Get started, Create shop tab, Add.
  static ElevatedButtonThemeData _elevatedButton(_Palette p) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.buttonBg,
          foregroundColor: p.buttonFg,
          disabledBackgroundColor: p.buttonBg.withValues(alpha: 0.35),
          disabledForegroundColor: p.buttonFg.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTextStyles.bodyStrong,
          elevation: 0,
        ),
      );

  /// Secondary CTA: Keep list, Copy link, Share, Cancel-in-dialog.
  static OutlinedButtonThemeData _outlinedButton(_Palette p) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.border, width: 1),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      );

  /// Tertiary: Skip for now, I have an invite code, Clear checked.
  static TextButtonThemeData _textButton(_Palette p) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: p.mutedText,
      textStyle: AppTextStyles.labelStrong,
      minimumSize: const Size(0, AppSpacing.minTapTarget),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );

  static FloatingActionButtonThemeData _floatingActionButton(
    ColorScheme scheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    elevation: 0,
    highlightElevation: 0,
  );

  // ── Inputs and controls ─────────────────────────────────────────────────

  /// In this design, labels are a separate Text above the field. Don't use
  /// labelText or floating labels.
  static InputDecorationTheme _inputDecoration(
    _Palette p,
    ColorScheme scheme,
  ) => InputDecorationTheme(
    filled: p.isDark,
    fillColor: p.isDark ? AppColors.subtleDark : Colors.transparent,
    contentPadding: const EdgeInsets.all(14),
    hintStyle: AppTextStyles.body.copyWith(color: p.mutedText),
    border: _inputBorder(p.border),
    enabledBorder: _inputBorder(p.border),
    focusedBorder: _inputBorder(scheme.primary),
    errorBorder: _inputBorder(AppColors.destructive),
    focusedErrorBorder: _inputBorder(AppColors.destructive),
    errorStyle: AppTextStyles.captionStrong.copyWith(
      color: AppColors.destructive,
    ),
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.input),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  /// Shop tab pills. Inside [forShop], the selected one is filled with the
  /// shop's colour.
  static ChipThemeData _chip(_Palette p, ColorScheme scheme) => ChipThemeData(
    backgroundColor: Colors.transparent,
    selectedColor: scheme.primary,
    disabledColor: Colors.transparent,
    // The label colour changes when selected, so it stays readable on the
    // filled background. This must be done here in `labelStyle`: Flutter's
    // Chip ignores `secondaryLabelStyle`, even though the name suggests
    // otherwise.
    labelStyle: AppTextStyles.label.copyWith(
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : p.secondaryText,
      ),
    ),
    side: BorderSide(color: p.border),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    showCheckmark: false,
  );

  /// The round check circle on every product row.
  static CheckboxThemeData _checkbox(_Palette p, ColorScheme scheme) =>
      CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(
          color: p.isDark ? Colors.white30 : Colors.black26,
          width: 1.5,
        ),
        shape: const CircleBorder(),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  static SwitchThemeData _switch(_Palette p) => SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? p.buttonBg
          : (p.isDark ? Colors.white24 : Colors.black12),
    ),
    // When the switch is on, the thumb uses the button text colour, so it's
    // visible on the track in both light and dark mode.
    thumbColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? p.buttonFg : Colors.white,
    ),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  );

  // ── Lists and feedback ──────────────────────────────────────────────────

  static ListTileThemeData _listTile(_Palette p) => ListTileThemeData(
    textColor: p.ink,
    iconColor: p.ink,
    titleTextStyle: AppTextStyles.body.copyWith(color: p.ink),
    subtitleTextStyle: AppTextStyles.caption.copyWith(color: p.mutedText),
    contentPadding: EdgeInsets.zero,
    minLeadingWidth: 0,
    // Background of the selected row, e.g. the open list in the drawer.
    selectedTileColor: p.isDark
        ? AppColors.selectedRowDark
        : AppColors.selectedRowLight,
  );

  /// v3 toast: the ink-on-paper button colours, so it inverts in dark mode
  /// like the primary button. Actions (Retry) use the same text colour; the
  /// old orange accent had poor contrast on a light toast.
  static SnackBarThemeData _snackBar(_Palette p) => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: p.buttonBg,
    contentTextStyle: AppTextStyles.label.copyWith(color: p.buttonFg),
    actionTextColor: p.buttonFg,
    insetPadding: const EdgeInsets.all(16),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.snackbar),
    ),
  );
}

/// The neutral colours for one brightness, shared by every component theme.
class _Palette {
  _Palette(this.brightness);

  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  Color get ink =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get bg => isDark ? AppColors.bgDark : AppColors.bgLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get subtleSurface =>
      isDark ? AppColors.subtleDark : AppColors.subtleLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get divider => isDark ? AppColors.dividerDark : AppColors.dividerLight;
  Color get secondaryText =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get mutedText =>
      isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

  /// Primary buttons are ink-on-paper in both modes, whatever the shop is.
  Color get buttonBg => isDark ? Colors.white : AppColors.ink;
  Color get buttonFg => isDark ? AppColors.ink : Colors.white;

  /// Text on the neutral primary. Light mode: white on black. Dark mode:
  /// black on white. Uses `AppColors.ink`, NOT [ink]: in dark mode that one
  /// is white, which would give white text on white.
  Color get onNeutralPrimary => isDark ? AppColors.ink : Colors.white;
}
