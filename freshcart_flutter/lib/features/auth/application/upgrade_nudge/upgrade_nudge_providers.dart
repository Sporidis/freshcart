import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_nudge_providers.g.dart';

/// Whether to show `UpgradeNudge`: only if the user is anonymous AND
/// hasn't closed it.
///
/// While either is still loading, the answer is "don't show". Otherwise the
/// banner could flash for one frame at startup and then disappear.
@riverpod
bool showUpgradeNudge(Ref ref) {
  final isAnonymous =
      ref.watch(profileControllerProvider).dataOrNull?.isAnonymous ?? false;
  final dismissed = ref.watch(upgradeNudgeControllerProvider).value ?? true;
  return isAnonymous && !dismissed;
}
