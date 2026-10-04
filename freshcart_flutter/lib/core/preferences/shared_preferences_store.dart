import 'package:freshcart_flutter/core/preferences/preferences_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_store.g.dart';

/// The real [PreferencesStore], on `shared_preferences` (localStorage on
/// the web).
class SharedPreferencesStore implements PreferencesStore {
  /// Creates the store.
  const SharedPreferencesStore();

  @override
  Future<bool?> getBool(String key) async =>
      (await SharedPreferences.getInstance()).getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }

  @override
  Future<String?> getString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

/// Supplies the [PreferencesStore]. The web demo overrides it per phone.
@Riverpod(keepAlive: true)
PreferencesStore preferencesStore(Ref ref) => const SharedPreferencesStore();
