import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a [ShoppingList] to JSON for [CachedListsStore], including its
/// members.
extension ShoppingListCachePayload on ShoppingList {
  /// Turns this list into JSON.
  Map<String, dynamic> toCachePayload() => {
    'id': id.value,
    'name': name,
    // New keys, not 'joinCode': payloads cached before invites expired
    // still have that key, and must not read as an open invite.
    'inviteCode': invite?.code.value,
    'inviteExpiresAt': invite?.expiresAt.toIso8601String(),
    'ownerId': ownerId.value,
    'createdAt': createdAt.toIso8601String(),
    'clearCheckedAfterShopping': clearCheckedAfterShopping,
    'members': [
      for (final member in members)
        {
          'userId': member.userId.value,
          'displayName': member.displayName,
          'role': member.role.name,
          'joinedAt': member.joinedAt.toIso8601String(),
          'avatarColor': member.avatarColor?.argb,
          'avatarPhotoUrl': member.avatarPhotoUrl,
        },
    ],
  };
}

/// Turns JSON from [ShoppingListCachePayload.toCachePayload] back into a
/// [ShoppingList].
ShoppingList shoppingListFromCachePayload(Map<String, dynamic> payload) {
  return ShoppingList(
    id: ListId(payload['id'] as String),
    name: payload['name'] as String,
    invite: _inviteFromJson(payload),
    ownerId: UserId(payload['ownerId'] as String),
    createdAt: DateTime.parse(payload['createdAt'] as String),
    clearCheckedAfterShopping: payload['clearCheckedAfterShopping'] as bool,
    members: [
      for (final raw in payload['members'] as List<dynamic>)
        _memberFromJson(raw as Map<String, dynamic>),
    ],
  );
}

/// The cached invite, or null if the list had none when it was cached.
ListInvite? _inviteFromJson(Map<String, dynamic> payload) {
  final code = payload['inviteCode'] as String?;
  final expiresAtStr = payload['inviteExpiresAt'] as String?;
  if (code != null && expiresAtStr != null) {
    final expiresAt = DateTime.parse(expiresAtStr);
    return switch (JoinCode.parse(code)) {
      Ok<JoinCode>(:final value) => ListInvite(
        code: value,
        expiresAt: expiresAt,
      ),
      Err<JoinCode>() => throw StateError(
        'Cached an invalid join code: $code',
      ),
    };
  }
  return null;
}

ListMember _memberFromJson(Map<String, dynamic> json) => ListMember(
  userId: UserId(json['userId'] as String),
  displayName: json['displayName'] as String,
  role: MemberRole.values.byName(json['role'] as String),
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  avatarColor: json['avatarColor'] == null
      ? null
      : HexColor.fromArgb(json['avatarColor'] as int),
  avatarPhotoUrl: json['avatarPhotoUrl'] as String?,
);
