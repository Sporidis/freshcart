/// The only corner radii allowed in the app. Don't use other values.
class AppRadii {
  AppRadii._();
  static const double sheet = 24; // bottom sheets
  static const double celebration = 20; // the one raised card
  static const double dialog = 16;
  static const double card = 14; // rows, list cards, buttons
  static const double button = 14;
  static const double input = 12;
  static const double snackbar = 14;
  static const double pill = 999; // tabs, chips, avatars

  /// For the app icon on the splash screen. Matches the rounding of iOS app
  /// icons (about 24% of its 86px size).
  static const double appIcon = 21;
}
