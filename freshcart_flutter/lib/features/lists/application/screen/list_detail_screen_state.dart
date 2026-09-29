import 'package:freshcart_domain/freshcart_domain.dart';

/// The list-level half of `ListDetailScreen`: what the header's overflow
/// menu needs to offer delete versus leave.
///
/// Deliberately separate from `ItemsScreenState`, which is about the rows.
/// Starts small on purpose -- the app bar's rename and the screen's own
/// load/error handling are natural later additions, not part of this step.
class ListDetailScreenState {
  final ShoppingList? list;
  final bool isOwner;

  const ListDetailScreenState({
    required this.list,
    required this.isOwner,
  });
}
