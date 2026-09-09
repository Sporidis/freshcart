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
import '../../lists/models/list_member.dart' as _i2;
import '../../items/models/shopping_item.dart' as _i3;
import '../../shops/models/shop.dart' as _i4;
import 'package:freshcart_server/src/generated/protocol.dart' as _i5;

/// A shopping list shared by one or more people.
abstract class ShoppingList
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ShoppingList._({
    this.id,
    required this.name,
    required this.joinCode,
    required this.ownerId,
    DateTime? createdAt,
    this.members,
    this.items,
    this.shops,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ShoppingList({
    _i1.UuidValue? id,
    required String name,
    required String joinCode,
    required _i1.UuidValue ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
  }) = _ShoppingListImpl;

  factory ShoppingList.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShoppingList(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      joinCode: jsonSerialization['joinCode'] as String,
      ownerId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      members: jsonSerialization['members'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i2.ListMember>>(
              jsonSerialization['members'],
            ),
      items: jsonSerialization['items'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i3.ShoppingItem>>(
              jsonSerialization['items'],
            ),
      shops: jsonSerialization['shops'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i4.Shop>>(
              jsonSerialization['shops'],
            ),
    );
  }

  static final t = ShoppingListTable();

  static const db = ShoppingListRepository._();

  @override
  _i1.UuidValue? id;

  /// Human-readable list name.
  String name;

  /// The short code someone types to join this list.
  String joinCode;

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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ShoppingList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShoppingList copyWith({
    _i1.UuidValue? id,
    String? name,
    String? joinCode,
    _i1.UuidValue? ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShoppingList',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'joinCode': joinCode,
      'ownerId': ownerId.toJson(),
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJson()),
      if (items != null) 'items': items?.toJson(valueToJson: (v) => v.toJson()),
      if (shops != null) 'shops': shops?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ShoppingList',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'joinCode': joinCode,
      'ownerId': ownerId.toJson(),
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (items != null)
        'items': items?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (shops != null)
        'shops': shops?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static ShoppingListInclude include({
    _i2.ListMemberIncludeList? members,
    _i3.ShoppingItemIncludeList? items,
    _i4.ShopIncludeList? shops,
  }) {
    return ShoppingListInclude._(
      members: members,
      items: items,
      shops: shops,
    );
  }

  static ShoppingListIncludeList includeList({
    _i1.WhereExpressionBuilder<ShoppingListTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingListTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingListTable>? orderByList,
    ShoppingListInclude? include,
  }) {
    return ShoppingListIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShoppingList.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ShoppingList.t),
      include: include,
    );
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
    required String joinCode,
    required _i1.UuidValue ownerId,
    DateTime? createdAt,
    List<_i2.ListMember>? members,
    List<_i3.ShoppingItem>? items,
    List<_i4.Shop>? shops,
  }) : super._(
         id: id,
         name: name,
         joinCode: joinCode,
         ownerId: ownerId,
         createdAt: createdAt,
         members: members,
         items: items,
         shops: shops,
       );

  /// Returns a shallow copy of this [ShoppingList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ShoppingList copyWith({
    Object? id = _Undefined,
    String? name,
    String? joinCode,
    _i1.UuidValue? ownerId,
    DateTime? createdAt,
    Object? members = _Undefined,
    Object? items = _Undefined,
    Object? shops = _Undefined,
  }) {
    return ShoppingList(
      id: id is _i1.UuidValue? ? id : this.id,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
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
    );
  }
}

