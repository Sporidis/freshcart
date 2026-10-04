import 'package:freshcart_flutter/core/preferences/shared_preferences_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_nudge_controller.g.dart';

/// Whether the user closed the "Secure your lists" banner.
///
/// Saved on the phone, so once closed it never comes back, even after
/// restarting the app. The user can still link an email from Settings.
///
/// Uses `shared_preferences` (not secure storage), because this isn't a
/// secret.
@riverpod
class UpgradeNudgeController extends _$UpgradeNudgeController {
  static const _prefsKey = 'upgrade_nudge_dismissed';

  @override
  Future<bool> build() async {
    final prefs = ref.watch(preferencesStoreProvider);
    return await prefs.getBool(_prefsKey) ?? false;
  }

  /// Dismisses the nudge for good.
  Future<void> dismiss() async {
    final prefs = ref.read(preferencesStoreProvider);
    await prefs.setBool(_prefsKey, true);
    if (ref.mounted) state = const AsyncData(true);
  }
}
