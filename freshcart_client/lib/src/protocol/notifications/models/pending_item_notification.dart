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

/// One added item, waiting to be summarised into a push. Only additions are
/// queued (decision #108): ticks, edits and deletes are live-only.
///
/// Buffered rather than sent immediately so a burst — "mom added 3 items" —
/// arrives as one notification instead of three. Each add moves the list's
/// scheduled send (NotificationService.enqueueAddition): one minute after the
/// last add, at most three after the first.
abstract class PendingItemNotification implements _i1.SerializableModel {
  PendingItemNotification._({
    this.id,
    required this.listId,
    required this.actorId,
    required this.actorName,
    required this.itemName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PendingItemNotification({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue actorId,
    required String actorName,
    required String itemName,
    DateTime? createdAt,
  }) = _PendingItemNotificationImpl;

  factory PendingItemNotification.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PendingItemNotification(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      actorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
      actorName: jsonSerialization['actorName'] as String,
      itemName: jsonSerialization['itemName'] as String,
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

  /// Who caused the change. Never notified about their own edit.
  _i1.UuidValue actorId;

  /// The actor's display name at the time, so the summary reads naturally even
  /// if they later change it.
  String actorName;

  /// The item's name, for the summary ("Sam added Milk, Eggs").
  String itemName;

  DateTime createdAt;

  /// Returns a shallow copy of this [PendingItemNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PendingItemNotification copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? actorId,
    String? actorName,
    String? itemName,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PendingItemNotification',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'actorId': actorId.toJson(),
      'actorName': actorName,
      'itemName': itemName,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PendingItemNotificationImpl extends PendingItemNotification {
  _PendingItemNotificationImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue actorId,
    required String actorName,
    required String itemName,
    DateTime? createdAt,
  }) : super._(
         id: id,
         listId: listId,
         actorId: actorId,
         actorName: actorName,
         itemName: itemName,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PendingItemNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PendingItemNotification copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? actorId,
    String? actorName,
    String? itemName,
    DateTime? createdAt,
  }) {
    return PendingItemNotification(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      itemName: itemName ?? this.itemName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
