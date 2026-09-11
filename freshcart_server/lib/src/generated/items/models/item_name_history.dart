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

/// A product name typed on a list before, so the add control's suggestion
/// chips (and, eventually, search's own "Recently bought") can offer it
/// again. Kept as its own record rather than derived from ShoppingItem:
/// every delete path (ItemService.remove, clearChecked, removeMany) is a
/// hard delete, so a name would disappear from history the moment the item
/// did -- exactly when a suggestion for it (re-adding something just
/// cleared off a finished list) would be most useful.
abstract class ItemNameHistory
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
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

  static final t = ItemNameHistoryTable();

  static const db = ItemNameHistoryRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ItemNameHistory',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'name': name,
      'lastUsedAt': lastUsedAt.toJson(),
    };
  }

  static ItemNameHistoryInclude include() {
    return ItemNameHistoryInclude._();
  }

  static ItemNameHistoryIncludeList includeList({
    _i1.WhereExpressionBuilder<ItemNameHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ItemNameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemNameHistoryTable>? orderByList,
    ItemNameHistoryInclude? include,
  }) {
    return ItemNameHistoryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ItemNameHistory.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ItemNameHistory.t),
      include: include,
    );
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

class ItemNameHistoryUpdateTable extends _i1.UpdateTable<ItemNameHistoryTable> {
  ItemNameHistoryUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> listId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.listId,
        value,
      );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastUsedAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastUsedAt,
        value,
      );
}

class ItemNameHistoryTable extends _i1.Table<_i1.UuidValue?> {
  ItemNameHistoryTable({super.tableRelation})
    : super(tableName: 'freshcart_item_name_history') {
    updateTable = ItemNameHistoryUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    lastUsedAt = _i1.ColumnDateTime(
      'lastUsedAt',
      this,
    );
  }

  late final ItemNameHistoryUpdateTable updateTable;

  /// The list this history belongs to. Suggestions are per-list, not
  /// household-wide -- the same scope shops already use (decisions #19).
  late final _i1.ColumnUuid listId;

  /// Exactly as typed. Matched case-insensitively at query time (ILIKE), but
  /// the unique index below is on the exact string, so "Milk" and "milk"
  /// persist as two separate rows -- a deliberate simplification, not an
  /// oversight (see decisions.md).
  late final _i1.ColumnString name;

  /// Bumped every time [name] is added again, so suggestions surface the
  /// most recently used first, not just whichever was typed first.
  late final _i1.ColumnDateTime lastUsedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    name,
    lastUsedAt,
  ];
}

class ItemNameHistoryInclude extends _i1.IncludeObject {
  ItemNameHistoryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ItemNameHistory.t;
}

class ItemNameHistoryIncludeList extends _i1.IncludeList {
  ItemNameHistoryIncludeList._({
    _i1.WhereExpressionBuilder<ItemNameHistoryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ItemNameHistory.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ItemNameHistory.t;
}

class ItemNameHistoryRepository {
  const ItemNameHistoryRepository._();

  /// Returns a list of [ItemNameHistory]s matching the given query parameters.
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
  Future<List<ItemNameHistory>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ItemNameHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ItemNameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemNameHistoryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ItemNameHistory>(
      where: where?.call(ItemNameHistory.t),
      orderBy: orderBy?.call(ItemNameHistory.t),
      orderByList: orderByList?.call(ItemNameHistory.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ItemNameHistory] matching the given query parameters.
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
  Future<ItemNameHistory?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ItemNameHistoryTable>? where,
    int? offset,
    _i1.OrderByBuilder<ItemNameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ItemNameHistoryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ItemNameHistory>(
      where: where?.call(ItemNameHistory.t),
      orderBy: orderBy?.call(ItemNameHistory.t),
      orderByList: orderByList?.call(ItemNameHistory.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ItemNameHistory] by its [id] or null if no such row exists.
  Future<ItemNameHistory?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ItemNameHistory>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ItemNameHistory]s in the list and returns the inserted rows.
  ///
  /// The returned [ItemNameHistory]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ItemNameHistory>> insert(
    _i1.DatabaseSession session,
    List<ItemNameHistory> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ItemNameHistory>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ItemNameHistory] and returns the inserted row.
  ///
  /// The returned [ItemNameHistory] will have its `id` field set.
  Future<ItemNameHistory> insertRow(
    _i1.DatabaseSession session,
    ItemNameHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ItemNameHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ItemNameHistory]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ItemNameHistory>> update(
    _i1.DatabaseSession session,
    List<ItemNameHistory> rows, {
    _i1.ColumnSelections<ItemNameHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ItemNameHistory>(
      rows,
      columns: columns?.call(ItemNameHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ItemNameHistory]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ItemNameHistory> updateRow(
    _i1.DatabaseSession session,
    ItemNameHistory row, {
    _i1.ColumnSelections<ItemNameHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ItemNameHistory>(
      row,
      columns: columns?.call(ItemNameHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ItemNameHistory] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ItemNameHistory?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ItemNameHistoryUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ItemNameHistory>(
      id,
      columnValues: columnValues(ItemNameHistory.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ItemNameHistory]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ItemNameHistory>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ItemNameHistoryUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ItemNameHistoryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ItemNameHistoryTable>? orderBy,
    _i1.OrderByListBuilder<ItemNameHistoryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ItemNameHistory>(
      columnValues: columnValues(ItemNameHistory.t.updateTable),
      where: where(ItemNameHistory.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ItemNameHistory.t),
      orderByList: orderByList?.call(ItemNameHistory.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ItemNameHistory]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ItemNameHistory>> delete(
    _i1.DatabaseSession session,
    List<ItemNameHistory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ItemNameHistory>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ItemNameHistory].
  Future<ItemNameHistory> deleteRow(
    _i1.DatabaseSession session,
    ItemNameHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ItemNameHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ItemNameHistory>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ItemNameHistoryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ItemNameHistory>(
      where: where(ItemNameHistory.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ItemNameHistoryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ItemNameHistory>(
      where: where?.call(ItemNameHistory.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ItemNameHistory] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ItemNameHistoryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ItemNameHistory>(
      where: where(ItemNameHistory.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
