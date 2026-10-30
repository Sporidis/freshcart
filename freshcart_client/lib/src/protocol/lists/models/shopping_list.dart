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
import '../../lists/models/list_member.dart' as _i2;
import '../../items/models/shopping_item.dart' as _i3;
import '../../shops/models/shop.dart' as _i4;
import '../../notifications/models/list_mute.dart' as _i5;
import '../../notifications/models/pending_item_notification.dart' as _i6;
import '../../items/models/item_name_history.dart' as _i7;
import 'package:freshcart_client/src/protocol/protocol.dart' as _i8;

/// A shopping list shared by one or more people.
abstract class ShoppingList implements _i1.SerializableModel {
  ShoppingList._({
    this.id,
    required this.name,
    this.joinCode,
    this.joinCodeExpiresAt,
    required this.ownerId,
    DateTime? createdAt,
    this.members,
    this.items,
    this.shops,
    this.mutes,
    this.pendingNotifications,
    this.itemNameHistory,
    bool? clearCheckedAfterShopping,
  }) : createdAt = createdAt ?? DateTime.now(),
       clearCheckedAfterShopping = clearCheckedAfterShopping ?? false;

  factory ShoppingList({
    _i1.UuidValue? id,
    required String name,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    required _i1.UuidValue ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
    List<_i5.ListMute>? mutes,
    List<_i6.PendingItemNotification>? pendingNotifications,
    List<_i7.ItemNameHistory>? itemNameHistory,
    bool? clearCheckedAfterShopping,
  }) = _ShoppingListImpl;

