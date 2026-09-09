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
import '../../items/models/item_change_kind.dart' as _i2;
import '../../items/models/shopping_item.dart' as _i3;
import 'package:freshcart_client/src/protocol/protocol.dart' as _i4;

/// A single change to a list's items, broadcast to everyone watching it.
///
/// A delta rather than the whole list: a list can hold hundreds of items and a
/// change usually touches one, so re-sending everything on every keystroke
/// would waste the connection this feature exists to make feel instant.
/// Subscribers keep the merged list themselves.
abstract class ItemChange implements _i1.SerializableModel {
  ItemChange._({
    required this.kind,
    required this.itemId,
    this.item,
    required this.actorId,
  });

  factory ItemChange({
    required _i2.ItemChangeKind kind,
    required _i1.UuidValue itemId,
    _i3.ShoppingItem? item,
    required _i1.UuidValue actorId,
  }) = _ItemChangeImpl;

  factory ItemChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return ItemChange(
      kind: _i2.ItemChangeKind.fromJson((jsonSerialization['kind'] as String)),
      itemId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['itemId']),
      item: jsonSerialization['item'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.ShoppingItem>(
              jsonSerialization['item'],
            ),
      actorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
    );
  }

  _i2.ItemChangeKind kind;

  /// The item's id. Present for every kind, including removals.
  _i1.UuidValue itemId;

  /// The item's current state. Null for a removal.
  _i3.ShoppingItem? item;

  /// Who made the change. Clients use this to avoid re-announcing their own
  /// edits, and the notification layer uses it to never notify the actor.
  _i1.UuidValue actorId;

  /// Returns a shallow copy of this [ItemChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ItemChange copyWith({
    _i2.ItemChangeKind? kind,
    _i1.UuidValue? itemId,
    _i3.ShoppingItem? item,
    _i1.UuidValue? actorId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ItemChange',
      'kind': kind.toJson(),
      'itemId': itemId.toJson(),
      if (item != null) 'item': item?.toJson(),
      'actorId': actorId.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemChangeImpl extends ItemChange {
  _ItemChangeImpl({
    required _i2.ItemChangeKind kind,
    required _i1.UuidValue itemId,
    _i3.ShoppingItem? item,
    required _i1.UuidValue actorId,
  }) : super._(
         kind: kind,
         itemId: itemId,
         item: item,
         actorId: actorId,
       );

  /// Returns a shallow copy of this [ItemChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ItemChange copyWith({
    _i2.ItemChangeKind? kind,
    _i1.UuidValue? itemId,
    Object? item = _Undefined,
    _i1.UuidValue? actorId,
  }) {
    return ItemChange(
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      item: item is _i3.ShoppingItem? ? item : this.item?.copyWith(),
      actorId: actorId ?? this.actorId,
    );
  }
}
