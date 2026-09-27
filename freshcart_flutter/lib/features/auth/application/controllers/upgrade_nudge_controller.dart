import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'upgrade_nudge_controller.g.dart';

/// Whether the "Secure your lists" nudge has been dismissed.
///
/// Persisted locally rather than in-memory state: dismissing it is meant to
/// be permanent, since the same action -- linking an email -- stays one tap
/// away from Settings for whenever the user actually wants it (see
/// UpgradeNudge's own doc comment for why the nudge exists at all). An
/// in-memory flag would forget the dismissal on every app restart, which is
/// exactly the "annoying, keeps coming back" behaviour this exists to fix.
///
/// `shared_preferences`, not `flutter_secure_storage`: this is a plain UI
/// preference, not a secret, and the latter is already a dependency only for
/// what the auth packages need internally for session storage.
@riverpod
class UpgradeNudgeController extends _$UpgradeNudgeController {
  static const _prefsKey = 'upgrade_nudge_dismissed';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Dismisses the nudge for good.
  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (ref.mounted) state = const AsyncData(true);
  }
}
