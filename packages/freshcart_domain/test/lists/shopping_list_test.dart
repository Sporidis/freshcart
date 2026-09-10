import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';

void main() {
  final mom = UserId('user-mom');
  final stranger = UserId('user-stranger');

  ShoppingList listWith(List<ListMember> members) => ShoppingList(
    id: testList,
    name: 'Groceries',
    joinCode: JoinCode.parse('ABC23').valueOrNull!,
    ownerId: testUser,
    createdAt: testNow,
    members: members,
  );

  final owner = ListMember(
    userId: testUser,
    displayName: 'Nikolaos',
    role: MemberRole.owner,
    joinedAt: testNow,
  );
  final member = ListMember(
    userId: mom,
    displayName: 'Mom',
    role: MemberRole.member,
    joinedAt: testNow,
  );

  group('ShoppingList membership', () {
    test('hasMember is true only for people on the list', () {
      final list = listWith([owner, member]);
      expect(list.hasMember(testUser), isTrue);
      expect(list.hasMember(mom), isTrue);
      expect(list.hasMember(stranger), isFalse);
    });

    test('memberFor returns the record, or null for a non-member', () {
      final list = listWith([owner, member]);
      expect(list.memberFor(mom)?.displayName, 'Mom');
      expect(list.memberFor(stranger), isNull);
    });

    test('isOwnedBy distinguishes the owner from a plain member', () {
      final list = listWith([owner, member]);
      expect(list.isOwnedBy(testUser), isTrue);
      expect(list.isOwnedBy(mom), isFalse);
    });

    test('a freshly built list has no members by default', () {
      expect(listWith(const []).members, isEmpty);
    });
  });

  group('ListMember.isOwner', () {
    test('reflects the role', () {
      expect(owner.isOwner, isTrue);
      expect(member.isOwner, isFalse);
    });
  });
}