class ShoppingListUpdateTable extends _i1.UpdateTable<ShoppingListTable> {
  ShoppingListUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> joinCode(String value) => _i1.ColumnValue(
    table.joinCode,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> ownerId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.ownerId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class ShoppingListTable extends _i1.Table<_i1.UuidValue?> {
  ShoppingListTable({super.tableRelation})
    : super(tableName: 'freshcart_shopping_list') {
    updateTable = ShoppingListUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    joinCode = _i1.ColumnString(
      'joinCode',
      this,
    );
    ownerId = _i1.ColumnUuid(
      'ownerId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ShoppingListUpdateTable updateTable;

  /// Human-readable list name.
  late final _i1.ColumnString name;

  /// The short code someone types to join this list.
  late final _i1.ColumnString joinCode;

  /// The `authUserId` of whoever created the list.
  ///
  /// A plain column rather than a relation to `AuthUser` on purpose: deleting
  /// an account must not cascade-delete a list other people are still using.
  late final _i1.ColumnUuid ownerId;

  late final _i1.ColumnDateTime createdAt;

  /// Who belongs to this list.
  _i2.ListMemberTable? ___members;

  /// Who belongs to this list.
  _i1.ManyRelation<_i2.ListMemberTable>? _members;

  /// The items on this list.
  _i3.ShoppingItemTable? ___items;

  /// The items on this list.
  _i1.ManyRelation<_i3.ShoppingItemTable>? _items;

  /// The shops items on this list can be tagged to.
  _i4.ShopTable? ___shops;

  /// The shops items on this list can be tagged to.
  _i1.ManyRelation<_i4.ShopTable>? _shops;

  _i2.ListMemberTable get __members {
    if (___members != null) return ___members!;
    ___members = _i1.createRelationTable(
      relationFieldName: '__members',
      field: ShoppingList.t.id,
      foreignField: _i2.ListMember.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ListMemberTable(tableRelation: foreignTableRelation),
    );
    return ___members!;
  }

  _i3.ShoppingItemTable get __items {
    if (___items != null) return ___items!;
    ___items = _i1.createRelationTable(
      relationFieldName: '__items',
      field: ShoppingList.t.id,
      foreignField: _i3.ShoppingItem.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.ShoppingItemTable(tableRelation: foreignTableRelation),
    );
    return ___items!;
  }

  _i4.ShopTable get __shops {
    if (___shops != null) return ___shops!;
    ___shops = _i1.createRelationTable(
      relationFieldName: '__shops',
      field: ShoppingList.t.id,
      foreignField: _i4.Shop.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.ShopTable(tableRelation: foreignTableRelation),
    );
    return ___shops!;
  }

  _i1.ManyRelation<_i2.ListMemberTable> get members {
    if (_members != null) return _members!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'members',
      field: ShoppingList.t.id,
      foreignField: _i2.ListMember.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ListMemberTable(tableRelation: foreignTableRelation),
    );
    _members = _i1.ManyRelation<_i2.ListMemberTable>(
      tableWithRelations: relationTable,
      table: _i2.ListMemberTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _members!;
  }

  _i1.ManyRelation<_i3.ShoppingItemTable> get items {
    if (_items != null) return _items!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'items',
      field: ShoppingList.t.id,
      foreignField: _i3.ShoppingItem.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.ShoppingItemTable(tableRelation: foreignTableRelation),
    );
    _items = _i1.ManyRelation<_i3.ShoppingItemTable>(
      tableWithRelations: relationTable,
      table: _i3.ShoppingItemTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _items!;
  }

  _i1.ManyRelation<_i4.ShopTable> get shops {
    if (_shops != null) return _shops!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'shops',
      field: ShoppingList.t.id,
      foreignField: _i4.Shop.t.listId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.ShopTable(tableRelation: foreignTableRelation),
    );
    _shops = _i1.ManyRelation<_i4.ShopTable>(
      tableWithRelations: relationTable,
      table: _i4.ShopTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _shops!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    joinCode,
    ownerId,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'members') {
      return __members;
    }
    if (relationField == 'items') {
      return __items;
    }
    if (relationField == 'shops') {
      return __shops;
    }
    return null;
  }
}

class ShoppingListInclude extends _i1.IncludeObject {
  ShoppingListInclude._({
    _i2.ListMemberIncludeList? members,
    _i3.ShoppingItemIncludeList? items,
    _i4.ShopIncludeList? shops,
  }) {
    _members = members;
    _items = items;
    _shops = shops;
  }

  _i2.ListMemberIncludeList? _members;

  _i3.ShoppingItemIncludeList? _items;

  _i4.ShopIncludeList? _shops;

  @override
  Map<String, _i1.Include?> get includes => {
    'members': _members,
    'items': _items,
    'shops': _shops,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => ShoppingList.t;
}

class ShoppingListIncludeList extends _i1.IncludeList {
  ShoppingListIncludeList._({
    _i1.WhereExpressionBuilder<ShoppingListTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ShoppingList.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ShoppingList.t;
}

class ShoppingListRepository {
  const ShoppingListRepository._();

  final attach = const ShoppingListAttachRepository._();

  final attachRow = const ShoppingListAttachRowRepository._();

  /// Returns a list of [ShoppingList]s matching the given query parameters.
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
  Future<List<ShoppingList>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingListTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingListTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingListTable>? orderByList,
    _i1.Transaction? transaction,
    ShoppingListInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ShoppingList>(
      where: where?.call(ShoppingList.t),
      orderBy: orderBy?.call(ShoppingList.t),
      orderByList: orderByList?.call(ShoppingList.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ShoppingList] matching the given query parameters.
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
  Future<ShoppingList?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingListTable>? where,
    int? offset,
    _i1.OrderByBuilder<ShoppingListTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingListTable>? orderByList,
    _i1.Transaction? transaction,
    ShoppingListInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ShoppingList>(
      where: where?.call(ShoppingList.t),
      orderBy: orderBy?.call(ShoppingList.t),
      orderByList: orderByList?.call(ShoppingList.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ShoppingList] by its [id] or null if no such row exists.
  Future<ShoppingList?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ShoppingListInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ShoppingList>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ShoppingList]s in the list and returns the inserted rows.
  ///
  /// The returned [ShoppingList]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ShoppingList>> insert(
    _i1.DatabaseSession session,
    List<ShoppingList> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ShoppingList>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ShoppingList] and returns the inserted row.
  ///
  /// The returned [ShoppingList] will have its `id` field set.
  Future<ShoppingList> insertRow(
    _i1.DatabaseSession session,
    ShoppingList row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ShoppingList>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ShoppingList]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ShoppingList>> update(
    _i1.DatabaseSession session,
    List<ShoppingList> rows, {
    _i1.ColumnSelections<ShoppingListTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ShoppingList>(
      rows,
      columns: columns?.call(ShoppingList.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShoppingList]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ShoppingList> updateRow(
    _i1.DatabaseSession session,
    ShoppingList row, {
    _i1.ColumnSelections<ShoppingListTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ShoppingList>(
      row,
      columns: columns?.call(ShoppingList.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShoppingList] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ShoppingList?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ShoppingListUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ShoppingList>(
      id,
      columnValues: columnValues(ShoppingList.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ShoppingList]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ShoppingList>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ShoppingListUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ShoppingListTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingListTable>? orderBy,
    _i1.OrderByListBuilder<ShoppingListTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ShoppingList>(
      columnValues: columnValues(ShoppingList.t.updateTable),
      where: where(ShoppingList.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShoppingList.t),
      orderByList: orderByList?.call(ShoppingList.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ShoppingList]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ShoppingList>> delete(
    _i1.DatabaseSession session,
    List<ShoppingList> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ShoppingList>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ShoppingList].
  Future<ShoppingList> deleteRow(
    _i1.DatabaseSession session,
    ShoppingList row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ShoppingList>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ShoppingList>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShoppingListTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ShoppingList>(
      where: where(ShoppingList.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingListTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ShoppingList>(
      where: where?.call(ShoppingList.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ShoppingList] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShoppingListTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ShoppingList>(
      where: where(ShoppingList.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ShoppingListAttachRepository {
  const ShoppingListAttachRepository._();

  /// Creates a relation between this [ShoppingList] and the given [ListMember]s
  /// by setting each [ListMember]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> members(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    List<_i2.ListMember> listMember, {
    _i1.Transaction? transaction,
  }) async {
    if (listMember.any((e) => e.id == null)) {
      throw ArgumentError.notNull('listMember.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $listMember = listMember
        .map((e) => e.copyWith(listId: shoppingList.id))
        .toList();
    await session.db.update<_i2.ListMember>(
      $listMember,
      columns: [_i2.ListMember.t.listId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [ShoppingList] and the given [ShoppingItem]s
  /// by setting each [ShoppingItem]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> items(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    List<_i3.ShoppingItem> shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.any((e) => e.id == null)) {
      throw ArgumentError.notNull('shoppingItem.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $shoppingItem = shoppingItem
        .map((e) => e.copyWith(listId: shoppingList.id))
        .toList();
    await session.db.update<_i3.ShoppingItem>(
      $shoppingItem,
      columns: [_i3.ShoppingItem.t.listId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [ShoppingList] and the given [Shop]s
  /// by setting each [Shop]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> shops(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    List<_i4.Shop> shop, {
    _i1.Transaction? transaction,
  }) async {
    if (shop.any((e) => e.id == null)) {
      throw ArgumentError.notNull('shop.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $shop = shop.map((e) => e.copyWith(listId: shoppingList.id)).toList();
    await session.db.update<_i4.Shop>(
      $shop,
      columns: [_i4.Shop.t.listId],
      transaction: transaction,
    );
  }
}

class ShoppingListAttachRowRepository {
  const ShoppingListAttachRowRepository._();

  /// Creates a relation between this [ShoppingList] and the given [ListMember]
  /// by setting the [ListMember]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> members(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    _i2.ListMember listMember, {
    _i1.Transaction? transaction,
  }) async {
    if (listMember.id == null) {
      throw ArgumentError.notNull('listMember.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $listMember = listMember.copyWith(listId: shoppingList.id);
    await session.db.updateRow<_i2.ListMember>(
      $listMember,
      columns: [_i2.ListMember.t.listId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [ShoppingList] and the given [ShoppingItem]
  /// by setting the [ShoppingItem]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> items(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    _i3.ShoppingItem shoppingItem, {
    _i1.Transaction? transaction,
  }) async {
    if (shoppingItem.id == null) {
      throw ArgumentError.notNull('shoppingItem.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $shoppingItem = shoppingItem.copyWith(listId: shoppingList.id);
    await session.db.updateRow<_i3.ShoppingItem>(
      $shoppingItem,
      columns: [_i3.ShoppingItem.t.listId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [ShoppingList] and the given [Shop]
  /// by setting the [Shop]'s foreign key `listId` to refer to this [ShoppingList].
  Future<void> shops(
    _i1.DatabaseSession session,
    ShoppingList shoppingList,
    _i4.Shop shop, {
    _i1.Transaction? transaction,
  }) async {
    if (shop.id == null) {
      throw ArgumentError.notNull('shop.id');
    }
    if (shoppingList.id == null) {
      throw ArgumentError.notNull('shoppingList.id');
    }

    var $shop = shop.copyWith(listId: shoppingList.id);
    await session.db.updateRow<_i4.Shop>(
      $shop,
      columns: [_i4.Shop.t.listId],
      transaction: transaction,
    );
  }
}
