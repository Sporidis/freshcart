import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'haptics_controller.g.dart';

/// Whether the app's own [HapticFeedback](https://api.flutter.dev/flutter/services/HapticFeedback-class.html)
/// calls (swipe-to-delete, checking an item, reordering, the invite-code
/// copy confirmation) should actually fire.
///
/// Defaults to `true` — every call site already fires unconditionally today,
/// so an unset preference has to mean "keep doing what it already does,"
/// not silently go quiet for everyone who has never opened this setting.
/// Persisted the same `shared_preferences` way as [AppearanceController].
@riverpod
class HapticsController extends _$HapticsController {
  static const _prefsKey = 'haptics_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  /// Sets whether haptics are on, and persists it.
  Future<void> select(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (ref.mounted) state = AsyncData(value);
  }
}
