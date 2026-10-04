/// Small settings saved on the device (theme, haptics, last opened list).
///
/// Controllers use this instead of calling `SharedPreferences` directly, so
/// the storage can be swapped through `preferencesStoreProvider`. The web
/// demo gives each of its two phones its own in-memory store, which a
/// global `SharedPreferences.getInstance()` can't do (decisions.md #110).
abstract interface class PreferencesStore {
  /// The bool saved under [key], or `null` if nothing is saved.
  Future<bool?> getBool(String key);

  /// Saves [value] under [key].
  Future<void> setBool(String key, bool value);

  /// The string saved under [key], or `null` if nothing is saved.
  Future<String?> getString(String key);

  /// Saves [value] under [key].
  Future<void> setString(String key, String value);
}
