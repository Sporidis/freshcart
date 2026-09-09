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
import '../../notifications/models/device_platform.dart' as _i2;

/// An FCM registration token for one device belonging to one user.
abstract class DeviceToken
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  DeviceToken._({
    this.id,
    required this.ownerId,
    required this.token,
    required this.platform,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DeviceToken({
    _i1.UuidValue? id,
    required _i1.UuidValue ownerId,
    required String token,
    required _i2.DevicePlatform platform,
    DateTime? createdAt,
  }) = _DeviceTokenImpl;

  factory DeviceToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceToken(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      ownerId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      token: jsonSerialization['token'] as String,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DeviceTokenTable();

  static const db = DeviceTokenRepository._();

  @override
  _i1.UuidValue? id;

  /// The owning user's `authUserId`.
  _i1.UuidValue ownerId;

  /// The FCM registration token.
  String token;

  _i2.DevicePlatform platform;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceToken copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? ownerId,
    String? token,
    _i2.DevicePlatform? platform,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'ownerId': ownerId.toJson(),
      'token': token,
      'platform': platform.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'ownerId': ownerId.toJson(),
      'token': token,
      'platform': platform.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static DeviceTokenInclude include() {
    return DeviceTokenInclude._();
  }

  static DeviceTokenIncludeList includeList({
    _i1.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTokenTable>? orderByList,
    DeviceTokenInclude? include,
  }) {
    return DeviceTokenIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceToken.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DeviceToken.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceTokenImpl extends DeviceToken {
  _DeviceTokenImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue ownerId,
    required String token,
    required _i2.DevicePlatform platform,
    DateTime? createdAt,
  }) : super._(
         id: id,
         ownerId: ownerId,
         token: token,
         platform: platform,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceToken copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? ownerId,
    String? token,
    _i2.DevicePlatform? platform,
    DateTime? createdAt,
  }) {
    return DeviceToken(
      id: id is _i1.UuidValue? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DeviceTokenUpdateTable extends _i1.UpdateTable<DeviceTokenTable> {
  DeviceTokenUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> ownerId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.ownerId,
        value,
      );

  _i1.ColumnValue<String, String> token(String value) => _i1.ColumnValue(
    table.token,
    value,
  );

  _i1.ColumnValue<_i2.DevicePlatform, _i2.DevicePlatform> platform(
    _i2.DevicePlatform value,
  ) => _i1.ColumnValue(
    table.platform,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class DeviceTokenTable extends _i1.Table<_i1.UuidValue?> {
  DeviceTokenTable({super.tableRelation})
    : super(tableName: 'freshcart_device_token') {
    updateTable = DeviceTokenUpdateTable(this);
    ownerId = _i1.ColumnUuid(
      'ownerId',
      this,
    );
    token = _i1.ColumnString(
      'token',
      this,
    );
    platform = _i1.ColumnEnum(
      'platform',
      this,
      _i1.EnumSerialization.byName,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DeviceTokenUpdateTable updateTable;

  /// The owning user's `authUserId`.
  late final _i1.ColumnUuid ownerId;

  /// The FCM registration token.
  late final _i1.ColumnString token;

  late final _i1.ColumnEnum<_i2.DevicePlatform> platform;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    ownerId,
    token,
    platform,
    createdAt,
  ];
}

class DeviceTokenInclude extends _i1.IncludeObject {
  DeviceTokenInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => DeviceToken.t;
}

class DeviceTokenIncludeList extends _i1.IncludeList {
  DeviceTokenIncludeList._({
    _i1.WhereExpressionBuilder<DeviceTokenTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DeviceToken.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => DeviceToken.t;
}

class DeviceTokenRepository {
  const DeviceTokenRepository._();

  /// Returns a list of [DeviceToken]s matching the given query parameters.
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
  Future<List<DeviceToken>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DeviceToken>(
      where: where?.call(DeviceToken.t),
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DeviceToken] matching the given query parameters.
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
  Future<DeviceToken?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? offset,
    _i1.OrderByBuilder<DeviceTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DeviceToken>(
      where: where?.call(DeviceToken.t),
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DeviceToken] by its [id] or null if no such row exists.
  Future<DeviceToken?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DeviceToken>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DeviceToken]s in the list and returns the inserted rows.
  ///
  /// The returned [DeviceToken]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DeviceToken>> insert(
    _i1.DatabaseSession session,
    List<DeviceToken> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DeviceToken>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DeviceToken] and returns the inserted row.
  ///
  /// The returned [DeviceToken] will have its `id` field set.
  Future<DeviceToken> insertRow(
    _i1.DatabaseSession session,
    DeviceToken row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DeviceToken>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DeviceToken]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DeviceToken>> update(
    _i1.DatabaseSession session,
    List<DeviceToken> rows, {
    _i1.ColumnSelections<DeviceTokenTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DeviceToken>(
      rows,
      columns: columns?.call(DeviceToken.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeviceToken]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DeviceToken> updateRow(
    _i1.DatabaseSession session,
    DeviceToken row, {
    _i1.ColumnSelections<DeviceTokenTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DeviceToken>(
      row,
      columns: columns?.call(DeviceToken.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeviceToken] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DeviceToken?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<DeviceTokenUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DeviceToken>(
      id,
      columnValues: columnValues(DeviceToken.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceToken]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DeviceToken>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DeviceTokenUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<DeviceTokenTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTokenTable>? orderBy,
    _i1.OrderByListBuilder<DeviceTokenTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DeviceToken>(
      columnValues: columnValues(DeviceToken.t.updateTable),
      where: where(DeviceToken.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DeviceToken]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DeviceToken>> delete(
    _i1.DatabaseSession session,
    List<DeviceToken> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DeviceToken>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DeviceToken].
  Future<DeviceToken> deleteRow(
    _i1.DatabaseSession session,
    DeviceToken row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DeviceToken>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DeviceToken>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DeviceTokenTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DeviceToken>(
      where: where(DeviceToken.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DeviceToken>(
      where: where?.call(DeviceToken.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DeviceToken] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DeviceTokenTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DeviceToken>(
      where: where(DeviceToken.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
