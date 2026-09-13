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
// ignore_for_file: unnecessary_null_comparison

import 'package:serverpod/serverpod.dart' as _i1;
import '../../items/models/shopping_item.dart' as _i2;
import 'package:freshcart_server/src/generated/protocol.dart' as _i3;

/// A shop that items can be tagged to — "Colruyt", "Delhaize", "the bakery".
///
/// Scoped to a list, not to a user: everyone collaborating on a list must see
/// the same shop set, otherwise one member's tag would be meaningless to
/// another. See docs/decisions.md #19.
abstract class Shop
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
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

  static final t = ShopTable();

  static const db = ShopRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Shop',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'colorArgb': colorArgb,
      if (items != null)
        'items': items?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'isActive': isActive,
    };
  }

  static ShopInclude include({_i2.ShoppingItemIncludeList? items}) {
    return ShopInclude._(items: items);
  }

  static ShopIncludeList includeList({
    _i1.WhereExpressionBuilder<ShopTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShopTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShopTable>? orderByList,
    ShopInclude? include,
  }) {
    return ShopIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Shop.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Shop.t),
      include: include,
    );
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

class ShopUpdateTable extends _i1.UpdateTable<ShopTable> {
  ShopUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> listId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.listId,
        value,
      );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<int, int> colorArgb(int value) => _i1.ColumnValue(
    table.colorArgb,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );
}

class ShopTable extends _i1.Table<_i1.UuidValue?> {
  ShopTable({super.tableRelation}) : super(tableName: 'freshcart_shop') {
    updateTable = ShopUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    colorArgb = _i1.ColumnInt(
      'colorArgb',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
  }

  late final ShopUpdateTable updateTable;

  /// The list these shops belong to.
  late final _i1.ColumnUuid listId;

  /// Display name.
  late final _i1.ColumnString name;

  /// The seed colour as a 32-bit ARGB integer. The app turns this into a full
  /// Material colour scheme, so picking a shop re-themes the whole app.
  late final _i1.ColumnInt colorArgb;

  /// Items tagged to this shop.
  _i2.ShoppingItemTable? ___items;

  /// Items tagged to this shop.
  _i1.ManyRelation<_i2.ShoppingItemTable>? _items;

  /// Whether this shop shows as a tab in the shop nav. Does not affect
  /// whether items can still be tagged to it -- "not shopping there this
  /// week" and "this shop no longer exists" are different facts, so only
  /// the tab strip reads this.
  ///
  /// defaultPersist, not just defaultModel -- same reasoning as
  /// ShoppingItem.sortOrder above: a database-level default is what lets
  /// this column be added to the existing table in place, backfilling every
  /// shop already in it as active rather than leaving them with no value.
  late final _i1.ColumnBool isActive;

  _i2.ShoppingItemTable get __items {
    if (___items != null) return ___items!;
    ___items = _i1.createRelationTable(
      relationFieldName: '__items',
      field: Shop.t.id,
      foreignField: _i2.ShoppingItem.t.shopId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ShoppingItemTable(tableRelation: foreignTableRelation),
    );
    return ___items!;
  }

  _i1.ManyRelation<_i2.ShoppingItemTable> get items {
    if (_items != null) return _items!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'items',
      field: Shop.t.id,
      foreignField: _i2.ShoppingItem.t.shopId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ShoppingItemTable(tableRelation: foreignTableRelation),
    );
    _items = _i1.ManyRelation<_i2.ShoppingItemTable>(
      tableWithRelations: relationTable,
      table: _i2.ShoppingItemTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _items!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    name,
    colorArgb,
    isActive,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'items') {
      return __items;
    }
    return null;
  }
}

class ShopInclude extends _i1.IncludeObject {
  ShopInclude._({_i2.ShoppingItemIncludeList? items}) {
    _items = items;
  }

  _i2.ShoppingItemIncludeList? _items;

  @override
  Map<String, _i1.Include?> get includes => {'items': _items};

  @override
  _i1.Table<_i1.UuidValue?> get table => Shop.t;
}

