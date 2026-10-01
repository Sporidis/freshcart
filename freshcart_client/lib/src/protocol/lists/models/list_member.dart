/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../../lists/models/member_role.dart' as _i2;

/// One person's membership of a shopping list.
abstract class ListMember implements _i1.SerializableModel {
  ListMember._({
    this.id,
    required this.listId,
    required this.userId,
    this.displayName,
    this.avatarColorArgb,
    this.avatarPhotoUrl,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory ListMember({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required _i2.MemberRole role,
    DateTime? joinedAt,
  }) = _ListMemberImpl;

  factory ListMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListMember(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      displayName: jsonSerialization['displayName'] as String?,
      avatarColorArgb: jsonSerialization['avatarColorArgb'] as int?,
      avatarPhotoUrl: jsonSerialization['avatarPhotoUrl'] as String?,
      role: _i2.MemberRole.fromJson((jsonSerialization['role'] as String)),
      joinedAt: jsonSerialization['joinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['joinedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// The list this membership belongs to.
  _i1.UuidValue listId;

  /// The member's `authUserId`.
  _i1.UuidValue userId;

  /// Filled in live from the member's `MemberProfile` every time a list is
  /// read (`ListService._withMembers`), never stored on this row: a copy
  /// taken at join time went stale the moment someone renamed themselves or
  /// changed their photo (docs/decisions.md #98). Always set by the server
  /// on the way out; nullable only because a row read straight from the
  /// table does not have it yet.
  String? displayName;

  /// The member's chosen avatar colour, live -- see [displayName].
  int? avatarColorArgb;

  /// The member's avatar photo as a public URL, live -- see [displayName].
  String? avatarPhotoUrl;

  _i2.MemberRole role;

  DateTime joinedAt;

  /// Returns a shallow copy of this [ListMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListMember copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    _i2.MemberRole? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListMember',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      if (displayName != null) 'displayName': displayName,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoUrl != null) 'avatarPhotoUrl': avatarPhotoUrl,
      'role': role.toJson(),
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListMemberImpl extends ListMember {
  _ListMemberImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required _i2.MemberRole role,
    DateTime? joinedAt,
  }) : super._(
         id: id,
         listId: listId,
         userId: userId,
         displayName: displayName,
         avatarColorArgb: avatarColorArgb,
         avatarPhotoUrl: avatarPhotoUrl,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [ListMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListMember copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    Object? displayName = _Undefined,
    Object? avatarColorArgb = _Undefined,
    Object? avatarPhotoUrl = _Undefined,
    _i2.MemberRole? role,
    DateTime? joinedAt,
  }) {
    return ListMember(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarColorArgb: avatarColorArgb is int?
          ? avatarColorArgb
          : this.avatarColorArgb,
      avatarPhotoUrl: avatarPhotoUrl is String?
          ? avatarPhotoUrl
          : this.avatarPhotoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
