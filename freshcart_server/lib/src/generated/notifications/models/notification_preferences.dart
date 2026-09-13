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

/// A user's own choices about which push notifications they receive
/// (decisions #80, phase 2). Global, not per-list -- ListMute is "not from
/// this list, regardless of kind," this is "which kinds of thing do I want
/// to hear about at all, from any list."
///
/// No row exists until a user changes something from its default --
/// NotificationPreferencesService.forUser returns an in-memory default
/// rather than inserting one on first read, so the table doesn't grow one
/// row per signed-up user who never opens this screen.
abstract class NotificationPreferences
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  NotificationPreferences._({
    this.id,
    required this.userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) : itemAdded = itemAdded ?? true,
       memberJoined = memberJoined ?? false,
       listFinished = listFinished ?? false;

  factory NotificationPreferences({
    _i1.UuidValue? id,
    required _i1.UuidValue userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) = _NotificationPreferencesImpl;

  factory NotificationPreferences.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationPreferences(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      itemAdded: jsonSerialization['itemAdded'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['itemAdded']),
      memberJoined: jsonSerialization['memberJoined'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['memberJoined']),
      listFinished: jsonSerialization['listFinished'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['listFinished']),
    );
  }

  static final t = NotificationPreferencesTable();

  static const db = NotificationPreferencesRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue userId;

  /// "Someone adds an item" -- on by default; the design's own words:
  /// "Off by default except the first -- nobody installs a list app for
  /// alerts."
  bool itemAdded;

  /// "Someone joins a list."
  bool memberJoined;

  /// "A list is finished" -- when the last item is checked off.
  bool listFinished;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationPreferences copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationPreferences',
      if (id != null) 'id': id?.toJson(),
      'userId': userId.toJson(),
      'itemAdded': itemAdded,
      'memberJoined': memberJoined,
      'listFinished': listFinished,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NotificationPreferences',
      if (id != null) 'id': id?.toJson(),
      'userId': userId.toJson(),
      'itemAdded': itemAdded,
      'memberJoined': memberJoined,
      'listFinished': listFinished,
    };
  }

  static NotificationPreferencesInclude include() {
    return NotificationPreferencesInclude._();
  }

  static NotificationPreferencesIncludeList includeList({
    _i1.WhereExpressionBuilder<NotificationPreferencesTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationPreferencesTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationPreferencesTable>? orderByList,
    NotificationPreferencesInclude? include,
  }) {
    return NotificationPreferencesIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationPreferences.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(NotificationPreferences.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationPreferencesImpl extends NotificationPreferences {
  _NotificationPreferencesImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) : super._(
         id: id,
         userId: userId,
         itemAdded: itemAdded,
         memberJoined: memberJoined,
         listFinished: listFinished,
       );

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationPreferences copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    bool? itemAdded,
    bool? memberJoined,
    bool? listFinished,
  }) {
    return NotificationPreferences(
      id: id is _i1.UuidValue? ? id : this.id,
      userId: userId ?? this.userId,
      itemAdded: itemAdded ?? this.itemAdded,
      memberJoined: memberJoined ?? this.memberJoined,
      listFinished: listFinished ?? this.listFinished,
    );
  }
}

class NotificationPreferencesUpdateTable
    extends _i1.UpdateTable<NotificationPreferencesTable> {
  NotificationPreferencesUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.userId,
        value,
      );

  _i1.ColumnValue<bool, bool> itemAdded(bool value) => _i1.ColumnValue(
    table.itemAdded,
    value,
  );

  _i1.ColumnValue<bool, bool> memberJoined(bool value) => _i1.ColumnValue(
    table.memberJoined,
    value,
  );

  _i1.ColumnValue<bool, bool> listFinished(bool value) => _i1.ColumnValue(
    table.listFinished,
    value,
  );
}

class NotificationPreferencesTable extends _i1.Table<_i1.UuidValue?> {
  NotificationPreferencesTable({super.tableRelation})
    : super(tableName: 'freshcart_notification_preferences') {
    updateTable = NotificationPreferencesUpdateTable(this);
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    itemAdded = _i1.ColumnBool(
      'itemAdded',
      this,
      hasDefault: true,
    );
    memberJoined = _i1.ColumnBool(
      'memberJoined',
      this,
      hasDefault: true,
    );
    listFinished = _i1.ColumnBool(
      'listFinished',
      this,
      hasDefault: true,
    );
  }

