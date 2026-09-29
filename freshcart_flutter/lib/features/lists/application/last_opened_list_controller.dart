import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'last_opened_list_controller.g.dart';

/// Controller for managing the last opened list.
/// It provides functionality to retrieve and store the last opened list id using shared preferences.
/// This allows the app to remember the last list the user interacted with.
/// Usage:
/// ```dart
/// final lastOpenedList = await ref.read(lastOpenedListControllerProvider.future);
/// ```
@riverpod
class LastOpenedListController extends _$LastOpenedListController {
  static const String _prefsKey = 'last_opened_list_id';

  @override
  Future<ListId?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenedListId = prefs.getString(_prefsKey);
    return lastOpenedListId != null ? ListId(lastOpenedListId) : null;
  }

  /// Stores the selected list id in shared preferences.
  ///
  /// [id] is the list id to be stored.
  Future<void> select(ListId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id.value);
  }
}
