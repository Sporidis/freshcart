import 'package:flutter/material.dart';

enum Appearance { system, light, dark }

extension AppearanceThemeMode on Appearance {
  ThemeMode get themeMode => switch (this) {
    Appearance.system => ThemeMode.system,
    Appearance.light => ThemeMode.light,
    Appearance.dark => ThemeMode.dark,
  };
}
