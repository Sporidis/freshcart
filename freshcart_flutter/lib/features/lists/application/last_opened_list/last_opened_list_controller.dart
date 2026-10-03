import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'last_opened_list_controller.g.dart';

/// The list the user opened last. Saved on the phone, so the app can open
/// it again next time (see `listsLandingTarget`).
@riverpod
class LastOpenedListController extends _$LastOpenedListController {
  static const String _prefsKey = 'last_opened_list_id';

  @override
  Future<ListId?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenedListId = prefs.getString(_prefsKey);
    return lastOpenedListId != null ? ListId(lastOpenedListId) : null;
  }

  /// Remembers [id] as the last opened list.
  Future<void> select(ListId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id.value);
    if (ref.mounted) state = AsyncData(id);
  }
}
