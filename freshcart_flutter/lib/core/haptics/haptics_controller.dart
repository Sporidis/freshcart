import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'haptics_controller.g.dart';

/// Whether the phone should vibrate on actions like swipe-to-delete,
/// checking an item, reordering, or copying an invite code.
///
/// On by default. Saved on the device with `shared_preferences`.
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
