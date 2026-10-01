import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `SettingsScreen` renders, already derived.
class SettingsScreenState {
  const SettingsScreenState({required this.profile, required this.lists});

  /// The signed-in user, as loaded -- the header shows a placeholder while
  /// this is still loading, so it gets the outcome rather than just a value.
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

  /// Whether this is the list the app opens to -- "Open now".
  final bool isOpen;
}
