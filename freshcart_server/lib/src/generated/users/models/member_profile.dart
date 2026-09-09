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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i2;
import 'package:freshcart_server/src/generated/protocol.dart' as _i3;

/// A FreshCart user's public profile, hanging off a Serverpod auth identity.
///
/// Named `MemberProfile`, not `UserProfile`, because serverpod_auth_core ships
/// a `UserProfile` of its own and both would land in the generated client.
/// Ours stays deliberately tiny — one display name — because the auth module's
/// profile feature carries images and email we do not need.
///
/// Kept separate from the auth module's `AuthUser` so that display name and any
/// future profile data are ours to evolve, while identity stays the auth
/// module's concern. The relation is what makes the anonymous-to-linked upgrade
/// free: the `authUserId` never changes, so this row follows the account.
abstract class MemberProfile
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  MemberProfile._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.displayName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MemberProfile({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String displayName,
    DateTime? createdAt,
  }) = _MemberProfileImpl;

  factory MemberProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return MemberProfile(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      displayName: jsonSerialization['displayName'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = MemberProfileTable();

  static const db = MemberProfileRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue authUserId;

  /// The auth identity this profile belongs to.
  _i2.AuthUser? authUser;

  /// The name collaborators see next to this user's changes.
  String displayName;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [MemberProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MemberProfile copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    String? displayName,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MemberProfile',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'displayName': displayName,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MemberProfile',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJsonForProtocol(),
      'displayName': displayName,
      'createdAt': createdAt.toJson(),
    };
  }

  static MemberProfileInclude include({_i2.AuthUserInclude? authUser}) {
    return MemberProfileInclude._(authUser: authUser);
  }

  static MemberProfileIncludeList includeList({
    _i1.WhereExpressionBuilder<MemberProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MemberProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MemberProfileTable>? orderByList,
    MemberProfileInclude? include,
  }) {
    return MemberProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MemberProfile.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MemberProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MemberProfileImpl extends MemberProfile {
  _MemberProfileImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String displayName,
    DateTime? createdAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         displayName: displayName,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MemberProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MemberProfile copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? displayName,
    DateTime? createdAt,
  }) {
    return MemberProfile(
      id: id is _i1.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MemberProfileUpdateTable extends _i1.UpdateTable<MemberProfileTable> {
  MemberProfileUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class MemberProfileTable extends _i1.Table<_i1.UuidValue?> {
  MemberProfileTable({super.tableRelation})
    : super(tableName: 'freshcart_member_profile') {
    updateTable = MemberProfileUpdateTable(this);
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final MemberProfileUpdateTable updateTable;

  late final _i1.ColumnUuid authUserId;

  /// The auth identity this profile belongs to.
  _i2.AuthUserTable? _authUser;

  /// The name collaborators see next to this user's changes.
  late final _i1.ColumnString displayName;

  late final _i1.ColumnDateTime createdAt;

  _i2.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _i1.createRelationTable(
      relationFieldName: 'authUser',
      field: MemberProfile.t.authUserId,
      foreignField: _i2.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _authUser!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    authUserId,
    displayName,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class MemberProfileInclude extends _i1.IncludeObject {
  MemberProfileInclude._({_i2.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _i2.AuthUserInclude? _authUser;

  @override
  Map<String, _i1.Include?> get includes => {'authUser': _authUser};

  @override
  _i1.Table<_i1.UuidValue?> get table => MemberProfile.t;
}

class MemberProfileIncludeList extends _i1.IncludeList {
  MemberProfileIncludeList._({
    _i1.WhereExpressionBuilder<MemberProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MemberProfile.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => MemberProfile.t;
}

class MemberProfileRepository {
  const MemberProfileRepository._();

  final attachRow = const MemberProfileAttachRowRepository._();

  /// Returns a list of [MemberProfile]s matching the given query parameters.
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
  Future<List<MemberProfile>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MemberProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MemberProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MemberProfileTable>? orderByList,
    _i1.Transaction? transaction,
    MemberProfileInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MemberProfile>(
      where: where?.call(MemberProfile.t),
      orderBy: orderBy?.call(MemberProfile.t),
      orderByList: orderByList?.call(MemberProfile.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MemberProfile] matching the given query parameters.
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
  Future<MemberProfile?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MemberProfileTable>? where,
    int? offset,
    _i1.OrderByBuilder<MemberProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MemberProfileTable>? orderByList,
    _i1.Transaction? transaction,
    MemberProfileInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MemberProfile>(
      where: where?.call(MemberProfile.t),
      orderBy: orderBy?.call(MemberProfile.t),
      orderByList: orderByList?.call(MemberProfile.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MemberProfile] by its [id] or null if no such row exists.
  Future<MemberProfile?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    MemberProfileInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MemberProfile>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MemberProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [MemberProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<MemberProfile>> insert(
    _i1.DatabaseSession session,
    List<MemberProfile> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<MemberProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [MemberProfile] and returns the inserted row.
  ///
  /// The returned [MemberProfile] will have its `id` field set.
  Future<MemberProfile> insertRow(
    _i1.DatabaseSession session,
    MemberProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MemberProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MemberProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MemberProfile>> update(
    _i1.DatabaseSession session,
    List<MemberProfile> rows, {
    _i1.ColumnSelections<MemberProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MemberProfile>(
      rows,
      columns: columns?.call(MemberProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MemberProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MemberProfile> updateRow(
    _i1.DatabaseSession session,
    MemberProfile row, {
    _i1.ColumnSelections<MemberProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MemberProfile>(
      row,
      columns: columns?.call(MemberProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MemberProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MemberProfile?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<MemberProfileUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<MemberProfile>(
      id,
      columnValues: columnValues(MemberProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MemberProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<MemberProfile>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<MemberProfileUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<MemberProfileTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MemberProfileTable>? orderBy,
    _i1.OrderByListBuilder<MemberProfileTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<MemberProfile>(
      columnValues: columnValues(MemberProfile.t.updateTable),
      where: where(MemberProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MemberProfile.t),
      orderByList: orderByList?.call(MemberProfile.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [MemberProfile]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MemberProfile>> delete(
    _i1.DatabaseSession session,
    List<MemberProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MemberProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MemberProfile].
  Future<MemberProfile> deleteRow(
    _i1.DatabaseSession session,
    MemberProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MemberProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MemberProfile>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<MemberProfileTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MemberProfile>(
      where: where(MemberProfile.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MemberProfileTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MemberProfile>(
      where: where?.call(MemberProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MemberProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<MemberProfileTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MemberProfile>(
      where: where(MemberProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MemberProfileAttachRowRepository {
  const MemberProfileAttachRowRepository._();

  /// Creates a relation between the given [MemberProfile] and [AuthUser]
  /// by setting the [MemberProfile]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _i1.DatabaseSession session,
    MemberProfile memberProfile,
    _i2.AuthUser authUser, {
    _i1.Transaction? transaction,
  }) async {
    if (memberProfile.id == null) {
      throw ArgumentError.notNull('memberProfile.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $memberProfile = memberProfile.copyWith(authUserId: authUser.id);
    await session.db.updateRow<MemberProfile>(
      $memberProfile,
      columns: [MemberProfile.t.authUserId],
      transaction: transaction,
    );
  }
}
