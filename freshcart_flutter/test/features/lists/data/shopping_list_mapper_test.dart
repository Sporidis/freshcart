import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/list_member_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';

import '../../../fakes/dto_builders.dart';

void main() {
  group('ShoppingListDtoX.toDomain', () {
    test('maps every field across the boundary', () {
      final domain = buildListDto(members: [buildMemberDto()]).toDomain();

      expect(domain.id.value, listUuid.uuid);
      expect(domain.name, 'Groceries');
      expect(domain.joinCode.value, 'ABC23');
      expect(domain.ownerId.value, userUuid.uuid);
      expect(domain.createdAt, testNow);
      expect(domain.members, hasLength(1));
    });

    test('turns a null member list into an empty one', () {
      // The wire type allows null; the domain entity guarantees a list. That
      // narrowing is the reason the mapper exists.
      expect(buildListDto().toDomain().members, isEmpty);
    });

    test('re-parses the join code into a validated value object', () {
      expect(
        buildListDto(joinCode: 'ABC23').toDomain().joinCode,
        JoinCode.parse('ABC23').valueOrNull,
      );
    });

    test('rejects a join code the domain would refuse', () {
      // A malformed code means the server contract is broken, so this throws
      // rather than surfacing as an expected Result failure.
      expect(
        () => buildListDto(joinCode: 'bad').toDomain(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a list with no id', () {
      final noId = dto.ShoppingList(
        name: 'Groceries',
        joinCode: 'ABC23',
        ownerId: userUuid,
        createdAt: testNow,
      );
      expect(noId.toDomain, throwsA(isA<StateError>()));
    });
  });

  group('MemberRole mapping', () {
    test('round-trips both roles', () {
      for (final role in MemberRole.values) {
        expect(role.toDto().toDomain(), role);
      }
    });

    test('maps each wire role to its domain counterpart', () {
      expect(dto.MemberRole.owner.toDomain(), MemberRole.owner);
      expect(dto.MemberRole.member.toDomain(), MemberRole.member);
    });
  });

  group('ListMemberDtoX.toDomain', () {
    test('maps the membership record', () {
      final member = buildMemberDto(
        displayName: 'Mom',
        role: dto.MemberRole.member,
      ).toDomain();

      expect(member.userId.value, userUuid.uuid);
      expect(member.displayName, 'Mom');
      expect(member.role, MemberRole.member);
      expect(member.isOwner, isFalse);
    });
  });
}
