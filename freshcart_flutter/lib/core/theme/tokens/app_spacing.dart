/// Spacing values, all multiples of 4. See decisions.md #105.
///
/// Use these for layout: screen padding, gaps between sections and rows.
/// Tiny sizes that are part of one widget's own shape (like a pill's
/// padding) can stay as plain numbers inside that widget.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  // Named by what they're for. Prefer these over the raw sizes above.
  static const double screen = xl; // horizontal screen padding
  static const double sheetH = xl;
  static const double gap = md;
  static const double gapSmall = sm;
  static const double rowVertical = 13; // design-exact; keeps rows at 44+
  static const double minTapTarget = 44;
}
