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
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i2;
import 'package:freshcart_client/src/protocol/protocol.dart' as _i3;

/// A FreshCart user's public profile, hanging off a Serverpod auth identity.
///
/// Named `MemberProfile`, not `UserProfile`, because serverpod_auth_core ships
/// a `UserProfile` of its own and both would land in the generated client.
/// Ours stays deliberately tiny — one display name — because the auth module's
/// profile feature carries images and email we do not need.
///
/// Kept separate from the auth module's `AuthUser` so that display name and any
/// future profile data are ours to evolve, while identity stays the auth
/// module's concern. The relation is what makes the anonymous-to-linked upgrade
/// free: the `authUserId` never changes, so this row follows the account.
abstract class MemberProfile implements _i1.SerializableModel {
  MemberProfile._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.displayName,
    this.avatarColorArgb,
    this.avatarPhotoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MemberProfile({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String displayName,
    int? avatarColorArgb,
    String? avatarPhotoPath,
    DateTime? createdAt,
  }) = _MemberProfileImpl;

  factory MemberProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return MemberProfile(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      displayName: jsonSerialization['displayName'] as String,
      avatarColorArgb: jsonSerialization['avatarColorArgb'] as int?,
      avatarPhotoPath: jsonSerialization['avatarPhotoPath'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue authUserId;

  /// The auth identity this profile belongs to.
  _i2.AuthUser? authUser;

  /// The name collaborators see next to this user's changes.
  String displayName;

  /// A colour the user picked for their own avatar, from the same swatch
  /// presets a shop's own colour uses. `null` until they choose one.
  int? avatarColorArgb;

  /// Storage path of an uploaded avatar photo (in the `public` cloud
  /// storage bucket), or `null` if none is set. The path, not the public
  /// URL: `ProfileService` recomputes the URL on read, so moving buckets
  /// later would not mean back-filling every row.
  String? avatarPhotoPath;

  DateTime createdAt;

  /// Returns a shallow copy of this [MemberProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MemberProfile copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoPath,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MemberProfile',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'displayName': displayName,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoPath != null) 'avatarPhotoPath': avatarPhotoPath,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MemberProfileImpl extends MemberProfile {
  _MemberProfileImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String displayName,
    int? avatarColorArgb,
    String? avatarPhotoPath,
    DateTime? createdAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         displayName: displayName,
         avatarColorArgb: avatarColorArgb,
         avatarPhotoPath: avatarPhotoPath,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MemberProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MemberProfile copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? displayName,
    Object? avatarColorArgb = _Undefined,
    Object? avatarPhotoPath = _Undefined,
    DateTime? createdAt,
  }) {
    return MemberProfile(
      id: id is _i1.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      displayName: displayName ?? this.displayName,
      avatarColorArgb: avatarColorArgb is int?
          ? avatarColorArgb
          : this.avatarColorArgb,
      avatarPhotoPath: avatarPhotoPath is String?
          ? avatarPhotoPath
          : this.avatarPhotoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
