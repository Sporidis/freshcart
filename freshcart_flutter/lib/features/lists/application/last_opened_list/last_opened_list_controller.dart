import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preferences/shared_preferences_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_opened_list_controller.g.dart';

/// The list the user opened last. Saved on the phone, so the app can open
/// it again next time (see `listsLandingTarget`).
@riverpod
class LastOpenedListController extends _$LastOpenedListController {
  static const String _prefsKey = 'last_opened_list_id';

  @override
  Future<ListId?> build() async {
    final prefs = ref.watch(preferencesStoreProvider);
    final lastOpenedListId = await prefs.getString(_prefsKey);
    return lastOpenedListId != null ? ListId(lastOpenedListId) : null;
  }

  /// Remembers [id] as the last opened list.
  Future<void> select(ListId id) async {
    final prefs = ref.read(preferencesStoreProvider);
    await prefs.setString(_prefsKey, id.value);
    if (ref.mounted) state = AsyncData(id);
  }
}
