import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'large_text_controller.g.dart';

/// Whether the "Larger list text" setting is on.
///
/// Off by default. Saved on the device with `shared_preferences`.
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
