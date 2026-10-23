import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/preferences/shared_preferences_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_controller.g.dart';

enum Appearance { system, light, dark }

/// Whether the user wants light mode, dark mode, or to follow the phone.
///
/// Saved on the device with `shared_preferences`. We save the name
/// (`'dark'`), not the index (`2`). If we add a new option later, the
/// indexes could shift, but the names won't.
@riverpod
class AppearanceController extends _$AppearanceController {
  static const _prefsKey = 'appearance_mode';

  @override
  Future<Appearance> build() async {
    final prefs = ref.watch(preferencesStoreProvider);
    final stored = await prefs.getString(_prefsKey);
    return Appearance.values.firstWhere(
      (appearance) => appearance.name == stored,
      orElse: () => Appearance.system,
    );
  }

  /// Chooses [appearance] and persists it.
  Future<void> select(Appearance appearance) async {
    final prefs = ref.read(preferencesStoreProvider);
    await prefs.setString(_prefsKey, appearance.name);
    if (ref.mounted) state = AsyncData(appearance);
  }
}

extension AppearanceThemeMode on Appearance {
  ThemeMode get themeMode => switch (this) {
    Appearance.system => ThemeMode.system,
    Appearance.light => ThemeMode.light,
    Appearance.dark => ThemeMode.dark,
  };
}
