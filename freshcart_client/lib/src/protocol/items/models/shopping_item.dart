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
import '../../items/models/note.dart' as _i2;
import 'package:freshcart_client/src/protocol/protocol.dart' as _i3;

/// A single line on a shopping list.
abstract class ShoppingItem implements _i1.SerializableModel {
  ShoppingItem._({
    this.id,
    required this.listId,
    required this.name,
    int? quantity,
    bool? isChecked,
    this.shopId,
    this.note,
    required this.addedBy,
    this.checkedBy,
    this.checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : quantity = quantity ?? 1,
       isChecked = isChecked ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ShoppingItem({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    int? quantity,
    bool? isChecked,
    _i1.UuidValue? shopId,
    _i2.Note? note,
    required _i1.UuidValue addedBy,
    _i1.UuidValue? checkedBy,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ShoppingItemImpl;

  factory ShoppingItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShoppingItem(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      name: jsonSerialization['name'] as String,
      quantity: jsonSerialization['quantity'] as int?,
      isChecked: jsonSerialization['isChecked'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isChecked']),
      shopId: jsonSerialization['shopId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['shopId']),
      note: jsonSerialization['note'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Note>(jsonSerialization['note']),
      addedBy: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['addedBy'],
      ),
      checkedBy: jsonSerialization['checkedBy'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['checkedBy']),
      checkedAt: jsonSerialization['checkedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['checkedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  /// The list this item belongs to.
  ///
  /// Declared as an explicit foreign-key field rather than an object relation:
  /// it mirrors the domain entity, which holds a `ListId`, not a whole
  /// `ShoppingList`, and it stops a read of one item dragging a list with it.
  _i1.UuidValue listId;

  /// What to buy.
  String name;

  /// How many. Always at least 1; enforced by the domain's AddItem use case.
  int quantity;

  bool isChecked;

  /// Optional shop tag. `SetNull` on delete so removing a shop untags its
  /// items rather than deleting them — losing a shop must never lose the
  /// shopping.
  ///
  /// Explicitly nullable: an object relation (`shop: Shop?`) generated a
  /// NOT NULL column here, which would have made the ON DELETE SET NULL
  /// constraint fail the first time anyone removed a shop.
  _i1.UuidValue? shopId;

  /// Optional annotation, stored as JSON (see Note).
  _i2.Note? note;

  /// The `authUserId` of whoever added it.
  _i1.UuidValue addedBy;

  /// Who checked it off, and when. Both null while unchecked.
  _i1.UuidValue? checkedBy;

  DateTime? checkedAt;

  DateTime createdAt;

  /// The optimistic-concurrency token. A write carries the value the client
  /// last saw; if the stored row has moved on, the server rejects the write
  /// and the client rolls its optimistic edit back.
  DateTime updatedAt;

  /// Returns a shallow copy of this [ShoppingItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShoppingItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    String? name,
    int? quantity,
    bool? isChecked,
    _i1.UuidValue? shopId,
    _i2.Note? note,
    _i1.UuidValue? addedBy,
    _i1.UuidValue? checkedBy,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShoppingItem',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'quantity': quantity,
      'isChecked': isChecked,
      if (shopId != null) 'shopId': shopId?.toJson(),
      if (note != null) 'note': note?.toJson(),
      'addedBy': addedBy.toJson(),
      if (checkedBy != null) 'checkedBy': checkedBy?.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShoppingItemImpl extends ShoppingItem {
  _ShoppingItemImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    int? quantity,
    bool? isChecked,
    _i1.UuidValue? shopId,
    _i2.Note? note,
    required _i1.UuidValue addedBy,
    _i1.UuidValue? checkedBy,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         listId: listId,
         name: name,
         quantity: quantity,
         isChecked: isChecked,
         shopId: shopId,
         note: note,
         addedBy: addedBy,
         checkedBy: checkedBy,
         checkedAt: checkedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ShoppingItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ShoppingItem copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    String? name,
    int? quantity,
    bool? isChecked,
    Object? shopId = _Undefined,
    Object? note = _Undefined,
    _i1.UuidValue? addedBy,
    Object? checkedBy = _Undefined,
    Object? checkedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      shopId: shopId is _i1.UuidValue? ? shopId : this.shopId,
      note: note is _i2.Note? ? note : this.note?.copyWith(),
      addedBy: addedBy ?? this.addedBy,
      checkedBy: checkedBy is _i1.UuidValue? ? checkedBy : this.checkedBy,
      checkedAt: checkedAt is DateTime? ? checkedAt : this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
