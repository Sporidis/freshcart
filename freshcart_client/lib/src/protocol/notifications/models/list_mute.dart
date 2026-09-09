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

/// A user's choice to silence one list.
///
/// Presence of a row means muted; there is no boolean. Absence is the default
/// and costs no storage for the overwhelmingly common case.
abstract class ListMute implements _i1.SerializableModel {
  ListMute._({
    this.id,
    required this.listId,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ListMute({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    DateTime? createdAt,
  }) = _ListMuteImpl;

  factory ListMute.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListMute(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue listId;

  _i1.UuidValue userId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ListMute]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListMute copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListMute',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListMuteImpl extends ListMute {
  _ListMuteImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         listId: listId,
         userId: userId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ListMute]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListMute copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
  }) {
    return ListMute(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