  late final NotificationPreferencesUpdateTable updateTable;

  late final _i1.ColumnUuid userId;

  /// "Someone adds an item" -- on by default; the design's own words:
  /// "Off by default except the first -- nobody installs a list app for
  /// alerts."
  late final _i1.ColumnBool itemAdded;

  /// "Someone joins a list."
  late final _i1.ColumnBool memberJoined;

  /// "A list is finished" -- when the last item is checked off.
  late final _i1.ColumnBool listFinished;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    itemAdded,
    memberJoined,
    listFinished,
  ];
}

class NotificationPreferencesInclude extends _i1.IncludeObject {
  NotificationPreferencesInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => NotificationPreferences.t;
}

class NotificationPreferencesIncludeList extends _i1.IncludeList {
  NotificationPreferencesIncludeList._({
    _i1.WhereExpressionBuilder<NotificationPreferencesTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(NotificationPreferences.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => NotificationPreferences.t;
}

class NotificationPreferencesRepository {
  const NotificationPreferencesRepository._();

  /// Returns a list of [NotificationPreferences]s matching the given query parameters.
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
  Future<List<NotificationPreferences>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<NotificationPreferencesTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationPreferencesTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationPreferencesTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<NotificationPreferences>(
      where: where?.call(NotificationPreferences.t),
      orderBy: orderBy?.call(NotificationPreferences.t),
      orderByList: orderByList?.call(NotificationPreferences.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [NotificationPreferences] matching the given query parameters.
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
  Future<NotificationPreferences?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<NotificationPreferencesTable>? where,
    int? offset,
    _i1.OrderByBuilder<NotificationPreferencesTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationPreferencesTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<NotificationPreferences>(
      where: where?.call(NotificationPreferences.t),
      orderBy: orderBy?.call(NotificationPreferences.t),
      orderByList: orderByList?.call(NotificationPreferences.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [NotificationPreferences] by its [id] or null if no such row exists.
  Future<NotificationPreferences?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<NotificationPreferences>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [NotificationPreferences]s in the list and returns the inserted rows.
  ///
  /// The returned [NotificationPreferences]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<NotificationPreferences>> insert(
    _i1.DatabaseSession session,
    List<NotificationPreferences> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<NotificationPreferences>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [NotificationPreferences] and returns the inserted row.
  ///
  /// The returned [NotificationPreferences] will have its `id` field set.
  Future<NotificationPreferences> insertRow(
    _i1.DatabaseSession session,
    NotificationPreferences row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<NotificationPreferences>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [NotificationPreferences]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<NotificationPreferences>> update(
    _i1.DatabaseSession session,
    List<NotificationPreferences> rows, {
    _i1.ColumnSelections<NotificationPreferencesTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<NotificationPreferences>(
      rows,
      columns: columns?.call(NotificationPreferences.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationPreferences]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<NotificationPreferences> updateRow(
    _i1.DatabaseSession session,
    NotificationPreferences row, {
    _i1.ColumnSelections<NotificationPreferencesTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<NotificationPreferences>(
      row,
      columns: columns?.call(NotificationPreferences.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationPreferences] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<NotificationPreferences?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<NotificationPreferencesUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<NotificationPreferences>(
      id,
      columnValues: columnValues(NotificationPreferences.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [NotificationPreferences]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<NotificationPreferences>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<NotificationPreferencesUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<NotificationPreferencesTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationPreferencesTable>? orderBy,
    _i1.OrderByListBuilder<NotificationPreferencesTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<NotificationPreferences>(
      columnValues: columnValues(NotificationPreferences.t.updateTable),
      where: where(NotificationPreferences.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationPreferences.t),
      orderByList: orderByList?.call(NotificationPreferences.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [NotificationPreferences]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<NotificationPreferences>> delete(
    _i1.DatabaseSession session,
    List<NotificationPreferences> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<NotificationPreferences>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [NotificationPreferences].
  Future<NotificationPreferences> deleteRow(
    _i1.DatabaseSession session,
    NotificationPreferences row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<NotificationPreferences>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<NotificationPreferences>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<NotificationPreferencesTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<NotificationPreferences>(
      where: where(NotificationPreferences.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<NotificationPreferencesTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<NotificationPreferences>(
      where: where?.call(NotificationPreferences.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [NotificationPreferences] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<NotificationPreferencesTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<NotificationPreferences>(
      where: where(NotificationPreferences.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
