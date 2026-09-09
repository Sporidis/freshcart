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
import '../../items/models/item_change_kind.dart' as _i2;

/// One buffered item change, waiting to be summarised into a push.
///
/// Buffered rather than sent immediately so a burst — "mom added 3 items" —
/// arrives as one notification instead of three. The flush is scheduled by a
/// future call keyed on the list, so a second change inside the window joins
/// the existing batch rather than starting another.
abstract class PendingItemNotification
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  PendingItemNotification._({
    this.id,
    required this.listId,
    required this.actorId,
    required this.actorName,
    required this.itemName,
    required this.kind,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PendingItemNotification({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue actorId,
    required String actorName,
    required String itemName,
    required _i2.ItemChangeKind kind,
    DateTime? createdAt,
  }) = _PendingItemNotificationImpl;

  factory PendingItemNotification.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PendingItemNotification(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      actorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
      actorName: jsonSerialization['actorName'] as String,
      itemName: jsonSerialization['itemName'] as String,
      kind: _i2.ItemChangeKind.fromJson((jsonSerialization['kind'] as String)),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = PendingItemNotificationTable();

  static const db = PendingItemNotificationRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue listId;

  /// Who caused the change. Never notified about their own edit.
  _i1.UuidValue actorId;

  /// The actor's display name at the time, so the summary reads naturally even
  /// if they later change it.
  String actorName;

  /// The item's name, for a single-change summary.
  String itemName;

  _i2.ItemChangeKind kind;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PendingItemNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PendingItemNotification copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? actorId,
    String? actorName,
    String? itemName,
    _i2.ItemChangeKind? kind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PendingItemNotification',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'actorId': actorId.toJson(),
      'actorName': actorName,
      'itemName': itemName,
      'kind': kind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PendingItemNotification',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'actorId': actorId.toJson(),
      'actorName': actorName,
      'itemName': itemName,
      'kind': kind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static PendingItemNotificationInclude include() {
    return PendingItemNotificationInclude._();
  }

  static PendingItemNotificationIncludeList includeList({
    _i1.WhereExpressionBuilder<PendingItemNotificationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PendingItemNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PendingItemNotificationTable>? orderByList,
    PendingItemNotificationInclude? include,
  }) {
    return PendingItemNotificationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PendingItemNotification.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PendingItemNotification.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PendingItemNotificationImpl extends PendingItemNotification {
  _PendingItemNotificationImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue actorId,
    required String actorName,
    required String itemName,
    required _i2.ItemChangeKind kind,
    DateTime? createdAt,
  }) : super._(
         id: id,
         listId: listId,
         actorId: actorId,
         actorName: actorName,
         itemName: itemName,
         kind: kind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PendingItemNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PendingItemNotification copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? actorId,
    String? actorName,
    String? itemName,
    _i2.ItemChangeKind? kind,
    DateTime? createdAt,
  }) {
    return PendingItemNotification(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      itemName: itemName ?? this.itemName,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PendingItemNotificationUpdateTable
    extends _i1.UpdateTable<PendingItemNotificationTable> {
  PendingItemNotificationUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> listId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.listId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> actorId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.actorId,
        value,
      );

  _i1.ColumnValue<String, String> actorName(String value) => _i1.ColumnValue(
    table.actorName,
    value,
  );

  _i1.ColumnValue<String, String> itemName(String value) => _i1.ColumnValue(
    table.itemName,
    value,
  );

  _i1.ColumnValue<_i2.ItemChangeKind, _i2.ItemChangeKind> kind(
    _i2.ItemChangeKind value,
  ) => _i1.ColumnValue(
    table.kind,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class PendingItemNotificationTable extends _i1.Table<_i1.UuidValue?> {
  PendingItemNotificationTable({super.tableRelation})
    : super(tableName: 'freshcart_pending_item_notification') {
    updateTable = PendingItemNotificationUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    actorId = _i1.ColumnUuid(
      'actorId',
      this,
    );
    actorName = _i1.ColumnString(
      'actorName',
      this,
    );
    itemName = _i1.ColumnString(
      'itemName',
      this,
    );
    kind = _i1.ColumnEnum(
      'kind',
      this,
      _i1.EnumSerialization.byName,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PendingItemNotificationUpdateTable updateTable;

  late final _i1.ColumnUuid listId;

  /// Who caused the change. Never notified about their own edit.
  late final _i1.ColumnUuid actorId;

  /// The actor's display name at the time, so the summary reads naturally even
  /// if they later change it.
  late final _i1.ColumnString actorName;

  /// The item's name, for a single-change summary.
  late final _i1.ColumnString itemName;

  late final _i1.ColumnEnum<_i2.ItemChangeKind> kind;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    actorId,
    actorName,
    itemName,
    kind,
    createdAt,
  ];
}

class PendingItemNotificationInclude extends _i1.IncludeObject {
  PendingItemNotificationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => PendingItemNotification.t;
}

class PendingItemNotificationIncludeList extends _i1.IncludeList {
  PendingItemNotificationIncludeList._({
    _i1.WhereExpressionBuilder<PendingItemNotificationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PendingItemNotification.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => PendingItemNotification.t;
}

class PendingItemNotificationRepository {
  const PendingItemNotificationRepository._();

  /// Returns a list of [PendingItemNotification]s matching the given query parameters.
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
  Future<List<PendingItemNotification>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PendingItemNotificationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PendingItemNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PendingItemNotificationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PendingItemNotification>(
      where: where?.call(PendingItemNotification.t),
      orderBy: orderBy?.call(PendingItemNotification.t),
      orderByList: orderByList?.call(PendingItemNotification.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PendingItemNotification] matching the given query parameters.
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
  Future<PendingItemNotification?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PendingItemNotificationTable>? where,
    int? offset,
    _i1.OrderByBuilder<PendingItemNotificationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PendingItemNotificationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PendingItemNotification>(
      where: where?.call(PendingItemNotification.t),
      orderBy: orderBy?.call(PendingItemNotification.t),
      orderByList: orderByList?.call(PendingItemNotification.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PendingItemNotification] by its [id] or null if no such row exists.
  Future<PendingItemNotification?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PendingItemNotification>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PendingItemNotification]s in the list and returns the inserted rows.
  ///
  /// The returned [PendingItemNotification]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PendingItemNotification>> insert(
    _i1.DatabaseSession session,
    List<PendingItemNotification> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PendingItemNotification>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PendingItemNotification] and returns the inserted row.
  ///
  /// The returned [PendingItemNotification] will have its `id` field set.
  Future<PendingItemNotification> insertRow(
    _i1.DatabaseSession session,
    PendingItemNotification row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PendingItemNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PendingItemNotification]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PendingItemNotification>> update(
    _i1.DatabaseSession session,
    List<PendingItemNotification> rows, {
    _i1.ColumnSelections<PendingItemNotificationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PendingItemNotification>(
      rows,
      columns: columns?.call(PendingItemNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PendingItemNotification]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PendingItemNotification> updateRow(
    _i1.DatabaseSession session,
    PendingItemNotification row, {
    _i1.ColumnSelections<PendingItemNotificationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PendingItemNotification>(
      row,
      columns: columns?.call(PendingItemNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PendingItemNotification] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PendingItemNotification?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<PendingItemNotificationUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PendingItemNotification>(
      id,
      columnValues: columnValues(PendingItemNotification.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PendingItemNotification]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PendingItemNotification>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PendingItemNotificationUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<PendingItemNotificationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PendingItemNotificationTable>? orderBy,
    _i1.OrderByListBuilder<PendingItemNotificationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PendingItemNotification>(
      columnValues: columnValues(PendingItemNotification.t.updateTable),
      where: where(PendingItemNotification.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PendingItemNotification.t),
      orderByList: orderByList?.call(PendingItemNotification.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PendingItemNotification]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PendingItemNotification>> delete(
    _i1.DatabaseSession session,
    List<PendingItemNotification> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PendingItemNotification>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PendingItemNotification].
  Future<PendingItemNotification> deleteRow(
    _i1.DatabaseSession session,
    PendingItemNotification row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PendingItemNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PendingItemNotification>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PendingItemNotificationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PendingItemNotification>(
      where: where(PendingItemNotification.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PendingItemNotificationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PendingItemNotification>(
      where: where?.call(PendingItemNotification.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PendingItemNotification] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PendingItemNotificationTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PendingItemNotification>(
      where: where(PendingItemNotification.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