class ShopIncludeList extends _i1.IncludeList {
  ShopIncludeList._({
    _i1.WhereExpressionBuilder<ShopTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Shop.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Shop.t;
}

class ShopRepository {
  const ShopRepository._();

  final attach = const ShopAttachRepository._();

  final attachRow = const ShopAttachRowRepository._();

  final detach = const ShopDetachRepository._();

  final detachRow = const ShopDetachRowRepository._();

  /// Returns a list of [Shop]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Shop>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShopTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShopTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShopTable>? orderByList,
    _i1.Transaction? transaction,
    ShopInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Shop>(
      where: where?.call(Shop.t),
      orderBy: orderBy?.call(Shop.t),
      orderByList: orderByList?.call(Shop.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Shop] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Shop?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShopTable>? where,
    int? offset,
    _i1.OrderByBuilder<ShopTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShopTable>? orderByList,
    _i1.Transaction? transaction,
    ShopInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Shop>(
      where: where?.call(Shop.t),
      orderBy: orderBy?.call(Shop.t),
      orderByList: orderByList?.call(Shop.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Shop] by its [id] or null if no such row exists.
  Future<Shop?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ShopInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Shop>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Shop]s in the list and returns the inserted rows.
  ///
  /// The returned [Shop]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Shop>> insert(
    _i1.DatabaseSession session,
    List<Shop> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Shop>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Shop] and returns the inserted row.
  ///
  /// The returned [Shop] will have its `id` field set.
  Future<Shop> insertRow(
    _i1.DatabaseSession session,
    Shop row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Shop>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Shop]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Shop>> update(
    _i1.DatabaseSession session,
    List<Shop> rows, {
    _i1.ColumnSelections<ShopTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Shop>(
      rows,
      columns: columns?.call(Shop.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Shop]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Shop> updateRow(
    _i1.DatabaseSession session,
    Shop row, {
    _i1.ColumnSelections<ShopTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Shop>(
      row,
      columns: columns?.call(Shop.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Shop] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Shop?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ShopUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Shop>(
      id,
      columnValues: columnValues(Shop.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Shop]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Shop>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ShopUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ShopTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShopTable>? orderBy,
    _i1.OrderByListBuilder<ShopTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Shop>(
      columnValues: columnValues(Shop.t.updateTable),
      where: where(Shop.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Shop.t),
      orderByList: orderByList?.call(Shop.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Shop]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Shop>> delete(
    _i1.DatabaseSession session,
    List<Shop> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Shop>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Shop].
  Future<Shop> deleteRow(
    _i1.DatabaseSession session,
    Shop row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Shop>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Shop>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShopTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Shop>(
      where: where(Shop.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShopTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Shop>(
      where: where?.call(Shop.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Shop] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShopTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Shop>(
      where: where(Shop.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ShopAttachRepository {
  const ShopAttachRepository._();

  /// Creates a relation between this [Shop] and the given [ShoppingItem]s
  /// by setting each [ShoppingItem]'s foreign key `shopId` to refer to this [Shop].
  Future<void> items(
    _i1.DatabaseSession session,
    Shop shop,
    List<_i2.ShoppingItem> shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.any((e) => e.id == null)) {
      throw ArgumentError.notNull('shoppingItem.id');
    }
    if (shop.id == null) {
      throw ArgumentError.notNull('shop.id');
    }

    var $shoppingItem = shoppingItem
        .map((e) => e.copyWith(shopId: shop.id))
        .toList();
    await session.db.update<_i2.ShoppingItem>(
      $shoppingItem,
      columns: [_i2.ShoppingItem.t.shopId],
      transaction: transaction,
    );
  }
}

class ShopAttachRowRepository {
  const ShopAttachRowRepository._();

  /// Creates a relation between this [Shop] and the given [ShoppingItem]
  /// by setting the [ShoppingItem]'s foreign key `shopId` to refer to this [Shop].
  Future<void> items(
    _i1.DatabaseSession session,
    Shop shop,
    _i2.ShoppingItem shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.id == null) {
      throw ArgumentError.notNull('shoppingItem.id');
    }
    if (shop.id == null) {
      throw ArgumentError.notNull('shop.id');
    }

    var $shoppingItem = shoppingItem.copyWith(shopId: shop.id);
    await session.db.updateRow<_i2.ShoppingItem>(
      $shoppingItem,
      columns: [_i2.ShoppingItem.t.shopId],
      transaction: transaction,
    );
  }
}

class ShopDetachRepository {
  const ShopDetachRepository._();

  /// Detaches the relation between this [Shop] and the given [ShoppingItem]
  /// by setting the [ShoppingItem]'s foreign key `shopId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> items(
    _i1.DatabaseSession session,
    List<_i2.ShoppingItem> shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.any((e) => e.id == null)) {
      throw ArgumentError.notNull('shoppingItem.id');
    }

    var $shoppingItem = shoppingItem
        .map((e) => e.copyWith(shopId: null))
        .toList();
    await session.db.update<_i2.ShoppingItem>(
      $shoppingItem,
      columns: [_i2.ShoppingItem.t.shopId],
      transaction: transaction,
    );
  }
}

class ShopDetachRowRepository {
  const ShopDetachRowRepository._();

  /// Detaches the relation between this [Shop] and the given [ShoppingItem]
  /// by setting the [ShoppingItem]'s foreign key `shopId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> items(
    _i1.DatabaseSession session,
    _i2.ShoppingItem shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.id == null) {
      throw ArgumentError.notNull('shoppingItem.id');
    }

    var $shoppingItem = shoppingItem.copyWith(shopId: null);
    await session.db.updateRow<_i2.ShoppingItem>(
      $shoppingItem,
      columns: [_i2.ShoppingItem.t.shopId],
      transaction: transaction,
    );
  }
}
