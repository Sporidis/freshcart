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
import '../../lists/models/member_role.dart' as _i2;

/// One person's membership of a shopping list.
abstract class ListMember
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ListMember._({
    this.id,
    required this.listId,
    required this.userId,
    this.displayName,
    this.avatarColorArgb,
    this.avatarPhotoUrl,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory ListMember({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required _i2.MemberRole role,
    DateTime? joinedAt,
  }) = _ListMemberImpl;

  factory ListMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListMember(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      displayName: jsonSerialization['displayName'] as String?,
      avatarColorArgb: jsonSerialization['avatarColorArgb'] as int?,
      avatarPhotoUrl: jsonSerialization['avatarPhotoUrl'] as String?,
      role: _i2.MemberRole.fromJson((jsonSerialization['role'] as String)),
      joinedAt: jsonSerialization['joinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['joinedAt']),
    );
  }

  static final t = ListMemberTable();

  static const db = ListMemberRepository._();

  @override
  _i1.UuidValue? id;

  /// The list this membership belongs to.
  _i1.UuidValue listId;

  /// The member's `authUserId`.
  _i1.UuidValue userId;

  /// Filled in live from the member's `MemberProfile` every time a list is
  /// read (`ListService._withMembers`), never stored on this row: a copy
  /// taken at join time went stale the moment someone renamed themselves or
  /// changed their photo (docs/decisions.md #98). Always set by the server
  /// on the way out; nullable only because a row read straight from the
  /// table does not have it yet.
  String? displayName;

  /// The member's chosen avatar colour, live -- see [displayName].
  int? avatarColorArgb;

  /// The member's avatar photo as a public URL, live -- see [displayName].
  String? avatarPhotoUrl;

  _i2.MemberRole role;

  DateTime joinedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ListMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListMember copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    _i2.MemberRole? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListMember',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      if (displayName != null) 'displayName': displayName,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoUrl != null) 'avatarPhotoUrl': avatarPhotoUrl,
      'role': role.toJson(),
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListMember',
      if (id != null) 'id': id?.toJson(),
      'listId': listId.toJson(),
      'userId': userId.toJson(),
      if (displayName != null) 'displayName': displayName,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoUrl != null) 'avatarPhotoUrl': avatarPhotoUrl,
      'role': role.toJson(),
      'joinedAt': joinedAt.toJson(),
    };
  }

  static ListMemberInclude include() {
    return ListMemberInclude._();
  }

  static ListMemberIncludeList includeList({
    _i1.WhereExpressionBuilder<ListMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMemberTable>? orderByList,
    ListMemberInclude? include,
  }) {
    return ListMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ListMember.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ListMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListMemberImpl extends ListMember {
  _ListMemberImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue listId,
    required _i1.UuidValue userId,
    String? displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required _i2.MemberRole role,
    DateTime? joinedAt,
  }) : super._(
         id: id,
         listId: listId,
         userId: userId,
         displayName: displayName,
         avatarColorArgb: avatarColorArgb,
         avatarPhotoUrl: avatarPhotoUrl,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [ListMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListMember copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? listId,
    _i1.UuidValue? userId,
    Object? displayName = _Undefined,
    Object? avatarColorArgb = _Undefined,
    Object? avatarPhotoUrl = _Undefined,
    _i2.MemberRole? role,
    DateTime? joinedAt,
  }) {
    return ListMember(
      id: id is _i1.UuidValue? ? id : this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarColorArgb: avatarColorArgb is int?
          ? avatarColorArgb
          : this.avatarColorArgb,
      avatarPhotoUrl: avatarPhotoUrl is String?
          ? avatarPhotoUrl
          : this.avatarPhotoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class ListMemberUpdateTable extends _i1.UpdateTable<ListMemberTable> {
  ListMemberUpdateTable(super.table);

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

  _i1.ColumnValue<_i2.MemberRole, _i2.MemberRole> role(_i2.MemberRole value) =>
      _i1.ColumnValue(
        table.role,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );
}

class ListMemberTable extends _i1.Table<_i1.UuidValue?> {
  ListMemberTable({super.tableRelation})
    : super(tableName: 'freshcart_list_member') {
    updateTable = ListMemberUpdateTable(this);
    listId = _i1.ColumnUuid(
      'listId',
      this,
    );
    userId = _i1.ColumnUuid(
      'userId',
      this,
    );
    role = _i1.ColumnEnum(
      'role',
      this,
      _i1.EnumSerialization.byName,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
  }

  late final ListMemberUpdateTable updateTable;

  /// The list this membership belongs to.
  late final _i1.ColumnUuid listId;

  /// The member's `authUserId`.
  late final _i1.ColumnUuid userId;

  late final _i1.ColumnEnum<_i2.MemberRole> role;

  late final _i1.ColumnDateTime joinedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    listId,
    userId,
    role,
    joinedAt,
  ];
}

class ListMemberInclude extends _i1.IncludeObject {
  ListMemberInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ListMember.t;
}

class ListMemberIncludeList extends _i1.IncludeList {
  ListMemberIncludeList._({
    _i1.WhereExpressionBuilder<ListMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ListMember.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ListMember.t;
}

class ListMemberRepository {
  const ListMemberRepository._();

  /// Returns a list of [ListMember]s matching the given query parameters.
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
  Future<List<ListMember>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ListMember>(
      where: where?.call(ListMember.t),
      orderBy: orderBy?.call(ListMember.t),
      orderByList: orderByList?.call(ListMember.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ListMember] matching the given query parameters.
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
  Future<ListMember?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMemberTable>? where,
    int? offset,
    _i1.OrderByBuilder<ListMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ListMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ListMember>(
      where: where?.call(ListMember.t),
      orderBy: orderBy?.call(ListMember.t),
      orderByList: orderByList?.call(ListMember.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ListMember] by its [id] or null if no such row exists.
  Future<ListMember?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ListMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ListMember]s in the list and returns the inserted rows.
  ///
  /// The returned [ListMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ListMember>> insert(
    _i1.DatabaseSession session,
    List<ListMember> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ListMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ListMember] and returns the inserted row.
  ///
  /// The returned [ListMember] will have its `id` field set.
  Future<ListMember> insertRow(
    _i1.DatabaseSession session,
    ListMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ListMember>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ListMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ListMember>> update(
    _i1.DatabaseSession session,
    List<ListMember> rows, {
    _i1.ColumnSelections<ListMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ListMember>(
      rows,
      columns: columns?.call(ListMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ListMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ListMember> updateRow(
    _i1.DatabaseSession session,
    ListMember row, {
    _i1.ColumnSelections<ListMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ListMember>(
      row,
      columns: columns?.call(ListMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ListMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ListMember?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ListMemberUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ListMember>(
      id,
      columnValues: columnValues(ListMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ListMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ListMember>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ListMemberUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ListMemberTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ListMemberTable>? orderBy,
    _i1.OrderByListBuilder<ListMemberTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ListMember>(
      columnValues: columnValues(ListMember.t.updateTable),
      where: where(ListMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ListMember.t),
      orderByList: orderByList?.call(ListMember.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ListMember]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ListMember>> delete(
    _i1.DatabaseSession session,
    List<ListMember> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ListMember>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ListMember].
  Future<ListMember> deleteRow(
    _i1.DatabaseSession session,
    ListMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ListMember>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ListMember>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ListMemberTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ListMember>(
      where: where(ListMember.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ListMemberTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ListMember>(
      where: where?.call(ListMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ListMember] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ListMemberTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ListMember>(
      where: where(ListMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