  factory ShoppingList.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShoppingList(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      joinCode: jsonSerialization['joinCode'] as String?,
      joinCodeExpiresAt: jsonSerialization['joinCodeExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['joinCodeExpiresAt'],
            ),
      ownerId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      members: jsonSerialization['members'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i2.ListMember>>(
              jsonSerialization['members'],
            ),
      items: jsonSerialization['items'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i3.ShoppingItem>>(
              jsonSerialization['items'],
            ),
      shops: jsonSerialization['shops'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i4.Shop>>(
              jsonSerialization['shops'],
            ),
      mutes: jsonSerialization['mutes'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i5.ListMute>>(
              jsonSerialization['mutes'],
            ),
      pendingNotifications: jsonSerialization['pendingNotifications'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i6.PendingItemNotification>>(
              jsonSerialization['pendingNotifications'],
            ),
      itemNameHistory: jsonSerialization['itemNameHistory'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i7.ItemNameHistory>>(
              jsonSerialization['itemNameHistory'],
            ),
      clearCheckedAfterShopping:
          jsonSerialization['clearCheckedAfterShopping'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['clearCheckedAfterShopping'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// Readable list name.
  String name;

  /// The code used to join this list, valid until [joinCodeExpiresAt].
  ///
  /// Null until the first invite is opened. Always written together with
  /// [joinCodeExpiresAt]; the pair maps to the domain's `ListInvite`.
  String? joinCode;

  /// The moment [joinCode] stops being accepted.
  ///
  /// Null on rows created before invites expired, which makes their legacy
  /// codes unusable.
  DateTime? joinCodeExpiresAt;

  /// The `authUserId` of whoever created the list.
  ///
  /// A plain column rather than a relation to `AuthUser` on purpose: deleting
  /// an account must not cascade-delete a list other people are still using.
  _i1.UuidValue ownerId;

  DateTime createdAt;

  /// Who belongs to this list.
  List<_i2.ListMember>? members;

  /// The items on this list.
  List<_i3.ShoppingItem>? items;

  /// The shops items on this list can be tagged to.
  List<_i4.Shop>? shops;

  /// Per-user mutes for this list.
  List<_i5.ListMute>? mutes;

  /// Buffered notifications awaiting a flush.
  List<_i6.PendingItemNotification>? pendingNotifications;

  /// Product names typed on this list before, for the add control's
  /// suggestion chips.
  List<_i7.ItemNameHistory>? itemNameHistory;

  /// Whether checked items are cleared automatically once every item on the
  /// list is checked, rather than by an explicit "Clear checked" action.
  ///
  /// `defaultPersist=false` backfills existing rows with the same default
  /// as new lists, following the pattern used for `Shop.isActive`.
  bool clearCheckedAfterShopping;

  /// Returns a shallow copy of this [ShoppingList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShoppingList copyWith({
    _i1.UuidValue? id,
    String? name,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    _i1.UuidValue? ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
    List<_i5.ListMute>? mutes,
    List<_i6.PendingItemNotification>? pendingNotifications,
    List<_i7.ItemNameHistory>? itemNameHistory,
    bool? clearCheckedAfterShopping,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShoppingList',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      if (joinCode != null) 'joinCode': joinCode,
      if (joinCodeExpiresAt != null)
        'joinCodeExpiresAt': joinCodeExpiresAt?.toJson(),
      'ownerId': ownerId.toJson(),
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJson()),
      if (items != null) 'items': items?.toJson(valueToJson: (v) => v.toJson()),
      if (shops != null) 'shops': shops?.toJson(valueToJson: (v) => v.toJson()),
      if (mutes != null) 'mutes': mutes?.toJson(valueToJson: (v) => v.toJson()),
      if (pendingNotifications != null)
        'pendingNotifications': pendingNotifications?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (itemNameHistory != null)
        'itemNameHistory': itemNameHistory?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      'clearCheckedAfterShopping': clearCheckedAfterShopping,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShoppingListImpl extends ShoppingList {
  _ShoppingListImpl({
    _i1.UuidValue? id,
    required String name,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    required _i1.UuidValue ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
    List<_i5.ListMute>? mutes,
    List<_i6.PendingItemNotification>? pendingNotifications,
    List<_i7.ItemNameHistory>? itemNameHistory,
    bool? clearCheckedAfterShopping,
  }) : super._(
         id: id,
         name: name,
         joinCode: joinCode,
         joinCodeExpiresAt: joinCodeExpiresAt,
         ownerId: ownerId,
         createdAt: createdAt,
         members: members,
         items: items,
         shops: shops,
         mutes: mutes,
         pendingNotifications: pendingNotifications,
         itemNameHistory: itemNameHistory,
         clearCheckedAfterShopping: clearCheckedAfterShopping,
       );

  /// Returns a shallow copy of this [ShoppingList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ShoppingList copyWith({
    Object? id = _Undefined,
    String? name,
    Object? joinCode = _Undefined,
    Object? joinCodeExpiresAt = _Undefined,
    _i1.UuidValue? ownerId,
    DateTime? createdAt,
    Object? members = _Undefined,
    Object? items = _Undefined,
    Object? shops = _Undefined,
    Object? mutes = _Undefined,
    Object? pendingNotifications = _Undefined,
    Object? itemNameHistory = _Undefined,
    bool? clearCheckedAfterShopping,
  }) {
    return ShoppingList(
      id: id is _i1.UuidValue? ? id : this.id,
      name: name ?? this.name,
      joinCode: joinCode is String? ? joinCode : this.joinCode,
      joinCodeExpiresAt: joinCodeExpiresAt is DateTime?
          ? joinCodeExpiresAt
          : this.joinCodeExpiresAt,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      members: members is List<_i2.ListMember>?
          ? members
          : this.members?.map((e0) => e0.copyWith()).toList(),
      items: items is List<_i3.ShoppingItem>?
          ? items
          : this.items?.map((e0) => e0.copyWith()).toList(),
      shops: shops is List<_i4.Shop>?
          ? shops
          : this.shops?.map((e0) => e0.copyWith()).toList(),
      mutes: mutes is List<_i5.ListMute>?
          ? mutes
          : this.mutes?.map((e0) => e0.copyWith()).toList(),
      pendingNotifications:
          pendingNotifications is List<_i6.PendingItemNotification>?
          ? pendingNotifications
          : this.pendingNotifications?.map((e0) => e0.copyWith()).toList(),
      itemNameHistory: itemNameHistory is List<_i7.ItemNameHistory>?
          ? itemNameHistory
          : this.itemNameHistory?.map((e0) => e0.copyWith()).toList(),
      clearCheckedAfterShopping:
          clearCheckedAfterShopping ?? this.clearCheckedAfterShopping,
    );
  }
}
