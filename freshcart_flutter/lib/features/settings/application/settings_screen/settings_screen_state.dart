import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_list_row.dart';

/// The data `SettingsScreen` shows.
class SettingsScreenState {
  const SettingsScreenState({required this.profile, required this.lists});

  /// The signed-in user, including the loading state, so the header can
  /// show a placeholder while loading.
  final AsyncValue<Result<AuthUser>> profile;

  /// One row per list for "Lists & shops"; empty until the lists load.
  final List<SettingsListRow> lists;
}
