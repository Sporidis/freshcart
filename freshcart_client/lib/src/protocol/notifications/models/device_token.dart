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
import '../../notifications/models/device_platform.dart' as _i2;

/// An FCM registration token for one device belonging to one user.
abstract class DeviceToken implements _i1.SerializableModel {
  DeviceToken._({
    this.id,
    required this.ownerId,
    required this.token,
    required this.platform,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DeviceToken({
    _i1.UuidValue? id,
    required _i1.UuidValue ownerId,
    required String token,
    required _i2.DevicePlatform platform,
    DateTime? createdAt,
  }) = _DeviceTokenImpl;

  factory DeviceToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceToken(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      ownerId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      token: jsonSerialization['token'] as String,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// The owning user's `authUserId`.
  _i1.UuidValue ownerId;

  /// The FCM registration token.
  String token;

  _i2.DevicePlatform platform;

  DateTime createdAt;

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceToken copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? ownerId,
    String? token,
    _i2.DevicePlatform? platform,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'ownerId': ownerId.toJson(),
      'token': token,
      'platform': platform.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceTokenImpl extends DeviceToken {
  _DeviceTokenImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue ownerId,
    required String token,
    required _i2.DevicePlatform platform,
    DateTime? createdAt,
  }) : super._(
         id: id,
         ownerId: ownerId,
         token: token,
         platform: platform,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceToken copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? ownerId,
    String? token,
    _i2.DevicePlatform? platform,
    DateTime? createdAt,
  }) {
    return DeviceToken(
      id: id is _i1.UuidValue? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
