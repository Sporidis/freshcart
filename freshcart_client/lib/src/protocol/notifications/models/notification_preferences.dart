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

/// A user's own choices about which push notifications they receive
/// (decisions #80, phase 2). Global, not per-list -- ListMute is "not from
/// this list, regardless of kind," this is "which kinds of thing do I want
/// to hear about at all, from any list."
///
/// No row exists until a user changes something from its default --
/// NotificationPreferencesService.forUser returns an in-memory default
/// rather than inserting one on first read, so the table doesn't grow one
/// row per signed-up user who never opens this screen.
abstract class NotificationPreferences implements _i1.SerializableModel {
  NotificationPreferences._({
    this.id,
    required this.userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) : itemAdded = itemAdded ?? true,
       memberJoined = memberJoined ?? false,
       listFinished = listFinished ?? false;

  factory NotificationPreferences({
    _i1.UuidValue? id,
    required _i1.UuidValue userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) = _NotificationPreferencesImpl;

  factory NotificationPreferences.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationPreferences(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      itemAdded: jsonSerialization['itemAdded'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['itemAdded']),
      memberJoined: jsonSerialization['memberJoined'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['memberJoined']),
      listFinished: jsonSerialization['listFinished'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['listFinished']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue userId;

  /// "Someone adds an item" -- on by default; the design's own words:
  /// "Off by default except the first -- nobody installs a list app for
  /// alerts."
  bool itemAdded;

  /// "Someone joins a list."
  bool memberJoined;

  /// "A list is finished" -- when the last item is checked off.
  bool listFinished;

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationPreferences copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationPreferences',
      if (id != null) 'id': id?.toJson(),
      'userId': userId.toJson(),
      'itemAdded': itemAdded,
      'memberJoined': memberJoined,
      'listFinished': listFinished,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationPreferencesImpl extends NotificationPreferences {
  _NotificationPreferencesImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) : super._(
         id: id,
         userId: userId,
         itemAdded: itemAdded,
         memberJoined: memberJoined,
         listFinished: listFinished,
       );

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationPreferences copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) {
    return NotificationPreferences(
      id: id is _i1.UuidValue? ? id : this.id,
      userId: userId ?? this.userId,
      itemAdded: itemAdded ?? this.itemAdded,
      memberJoined: memberJoined ?? this.memberJoined,
      listFinished: listFinished ?? this.listFinished,
    );
  }
}
