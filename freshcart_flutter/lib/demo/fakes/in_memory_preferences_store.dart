import 'package:freshcart_flutter/core/preferences/preferences_store.dart';

/// [PreferencesStore] for one demo phone: a plain map.
///
/// One per phone, so dark mode on phone A doesn't change phone B, and
/// nothing is written to the host page's localStorage.
class InMemoryPreferencesStore implements PreferencesStore {
  final _values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
}
