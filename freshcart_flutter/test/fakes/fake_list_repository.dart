import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [ListRepository] for presentation tests.
///
/// Overriding the *port* rather than the Serverpod client keeps these tests
/// about the screen: what it renders for each outcome, and what it calls. The
/// mapper and transport paths already have their own tests in
/// `test/features/*/data`.
class FakeListRepository implements ListRepository {
  /// What [myLists] returns.
  Result<List<ShoppingList>> myListsResult = const Ok(<ShoppingList>[]);

  /// What [create] returns.
  Result<ShoppingList>? createResult;

  /// What [joinByCode] returns.
  Result<ShoppingList>? joinResult;

  /// What [byId] returns.
  Result<ShoppingList>? byIdResult;

  /// Names passed to [create], in order.
  final List<String> createCalls = [];

  /// Codes passed to [joinByCode], in order.
  final List<JoinCode> joinCalls = [];

  /// How many times [myLists] was read, to assert on refreshes.
  int myListsCallCount = 0;

  @override
  Future<Result<List<ShoppingList>>> myLists() async {
    myListsCallCount++;
    return myListsResult;
  }

  @override
  Future<Result<ShoppingList>> byId(ListId id) async =>
      byIdResult ?? const Err(Failure.notFound());

  @override
  Future<Result<ShoppingList>> create({required String name}) async {
    createCalls.add(name);
    return createResult ?? const Err(Failure.unexpected('create not set'));
  }

  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) async {
    joinCalls.add(code);
    return joinResult ?? const Err(Failure.notFound());
  }

  @override
  Future<Result<ShoppingList>> rename(ListId id, String name) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> leave(ListId id) => throw UnimplementedError();

  /// Feeds [watch]. Tests push updates through this to simulate another
  /// client renaming the list, or someone joining or leaving.
  final StreamController<Result<ShoppingList>> live =
      StreamController<Result<ShoppingList>>.broadcast();

  @override
  Stream<Result<ShoppingList>> watch(ListId id) {
    // Stream.multi rather than an async* generator so the live listener
    // attaches synchronously on subscribe — otherwise a test that pushes an
    // event right after the seed would race the generator (see
    // FakeItemRepository.watchByList for the same fix).
    return Stream<Result<ShoppingList>>.multi((controller) {
      controller.add(byIdResult ?? const Err(Failure.notFound()));
      final subscription = live.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  /// Closes the live stream. Call from a test teardown.
  Future<void> dispose() => live.close();
}

/// Builds a domain [ShoppingList] for tests.
ShoppingList buildList({
  String id = '00000000-0000-4000-8000-000000000001',
  String name = 'Groceries',
  String joinCode = 'ABC234',
  List<ListMember> members = const [],
}) => ShoppingList(
  id: ListId(id),
  name: name,
  joinCode: JoinCode.parse(joinCode).valueOrNull!,
  ownerId: UserId('user-1'),
  createdAt: DateTime.utc(2026, 9, 9),
  members: members,
);

/// Builds a domain [ListMember] for tests.
ListMember buildMember({
  String userId = 'user-1',
  String displayName = 'Nikolaos',
  MemberRole role = MemberRole.owner,
}) => ListMember(
  userId: UserId(userId),
  displayName: displayName,
  role: role,
  joinedAt: DateTime.utc(2026, 9, 9),
);
