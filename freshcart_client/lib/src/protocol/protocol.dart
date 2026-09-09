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

import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'common/models/edit_conflict_exception.dart' as _i2;
import 'common/models/invalid_join_code_exception.dart' as _i3;
import 'common/models/item_not_found_exception.dart' as _i4;
import 'common/models/list_not_found_exception.dart' as _i5;
import 'common/models/not_a_member_exception.dart' as _i6;
import 'items/models/note.dart' as _i7;
import 'items/models/shopping_item.dart' as _i8;
import 'lists/models/list_member.dart' as _i9;
import 'lists/models/member_role.dart' as _i10;
import 'lists/models/shopping_list.dart' as _i11;
import 'shops/models/shop.dart' as _i12;
import 'users/models/member_profile.dart' as _i13;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i14;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i15;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i16;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i17;
export 'common/models/edit_conflict_exception.dart';
export 'common/models/invalid_join_code_exception.dart';
export 'common/models/item_not_found_exception.dart';
export 'common/models/list_not_found_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/list_member.dart';
export 'lists/models/member_role.dart';
export 'lists/models/shopping_list.dart';
export 'shops/models/shop.dart';
export 'users/models/member_profile.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.EditConflictException) {
      return _i2.EditConflictException.fromJson(data) as T;
    }
    if (t == _i3.InvalidJoinCodeException) {
      return _i3.InvalidJoinCodeException.fromJson(data) as T;
    }
    if (t == _i4.ItemNotFoundException) {
      return _i4.ItemNotFoundException.fromJson(data) as T;
    }
    if (t == _i5.ListNotFoundException) {
      return _i5.ListNotFoundException.fromJson(data) as T;
    }
    if (t == _i6.NotAMemberException) {
      return _i6.NotAMemberException.fromJson(data) as T;
    }
    if (t == _i7.Note) {
      return _i7.Note.fromJson(data) as T;
    }
    if (t == _i8.ShoppingItem) {
      return _i8.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i9.ListMember) {
      return _i9.ListMember.fromJson(data) as T;
    }
    if (t == _i10.MemberRole) {
      return _i10.MemberRole.fromJson(data) as T;
    }
    if (t == _i11.ShoppingList) {
      return _i11.ShoppingList.fromJson(data) as T;
    }
    if (t == _i12.Shop) {
      return _i12.Shop.fromJson(data) as T;
    }
    if (t == _i13.MemberProfile) {
      return _i13.MemberProfile.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.EditConflictException?>()) {
      return (data != null ? _i2.EditConflictException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.InvalidJoinCodeException?>()) {
      return (data != null ? _i3.InvalidJoinCodeException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.ItemNotFoundException?>()) {
      return (data != null ? _i4.ItemNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.ListNotFoundException?>()) {
      return (data != null ? _i5.ListNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.NotAMemberException?>()) {
      return (data != null ? _i6.NotAMemberException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.Note?>()) {
      return (data != null ? _i7.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ShoppingItem?>()) {
      return (data != null ? _i8.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ListMember?>()) {
      return (data != null ? _i9.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.MemberRole?>()) {
      return (data != null ? _i10.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ShoppingList?>()) {
      return (data != null ? _i11.ShoppingList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Shop?>()) {
      return (data != null ? _i12.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.MemberProfile?>()) {
      return (data != null ? _i13.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i9.ListMember>) {
      return (data as List).map((e) => deserialize<_i9.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i9.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i9.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i8.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i8.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i8.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i12.Shop>) {
      return (data as List).map((e) => deserialize<_i12.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i12.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i12.Shop>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i14.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i14.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i15.ShoppingList>(e))
              .toList()
          as T;
    }
    try {
      return _i16.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i17.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.EditConflictException => 'EditConflictException',
      _i3.InvalidJoinCodeException => 'InvalidJoinCodeException',
      _i4.ItemNotFoundException => 'ItemNotFoundException',
      _i5.ListNotFoundException => 'ListNotFoundException',
      _i6.NotAMemberException => 'NotAMemberException',
      _i7.Note => 'Note',
      _i8.ShoppingItem => 'ShoppingItem',
      _i9.ListMember => 'ListMember',
      _i10.MemberRole => 'MemberRole',
      _i11.ShoppingList => 'ShoppingList',
      _i12.Shop => 'Shop',
      _i13.MemberProfile => 'MemberProfile',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('freshcart.', '');
    }

    switch (data) {
      case _i2.EditConflictException():
        return 'EditConflictException';
      case _i3.InvalidJoinCodeException():
        return 'InvalidJoinCodeException';
      case _i4.ItemNotFoundException():
        return 'ItemNotFoundException';
      case _i5.ListNotFoundException():
        return 'ListNotFoundException';
      case _i6.NotAMemberException():
        return 'NotAMemberException';
      case _i7.Note():
        return 'Note';
      case _i8.ShoppingItem():
        return 'ShoppingItem';
      case _i9.ListMember():
        return 'ListMember';
      case _i10.MemberRole():
        return 'MemberRole';
      case _i11.ShoppingList():
        return 'ShoppingList';
      case _i12.Shop():
        return 'Shop';
      case _i13.MemberProfile():
        return 'MemberProfile';
    }
    className = _i16.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i17.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'EditConflictException') {
      return deserialize<_i2.EditConflictException>(data['data']);
    }
    if (dataClassName == 'InvalidJoinCodeException') {
      return deserialize<_i3.InvalidJoinCodeException>(data['data']);
    }
    if (dataClassName == 'ItemNotFoundException') {
      return deserialize<_i4.ItemNotFoundException>(data['data']);
    }
    if (dataClassName == 'ListNotFoundException') {
      return deserialize<_i5.ListNotFoundException>(data['data']);
    }
    if (dataClassName == 'NotAMemberException') {
      return deserialize<_i6.NotAMemberException>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i7.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i8.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i9.ListMember>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i10.MemberRole>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i11.ShoppingList>(data['data']);
    }
    if (dataClassName == 'Shop') {
      return deserialize<_i12.Shop>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i13.MemberProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i16.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i17.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i16.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i17.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
