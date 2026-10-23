import 'package:freshcart_domain/freshcart_domain.dart';

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
