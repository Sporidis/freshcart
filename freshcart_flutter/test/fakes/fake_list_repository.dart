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

  @override
  Stream<Result<ShoppingList>> watch(ListId id) => throw UnimplementedError();
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
