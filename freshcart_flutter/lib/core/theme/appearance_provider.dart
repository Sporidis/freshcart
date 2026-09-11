import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_provider.g.dart';

enum Appearance { system, light, dark }

@riverpod
class AppearanceController extends _$AppearanceController {
  @override
  Appearance build() => Appearance.system;

  void select(Appearance appearance) => state = appearance;
}

extension AppearanceThemeMode on Appearance {
  ThemeMode get themeMode => switch (this) {
    Appearance.system => ThemeMode.system,
    Appearance.light => ThemeMode.light,
    Appearance.dark => ThemeMode.dark,
  };
}
