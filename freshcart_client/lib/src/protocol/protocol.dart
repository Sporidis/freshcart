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
import 'common/models/shop_not_found_exception.dart' as _i7;
import 'items/models/note.dart' as _i8;
import 'items/models/shopping_item.dart' as _i9;
import 'lists/models/list_member.dart' as _i10;
import 'lists/models/member_role.dart' as _i11;
import 'lists/models/shopping_list.dart' as _i12;
import 'shops/models/shop.dart' as _i13;
import 'users/models/current_user.dart' as _i14;
import 'users/models/member_profile.dart' as _i15;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i16;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i17;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i18;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i19;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i20;
export 'common/models/edit_conflict_exception.dart';
export 'common/models/invalid_join_code_exception.dart';
export 'common/models/item_not_found_exception.dart';
export 'common/models/list_not_found_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'common/models/shop_not_found_exception.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/list_member.dart';
export 'lists/models/member_role.dart';
export 'lists/models/shopping_list.dart';
export 'shops/models/shop.dart';
export 'users/models/current_user.dart';
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
    if (t == _i7.ShopNotFoundException) {
      return _i7.ShopNotFoundException.fromJson(data) as T;
    }
    if (t == _i8.Note) {
      return _i8.Note.fromJson(data) as T;
    }
    if (t == _i9.ShoppingItem) {
      return _i9.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i10.ListMember) {
      return _i10.ListMember.fromJson(data) as T;
    }
    if (t == _i11.MemberRole) {
      return _i11.MemberRole.fromJson(data) as T;
    }
    if (t == _i12.ShoppingList) {
      return _i12.ShoppingList.fromJson(data) as T;
    }
    if (t == _i13.Shop) {
      return _i13.Shop.fromJson(data) as T;
    }
    if (t == _i14.CurrentUser) {
      return _i14.CurrentUser.fromJson(data) as T;
    }
    if (t == _i15.MemberProfile) {
      return _i15.MemberProfile.fromJson(data) as T;
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
    if (t == _i1.getType<_i7.ShopNotFoundException?>()) {
      return (data != null ? _i7.ShopNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.Note?>()) {
      return (data != null ? _i8.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ShoppingItem?>()) {
      return (data != null ? _i9.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ListMember?>()) {
      return (data != null ? _i10.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.MemberRole?>()) {
      return (data != null ? _i11.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ShoppingList?>()) {
      return (data != null ? _i12.ShoppingList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Shop?>()) {
      return (data != null ? _i13.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CurrentUser?>()) {
      return (data != null ? _i14.CurrentUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.MemberProfile?>()) {
      return (data != null ? _i15.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i10.ListMember>) {
      return (data as List).map((e) => deserialize<_i10.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i10.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i10.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i9.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i9.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i9.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i9.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i13.Shop>) {
      return (data as List).map((e) => deserialize<_i13.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i13.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i13.Shop>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i16.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i16.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i17.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i17.ShoppingList>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.Shop>) {
      return (data as List).map((e) => deserialize<_i18.Shop>(e)).toList() as T;
    }
    try {
      return _i19.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i20.Protocol().deserialize<T>(data, t);
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
      _i7.ShopNotFoundException => 'ShopNotFoundException',
      _i8.Note => 'Note',
      _i9.ShoppingItem => 'ShoppingItem',
      _i10.ListMember => 'ListMember',
      _i11.MemberRole => 'MemberRole',
      _i12.ShoppingList => 'ShoppingList',
      _i13.Shop => 'Shop',
      _i14.CurrentUser => 'CurrentUser',
      _i15.MemberProfile => 'MemberProfile',
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
      case _i7.ShopNotFoundException():
        return 'ShopNotFoundException';
      case _i8.Note():
        return 'Note';
      case _i9.ShoppingItem():
        return 'ShoppingItem';
      case _i10.ListMember():
        return 'ListMember';
      case _i11.MemberRole():
        return 'MemberRole';
      case _i12.ShoppingList():
        return 'ShoppingList';
      case _i13.Shop():
        return 'Shop';
      case _i14.CurrentUser():
        return 'CurrentUser';
      case _i15.MemberProfile():
        return 'MemberProfile';
    }
    className = _i19.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i20.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'ShopNotFoundException') {
      return deserialize<_i7.ShopNotFoundException>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i8.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i9.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i10.ListMember>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i11.MemberRole>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i12.ShoppingList>(data['data']);
    }
    if (dataClassName == 'Shop') {
      return deserialize<_i13.Shop>(data['data']);
    }
    if (dataClassName == 'CurrentUser') {
      return deserialize<_i14.CurrentUser>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i15.MemberProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i19.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i20.Protocol().deserializeByClassName(data);
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
      return _i19.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i20.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
