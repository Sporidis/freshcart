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

/// A user's choice to silence one list.
///
/// Presence of a row means muted; there is no boolean. Absence is the default
/// and costs no storage for the overwhelmingly common case.
abstract class ListMute
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ListMute._({
    this.id,
    required this.listId,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ListMute({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    DateTime? createdAt,
  }) = _ListMuteImpl;

  factory ListMute.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListMute(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ListMuteTable();

  static const db = ListMuteRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue listId;

  _i1.UuidValue userId;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ListMute]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListMute copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListMute',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListMute',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static ListMuteInclude include() {
    return ListMuteInclude._();
  }

  static ListMuteIncludeList includeList({
    _i1.WhereExpressionBuilder<ListMuteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMuteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMuteTable>? orderByList,
    ListMuteInclude? include,
  }) {
    return ListMuteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ListMute.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ListMute.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListMuteImpl extends ListMute {
  _ListMuteImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         listId: listId,
         userId: userId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ListMute]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListMute copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    DateTime? createdAt,
  }) {
    return ListMute(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ListMuteUpdateTable extends _i1.UpdateTable<ListMuteTable> {
  ListMuteUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> listId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.listId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class ListMuteTable extends _i1.Table<_i1.UuidValue?> {
  ListMuteTable({super.tableRelation})
    : super(tableName: 'freshcart_list_mute') {
    updateTable = ListMuteUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ListMuteUpdateTable updateTable;

  late final _i1.ColumnUuid listId;

  late final _i1.ColumnUuid userId;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    userId,
    createdAt,
  ];
}

class ListMuteInclude extends _i1.IncludeObject {
  ListMuteInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ListMute.t;
}

class ListMuteIncludeList extends _i1.IncludeList {
  ListMuteIncludeList._({
    _i1.WhereExpressionBuilder<ListMuteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ListMute.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ListMute.t;
}

class ListMuteRepository {
  const ListMuteRepository._();

  /// Returns a list of [ListMute]s matching the given query parameters.
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
  Future<List<ListMute>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMuteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMuteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMuteTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ListMute>(
      where: where?.call(ListMute.t),
      orderBy: orderBy?.call(ListMute.t),
      orderByList: orderByList?.call(ListMute.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ListMute] matching the given query parameters.
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
  Future<ListMute?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMuteTable>? where,
    int? offset,
    _i1.OrderByBuilder<ListMuteTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMuteTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ListMute>(
      where: where?.call(ListMute.t),
      orderBy: orderBy?.call(ListMute.t),
      orderByList: orderByList?.call(ListMute.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ListMute] by its [id] or null if no such row exists.
  Future<ListMute?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ListMute>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ListMute]s in the list and returns the inserted rows.
  ///
  /// The returned [ListMute]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ListMute>> insert(
    _i1.DatabaseSession session,
    List<ListMute> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ListMute>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ListMute] and returns the inserted row.
  ///
  /// The returned [ListMute] will have its `id` field set.
  Future<ListMute> insertRow(
    _i1.DatabaseSession session,
    ListMute row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ListMute>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ListMute]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ListMute>> update(
    _i1.DatabaseSession session,
    List<ListMute> rows, {
    _i1.ColumnSelections<ListMuteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ListMute>(
      rows,
      columns: columns?.call(ListMute.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ListMute]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ListMute> updateRow(
    _i1.DatabaseSession session,
    ListMute row, {
    _i1.ColumnSelections<ListMuteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ListMute>(
      row,
      columns: columns?.call(ListMute.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ListMute] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ListMute?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ListMuteUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ListMute>(
      id,
      columnValues: columnValues(ListMute.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ListMute]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ListMute>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ListMuteUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ListMuteTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMuteTable>? orderBy,
    _i1.OrderByListBuilder<ListMuteTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ListMute>(
      columnValues: columnValues(ListMute.t.updateTable),
      where: where(ListMute.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ListMute.t),
      orderByList: orderByList?.call(ListMute.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ListMute]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ListMute>> delete(
    _i1.DatabaseSession session,
    List<ListMute> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ListMute>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ListMute].
  Future<ListMute> deleteRow(
    _i1.DatabaseSession session,
    ListMute row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ListMute>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ListMute>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ListMuteTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ListMute>(
      where: where(ListMute.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMuteTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ListMute>(
      where: where?.call(ListMute.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ListMute] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ListMuteTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ListMute>(
      where: where(ListMute.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
