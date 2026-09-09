import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_seed_color_provider.g.dart';

/// The colour the whole app is themed from.
///
/// Holds the active shop's [HexColor] converted to a Flutter [Color], or
/// [AppTheme.brandSeed] when no shop is selected. Phase 7 drives this from the
/// list's shop filter; until then it simply reports the brand default.
///
/// Note the direction of the conversion: the domain stores a plain ARGB `int`
/// and knows nothing about `Color`. Turning it into a Flutter type happens
/// here, in the app, which is what keeps the domain free of Flutter.
@riverpod
class ActiveSeedColor extends _$ActiveSeedColor {
  @override
  Color build() => AppTheme.brandSeed;

  /// Themes the app from [color], or back to the brand seed when null.
  void select(HexColor? color) =>
      state = color == null ? AppTheme.brandSeed : Color(color.argb);
}
