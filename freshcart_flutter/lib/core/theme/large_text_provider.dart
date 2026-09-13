import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'large_text_provider.g.dart';

/// Whether list text renders at the "easier to read at arm's length" size
/// the design calls for (`docs/design-gap-plan.md` §7) — a deliberately
/// conservative, opt-in bump, not a full accessibility text-scale system.
///
/// Persisted the same way [AppearanceController] is: `shared_preferences`,
/// a plain UI preference.
@riverpod
class LargeTextController extends _$LargeTextController {
  static const _prefsKey = 'large_list_text';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Sets whether larger list text is on, and persists it.
  Future<void> select(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (ref.mounted) state = AsyncData(value);
  }
}
