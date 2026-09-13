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
import '../../items/models/shopping_item.dart' as _i2;
import 'package:freshcart_client/src/protocol/protocol.dart' as _i3;

/// A shop that items can be tagged to — "Colruyt", "Delhaize", "the bakery".
///
/// Scoped to a list, not to a user: everyone collaborating on a list must see
/// the same shop set, otherwise one member's tag would be meaningless to
/// another. See docs/decisions.md #19.
abstract class Shop implements _i1.SerializableModel {
  Shop._({
    this.id,
    required this.listId,
    required this.name,
    required this.colorArgb,
    this.items,
    bool? isActive,
  }) : isActive = isActive ?? true;

  factory Shop({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    required int colorArgb,
    List<_i2.ShoppingItem>? items,
    bool? isActive,
  }) = _ShopImpl;

  factory Shop.fromJson(Map<String, dynamic> jsonSerialization) {
    return Shop(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      name: jsonSerialization['name'] as String,
      colorArgb: jsonSerialization['colorArgb'] as int,
      items: jsonSerialization['items'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.ShoppingItem>>(
              jsonSerialization['items'],
            ),
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// The list these shops belong to.
  _i1.UuidValue listId;

  /// Display name.
  String name;

  /// The seed colour as a 32-bit ARGB integer. The app turns this into a full
  /// Material colour scheme, so picking a shop re-themes the whole app.
  int colorArgb;

  /// Items tagged to this shop.
  List<_i2.ShoppingItem>? items;

  /// Whether this shop shows as a tab in the shop nav. Does not affect
  /// whether items can still be tagged to it -- "not shopping there this
  /// week" and "this shop no longer exists" are different facts, so only
  /// the tab strip reads this.
  ///
  /// defaultPersist, not just defaultModel -- same reasoning as
  /// ShoppingItem.sortOrder above: a database-level default is what lets
  /// this column be added to the existing table in place, backfilling every
  /// shop already in it as active rather than leaving them with no value.
  bool isActive;

  /// Returns a shallow copy of this [Shop]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Shop copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    String? name,
    int? colorArgb,
    List<_i2.ShoppingItem>? items,
    bool? isActive,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Shop',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'colorArgb': colorArgb,
      if (items != null) 'items': items?.toJson(valueToJson: (v) => v.toJson()),
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShopImpl extends Shop {
  _ShopImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    required int colorArgb,
    List<_i2.ShoppingItem>? items,
    bool? isActive,
  }) : super._(
         id: id,
         listId: listId,
         name: name,
         colorArgb: colorArgb,
         items: items,
         isActive: isActive,
       );

  /// Returns a shallow copy of this [Shop]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Shop copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    String? name,
    int? colorArgb,
    Object? items = _Undefined,
    bool? isActive,
  }) {
    return Shop(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      items: items is List<_i2.ShoppingItem>?
          ? items
          : this.items?.map((e0) => e0.copyWith()).toList(),
      isActive: isActive ?? this.isActive,
    );
  }
}
