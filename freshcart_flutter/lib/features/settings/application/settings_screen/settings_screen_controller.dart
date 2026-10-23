import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_list_row.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_screen_controller.g.dart';

/// The controller for `SettingsScreen`: the profile, and one row per list.
///
/// It combines several providers: profile, lists, each list's shops, and
/// which list the app opens to ("Open now"). That last one uses
/// [listsLandingTargetProvider], the same one that decides where `/lists`
/// goes, so they always agree.
@riverpod
class SettingsScreenController extends _$SettingsScreenController {
  @override
  SettingsScreenState build() {
    final lists = ref.watch(listsControllerProvider).dataOrNull ?? const [];
    final openId = ref.watch(listsLandingTargetProvider);

    return SettingsScreenState(
      profile: ref.watch(profileControllerProvider),
      lists: [
        for (final list in lists)
          SettingsListRow(
            list: list,
            shopCount: ref
                .watch(shopsControllerProvider(list.id))
                .dataOrNull
                ?.length,
            isOpen: list.id == openId,
          ),
      ],
    );
  }
}
