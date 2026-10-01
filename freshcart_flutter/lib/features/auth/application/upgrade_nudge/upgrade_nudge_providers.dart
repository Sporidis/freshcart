import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upgrade_nudge_providers.g.dart';

/// Whether `UpgradeNudge` should show: the user is anonymous *and* has not
/// dismissed it.
///
/// Both halves stay quiet while they load. An unknown identity counts as not
/// anonymous, and an unread dismissal counts as dismissed, so a cold start
/// never flashes the banner for one frame and then takes it away again.
@riverpod
bool showUpgradeNudge(Ref ref) {
  final isAnonymous =
      ref.watch(profileControllerProvider).dataOrNull?.isAnonymous ?? false;
  final dismissed = ref.watch(upgradeNudgeControllerProvider).value ?? true;
  return isAnonymous && !dismissed;
}
