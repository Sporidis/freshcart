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

/// A product name typed on a list before, so the add control's suggestion
/// chips (and, eventually, search's own "Recently bought") can offer it
/// again. Kept as its own record rather than derived from ShoppingItem:
/// every delete path (ItemService.remove, clearChecked, removeMany) is a
/// hard delete, so a name would disappear from history the moment the item
/// did -- exactly when a suggestion for it (re-adding something just
/// cleared off a finished list) would be most useful.
abstract class ItemNameHistory implements _i1.SerializableModel {
  ItemNameHistory._({
    this.id,
    required this.listId,
    required this.name,
    DateTime? lastUsedAt,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  factory ItemNameHistory({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    DateTime? lastUsedAt,
  }) = _ItemNameHistoryImpl;

  factory ItemNameHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return ItemNameHistory(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      name: jsonSerialization['name'] as String,
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// The list this history belongs to. Suggestions are per-list, not
  /// household-wide -- the same scope shops already use (decisions #19).
  _i1.UuidValue listId;

  /// Exactly as typed. Matched case-insensitively at query time (ILIKE), but
  /// the unique index below is on the exact string, so "Milk" and "milk"
  /// persist as two separate rows -- a deliberate simplification, not an
  /// oversight (see decisions.md).
  String name;

  /// Bumped every time [name] is added again, so suggestions surface the
  /// most recently used first, not just whichever was typed first.
  DateTime lastUsedAt;

  /// Returns a shallow copy of this [ItemNameHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ItemNameHistory copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    String? name,
    DateTime? lastUsedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ItemNameHistory',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemNameHistoryImpl extends ItemNameHistory {
  _ItemNameHistoryImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    DateTime? lastUsedAt,
  }) : super._(
         id: id,
         listId: listId,
         name: name,
         lastUsedAt: lastUsedAt,
       );

  /// Returns a shallow copy of this [ItemNameHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ItemNameHistory copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    String? name,
    DateTime? lastUsedAt,
  }) {
    return ItemNameHistory(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
