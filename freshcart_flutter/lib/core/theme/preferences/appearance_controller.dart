import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'appearance_controller.g.dart';

enum Appearance { system, light, dark }

/// The user's chosen theme mode.
///
/// Persisted with `shared_preferences`, the same pattern
/// [UpgradeNudgeController] uses — this is a plain UI preference, not
/// anything secret. Stored by [Appearance.name] rather than an index, so
/// adding a value later can't silently shift what an already-stored index
/// means.
@riverpod
class AppearanceController extends _$AppearanceController {
  static const _prefsKey = 'appearance_mode';

  @override
  Future<Appearance> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    return Appearance.values.firstWhere(
      (appearance) => appearance.name == stored,
      orElse: () => Appearance.system,
    );
  }

  /// Chooses [appearance] and persists it.
  Future<void> select(Appearance appearance) async {
    final prefs = await SharedPreferences.getInstance();
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
