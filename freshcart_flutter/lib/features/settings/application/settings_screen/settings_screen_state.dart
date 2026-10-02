import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `SettingsScreen` shows.
class SettingsScreenState {
  const SettingsScreenState({required this.profile, required this.lists});

  /// The signed-in user, including the loading state, so the header can
  /// show a placeholder while loading.
  final AsyncValue<Result<AuthUser>> profile;

  /// One row per list for "Lists & shops"; empty until the lists load.
  final List<SettingsListRow> lists;
}

/// One list in the Settings screen's "Lists & shops" group.
class SettingsListRow {
  const SettingsListRow({
    required this.list,
    required this.shopCount,
    required this.isOpen,
  });

  final ShoppingList list;

  /// How many shops [list] has; null until they load.
  final int? shopCount;

  /// Whether this is the list the app opens to (shown as "Open now").
  final bool isOpen;
}
