import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/application/list_use_case_providers.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lists_controller.g.dart';

/// Every list the signed-in user belongs to.
@riverpod
class ListsController extends _$ListsController {
  @override
  Future<Result<List<ShoppingList>>> build() =>
      ref.watch(listRepositoryProvider).myLists();

  /// Creates a list and refreshes the collection on success.
  ///
  /// Returns the [Result] rather than folding it into state so the calling
  /// dialog can show a validation message against its own text field instead of
  /// replacing the whole screen with an error.
  Future<Result<ShoppingList>> create(String name) async {
    final result = await ref.read(createListUseCaseProvider)(name);
    if (result.isOk) ref.invalidateSelf();
    return result;
  }

  /// Joins a list by code and refreshes the collection on success.
  Future<Result<ShoppingList>> join(String rawCode) async {
    final result = await ref.read(joinListUseCaseProvider)(rawCode);
    if (result.isOk) ref.invalidateSelf();
    return result;
  }

  /// Re-reads the lists, for pull-to-refresh and after leaving a list.
  Future<void> refresh() async => ref.invalidateSelf();
}

/// One list by id, for the detail screen and the router's membership guard.
@riverpod
Future<Result<ShoppingList>> listById(Ref ref, ListId listId) =>
    ref.watch(listRepositoryProvider).byId(listId);
