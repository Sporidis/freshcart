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

import 'package:serverpod/serverpod.dart' as _i1;
import '../../items/models/note.dart' as _i2;
import 'package:freshcart_server/src/generated/protocol.dart' as _i3;

/// A single line on a shopping list.
abstract class ShoppingItem
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ShoppingItem._({
    this.id,
    required this.listId,
    required this.name,
    int? quantity,
    bool? isChecked,
    double? sortOrder,
    this.shopId,
    this.note,
    required this.addedBy,
    this.checkedBy,
    this.checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : quantity = quantity ?? 1,
       isChecked = isChecked ?? false,
       sortOrder = sortOrder ?? 0.0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ShoppingItem({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required String name,
    int? quantity,
    bool? isChecked,
    double? sortOrder,
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
      sortOrder: (jsonSerialization['sortOrder'] as num?)?.toDouble(),
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

  static final t = ShoppingItemTable();

  static const db = ShoppingItemRepository._();

  @override
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

  /// Manual ordering within a shop tab (drag-to-reorder). Fresh items append
  /// past the current end; a drag slots one item between its new neighbours
  /// by averaging their sortOrder, so a reorder only ever writes the one row
  /// that moved. See ShoppingItem.sortOrderBetween in the domain package,
  /// which is the single place that averaging is computed.
  ///
  /// defaultPersist, not defaultModel: a *database*-level default is what
  /// lets this column be added to an existing table in place. defaultModel
  /// alone left Postgres with no value to backfill existing rows with, and
  /// `serverpod create-migration` refused, warning it would have to drop and
  /// recreate the whole table instead.
  double sortOrder;

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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ShoppingItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShoppingItem copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    String? name,
    int? quantity,
    bool? isChecked,
    double? sortOrder,
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
      'sortOrder': sortOrder,
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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ShoppingItem',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'quantity': quantity,
      'isChecked': isChecked,
      'sortOrder': sortOrder,
      if (shopId != null) 'shopId': shopId?.toJson(),
      if (note != null) 'note': note?.toJsonForProtocol(),
      'addedBy': addedBy.toJson(),
      if (checkedBy != null) 'checkedBy': checkedBy?.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ShoppingItemInclude include() {
    return ShoppingItemInclude._();
  }

  static ShoppingItemIncludeList includeList({
    _i1.WhereExpressionBuilder<ShoppingItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingItemTable>? orderByList,
    ShoppingItemInclude? include,
  }) {
    return ShoppingItemIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShoppingItem.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ShoppingItem.t),
      include: include,
    );
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
    double? sortOrder,
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
         sortOrder: sortOrder,
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
    double? sortOrder,
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
      sortOrder: sortOrder ?? this.sortOrder,
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

class ShoppingItemUpdateTable extends _i1.UpdateTable<ShoppingItemTable> {
  ShoppingItemUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> listId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.listId,
        value,
      );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<int, int> quantity(int value) => _i1.ColumnValue(
    table.quantity,
    value,
  );

  _i1.ColumnValue<bool, bool> isChecked(bool value) => _i1.ColumnValue(
    table.isChecked,
    value,
  );

  _i1.ColumnValue<double, double> sortOrder(double value) => _i1.ColumnValue(
    table.sortOrder,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> shopId(_i1.UuidValue? value) =>
      _i1.ColumnValue(
        table.shopId,
        value,
      );

  _i1.ColumnValue<_i2.Note, _i2.Note> note(_i2.Note? value) => _i1.ColumnValue(
    table.note,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> addedBy(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.addedBy,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> checkedBy(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.checkedBy,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> checkedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.checkedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ShoppingItemTable extends _i1.Table<_i1.UuidValue?> {
  ShoppingItemTable({super.tableRelation})
    : super(tableName: 'freshcart_shopping_item') {
    updateTable = ShoppingItemUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    quantity = _i1.ColumnInt(
      'quantity',
      this,
    );
    isChecked = _i1.ColumnBool(
      'isChecked',
      this,
    );
    sortOrder = _i1.ColumnDouble(
      'sortOrder',
      this,
      hasDefault: true,
    );
    shopId = _i1.ColumnUuid(
      'shopId',
      this,
    );
    note = _i1.ColumnSerializable<_i2.Note>(
      'note',
      this,
    );
    addedBy = _i1.ColumnUuid(
      'addedBy',
      this,
    );
    checkedBy = _i1.ColumnUuid(
      'checkedBy',
      this,
    );
    checkedAt = _i1.ColumnDateTime(
      'checkedAt',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ShoppingItemUpdateTable updateTable;

  /// The list this item belongs to.
  ///
  /// Declared as an explicit foreign-key field rather than an object relation:
  /// it mirrors the domain entity, which holds a `ListId`, not a whole
  /// `ShoppingList`, and it stops a read of one item dragging a list with it.
  late final _i1.ColumnUuid listId;

  /// What to buy.
  late final _i1.ColumnString name;

  /// How many. Always at least 1; enforced by the domain's AddItem use case.
  late final _i1.ColumnInt quantity;

  late final _i1.ColumnBool isChecked;

  /// Manual ordering within a shop tab (drag-to-reorder). Fresh items append
  /// past the current end; a drag slots one item between its new neighbours
  /// by averaging their sortOrder, so a reorder only ever writes the one row
  /// that moved. See ShoppingItem.sortOrderBetween in the domain package,
  /// which is the single place that averaging is computed.
  ///
  /// defaultPersist, not defaultModel: a *database*-level default is what
  /// lets this column be added to an existing table in place. defaultModel
  /// alone left Postgres with no value to backfill existing rows with, and
  /// `serverpod create-migration` refused, warning it would have to drop and
  /// recreate the whole table instead.
  late final _i1.ColumnDouble sortOrder;

  /// Optional shop tag. `SetNull` on delete so removing a shop untags its
  /// items rather than deleting them — losing a shop must never lose the
  /// shopping.
  ///
  /// Explicitly nullable: an object relation (`shop: Shop?`) generated a
  /// NOT NULL column here, which would have made the ON DELETE SET NULL
  /// constraint fail the first time anyone removed a shop.
  late final _i1.ColumnUuid shopId;

  /// Optional annotation, stored as JSON (see Note).
  late final _i1.ColumnSerializable<_i2.Note> note;

  /// The `authUserId` of whoever added it.
  late final _i1.ColumnUuid addedBy;

  /// Who checked it off, and when. Both null while unchecked.
  late final _i1.ColumnUuid checkedBy;

  late final _i1.ColumnDateTime checkedAt;

  late final _i1.ColumnDateTime createdAt;

  /// The optimistic-concurrency token. A write carries the value the client
  /// last saw; if the stored row has moved on, the server rejects the write
  /// and the client rolls its optimistic edit back.
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    name,
    quantity,
    isChecked,
    sortOrder,
    shopId,
    note,
    addedBy,
    checkedBy,
    checkedAt,
    createdAt,
    updatedAt,
  ];
}

class ShoppingItemInclude extends _i1.IncludeObject {
  ShoppingItemInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ShoppingItem.t;
}

class ShoppingItemIncludeList extends _i1.IncludeList {
  ShoppingItemIncludeList._({
    _i1.WhereExpressionBuilder<ShoppingItemTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ShoppingItem.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ShoppingItem.t;
}

class ShoppingItemRepository {
  const ShoppingItemRepository._();

  /// Returns a list of [ShoppingItem]s matching the given query parameters.
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
  Future<List<ShoppingItem>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingItemTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingItemTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ShoppingItem>(
      where: where?.call(ShoppingItem.t),
      orderBy: orderBy?.call(ShoppingItem.t),
      orderByList: orderByList?.call(ShoppingItem.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ShoppingItem] matching the given query parameters.
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
  Future<ShoppingItem?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingItemTable>? where,
    int? offset,
    _i1.OrderByBuilder<ShoppingItemTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ShoppingItemTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ShoppingItem>(
      where: where?.call(ShoppingItem.t),
      orderBy: orderBy?.call(ShoppingItem.t),
      orderByList: orderByList?.call(ShoppingItem.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ShoppingItem] by its [id] or null if no such row exists.
  Future<ShoppingItem?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ShoppingItem>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ShoppingItem]s in the list and returns the inserted rows.
  ///
  /// The returned [ShoppingItem]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ShoppingItem>> insert(
    _i1.DatabaseSession session,
    List<ShoppingItem> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ShoppingItem>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ShoppingItem] and returns the inserted row.
  ///
  /// The returned [ShoppingItem] will have its `id` field set.
  Future<ShoppingItem> insertRow(
    _i1.DatabaseSession session,
    ShoppingItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ShoppingItem>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ShoppingItem]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ShoppingItem>> update(
    _i1.DatabaseSession session,
    List<ShoppingItem> rows, {
    _i1.ColumnSelections<ShoppingItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ShoppingItem>(
      rows,
      columns: columns?.call(ShoppingItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShoppingItem]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ShoppingItem> updateRow(
    _i1.DatabaseSession session,
    ShoppingItem row, {
    _i1.ColumnSelections<ShoppingItemTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ShoppingItem>(
      row,
      columns: columns?.call(ShoppingItem.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShoppingItem] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ShoppingItem?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ShoppingItemUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ShoppingItem>(
      id,
      columnValues: columnValues(ShoppingItem.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ShoppingItem]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ShoppingItem>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ShoppingItemUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ShoppingItemTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ShoppingItemTable>? orderBy,
    _i1.OrderByListBuilder<ShoppingItemTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ShoppingItem>(
      columnValues: columnValues(ShoppingItem.t.updateTable),
      where: where(ShoppingItem.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShoppingItem.t),
      orderByList: orderByList?.call(ShoppingItem.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ShoppingItem]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ShoppingItem>> delete(
    _i1.DatabaseSession session,
    List<ShoppingItem> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ShoppingItem>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ShoppingItem].
  Future<ShoppingItem> deleteRow(
    _i1.DatabaseSession session,
    ShoppingItem row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ShoppingItem>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ShoppingItem>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShoppingItemTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ShoppingItem>(
      where: where(ShoppingItem.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ShoppingItemTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ShoppingItem>(
      where: where?.call(ShoppingItem.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ShoppingItem] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ShoppingItemTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ShoppingItem>(
      where: where(ShoppingItem.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
