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
import 'auth/models/linked_provider.dart' as _i2;
import 'common/models/account_already_linked_exception.dart' as _i3;
import 'common/models/edit_conflict_exception.dart' as _i4;
import 'common/models/email_already_in_use_exception.dart' as _i5;
import 'common/models/invalid_join_code_exception.dart' as _i6;
import 'common/models/item_not_found_exception.dart' as _i7;
import 'common/models/list_not_found_exception.dart' as _i8;
import 'common/models/not_a_member_exception.dart' as _i9;
import 'common/models/shop_not_found_exception.dart' as _i10;
import 'items/models/item_change.dart' as _i11;
import 'items/models/item_change_kind.dart' as _i12;
import 'items/models/note.dart' as _i13;
import 'items/models/shopping_item.dart' as _i14;
import 'lists/models/list_member.dart' as _i15;
import 'lists/models/member_role.dart' as _i16;
import 'lists/models/shopping_list.dart' as _i17;
import 'notifications/models/device_platform.dart' as _i18;
import 'notifications/models/device_token.dart' as _i19;
import 'notifications/models/list_mute.dart' as _i20;
import 'notifications/models/list_reference.dart' as _i21;
import 'notifications/models/pending_item_notification.dart' as _i22;
import 'shops/models/shop.dart' as _i23;
import 'shops/models/shop_item_disposition.dart' as _i24;
import 'users/models/current_user.dart' as _i25;
import 'users/models/member_profile.dart' as _i26;
import 'package:freshcart_client/src/protocol/auth/models/linked_provider.dart'
    as _i27;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i28;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i29;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i30;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i31;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i32;
export 'auth/models/linked_provider.dart';
export 'common/models/account_already_linked_exception.dart';
export 'common/models/edit_conflict_exception.dart';
export 'common/models/email_already_in_use_exception.dart';
export 'common/models/invalid_join_code_exception.dart';
export 'common/models/item_not_found_exception.dart';
export 'common/models/list_not_found_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'common/models/shop_not_found_exception.dart';
export 'items/models/item_change.dart';
export 'items/models/item_change_kind.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/list_member.dart';
export 'lists/models/member_role.dart';
export 'lists/models/shopping_list.dart';
export 'notifications/models/device_platform.dart';
export 'notifications/models/device_token.dart';
export 'notifications/models/list_mute.dart';
export 'notifications/models/list_reference.dart';
export 'notifications/models/pending_item_notification.dart';
export 'shops/models/shop.dart';
export 'shops/models/shop_item_disposition.dart';
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

    if (t == _i2.LinkedProvider) {
      return _i2.LinkedProvider.fromJson(data) as T;
    }
    if (t == _i3.AccountAlreadyLinkedException) {
      return _i3.AccountAlreadyLinkedException.fromJson(data) as T;
    }
    if (t == _i4.EditConflictException) {
      return _i4.EditConflictException.fromJson(data) as T;
    }
    if (t == _i5.EmailAlreadyInUseException) {
      return _i5.EmailAlreadyInUseException.fromJson(data) as T;
    }
    if (t == _i6.InvalidJoinCodeException) {
      return _i6.InvalidJoinCodeException.fromJson(data) as T;
    }
    if (t == _i7.ItemNotFoundException) {
      return _i7.ItemNotFoundException.fromJson(data) as T;
    }
    if (t == _i8.ListNotFoundException) {
      return _i8.ListNotFoundException.fromJson(data) as T;
    }
    if (t == _i9.NotAMemberException) {
      return _i9.NotAMemberException.fromJson(data) as T;
    }
    if (t == _i10.ShopNotFoundException) {
      return _i10.ShopNotFoundException.fromJson(data) as T;
    }
    if (t == _i11.ItemChange) {
      return _i11.ItemChange.fromJson(data) as T;
    }
    if (t == _i12.ItemChangeKind) {
      return _i12.ItemChangeKind.fromJson(data) as T;
    }
    if (t == _i13.Note) {
      return _i13.Note.fromJson(data) as T;
    }
    if (t == _i14.ShoppingItem) {
      return _i14.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i15.ListMember) {
      return _i15.ListMember.fromJson(data) as T;
    }
    if (t == _i16.MemberRole) {
      return _i16.MemberRole.fromJson(data) as T;
    }
    if (t == _i17.ShoppingList) {
      return _i17.ShoppingList.fromJson(data) as T;
    }
    if (t == _i18.DevicePlatform) {
      return _i18.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i19.DeviceToken) {
      return _i19.DeviceToken.fromJson(data) as T;
    }
    if (t == _i20.ListMute) {
      return _i20.ListMute.fromJson(data) as T;
    }
    if (t == _i21.ListReference) {
      return _i21.ListReference.fromJson(data) as T;
    }
    if (t == _i22.PendingItemNotification) {
      return _i22.PendingItemNotification.fromJson(data) as T;
    }
    if (t == _i23.Shop) {
      return _i23.Shop.fromJson(data) as T;
    }
    if (t == _i24.ShopItemDisposition) {
      return _i24.ShopItemDisposition.fromJson(data) as T;
    }
    if (t == _i25.CurrentUser) {
      return _i25.CurrentUser.fromJson(data) as T;
    }
    if (t == _i26.MemberProfile) {
      return _i26.MemberProfile.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.LinkedProvider?>()) {
      return (data != null ? _i2.LinkedProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AccountAlreadyLinkedException?>()) {
      return (data != null
              ? _i3.AccountAlreadyLinkedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i4.EditConflictException?>()) {
      return (data != null ? _i4.EditConflictException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.EmailAlreadyInUseException?>()) {
      return (data != null
              ? _i5.EmailAlreadyInUseException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i6.InvalidJoinCodeException?>()) {
      return (data != null ? _i6.InvalidJoinCodeException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ItemNotFoundException?>()) {
      return (data != null ? _i7.ItemNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ListNotFoundException?>()) {
      return (data != null ? _i8.ListNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.NotAMemberException?>()) {
      return (data != null ? _i9.NotAMemberException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.ShopNotFoundException?>()) {
      return (data != null ? _i10.ShopNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.ItemChange?>()) {
      return (data != null ? _i11.ItemChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ItemChangeKind?>()) {
      return (data != null ? _i12.ItemChangeKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Note?>()) {
      return (data != null ? _i13.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ShoppingItem?>()) {
      return (data != null ? _i14.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ListMember?>()) {
      return (data != null ? _i15.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.MemberRole?>()) {
      return (data != null ? _i16.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ShoppingList?>()) {
      return (data != null ? _i17.ShoppingList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.DevicePlatform?>()) {
      return (data != null ? _i18.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.DeviceToken?>()) {
      return (data != null ? _i19.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ListMute?>()) {
      return (data != null ? _i20.ListMute.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ListReference?>()) {
      return (data != null ? _i21.ListReference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.PendingItemNotification?>()) {
      return (data != null ? _i22.PendingItemNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.Shop?>()) {
      return (data != null ? _i23.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ShopItemDisposition?>()) {
      return (data != null ? _i24.ShopItemDisposition.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.CurrentUser?>()) {
      return (data != null ? _i25.CurrentUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.MemberProfile?>()) {
      return (data != null ? _i26.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i15.ListMember>) {
      return (data as List).map((e) => deserialize<_i15.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i15.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i15.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i14.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i14.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i23.Shop>) {
      return (data as List).map((e) => deserialize<_i23.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i23.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i23.Shop>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i20.ListMute>) {
      return (data as List).map((e) => deserialize<_i20.ListMute>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i20.ListMute>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i20.ListMute>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i22.PendingItemNotification>) {
      return (data as List)
              .map((e) => deserialize<_i22.PendingItemNotification>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i22.PendingItemNotification>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i22.PendingItemNotification>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i27.LinkedProvider>) {
      return (data as List)
              .map((e) => deserialize<_i27.LinkedProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_i28.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i28.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i29.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i29.ShoppingList>(e))
              .toList()
          as T;
    }
    if (t == List<_i30.Shop>) {
      return (data as List).map((e) => deserialize<_i30.Shop>(e)).toList() as T;
    }
    try {
      return _i31.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i32.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.LinkedProvider => 'LinkedProvider',
      _i3.AccountAlreadyLinkedException => 'AccountAlreadyLinkedException',
      _i4.EditConflictException => 'EditConflictException',
      _i5.EmailAlreadyInUseException => 'EmailAlreadyInUseException',
      _i6.InvalidJoinCodeException => 'InvalidJoinCodeException',
      _i7.ItemNotFoundException => 'ItemNotFoundException',
      _i8.ListNotFoundException => 'ListNotFoundException',
      _i9.NotAMemberException => 'NotAMemberException',
      _i10.ShopNotFoundException => 'ShopNotFoundException',
      _i11.ItemChange => 'ItemChange',
      _i12.ItemChangeKind => 'ItemChangeKind',
      _i13.Note => 'Note',
      _i14.ShoppingItem => 'ShoppingItem',
      _i15.ListMember => 'ListMember',
      _i16.MemberRole => 'MemberRole',
      _i17.ShoppingList => 'ShoppingList',
      _i18.DevicePlatform => 'DevicePlatform',
      _i19.DeviceToken => 'DeviceToken',
      _i20.ListMute => 'ListMute',
      _i21.ListReference => 'ListReference',
      _i22.PendingItemNotification => 'PendingItemNotification',
      _i23.Shop => 'Shop',
      _i24.ShopItemDisposition => 'ShopItemDisposition',
      _i25.CurrentUser => 'CurrentUser',
      _i26.MemberProfile => 'MemberProfile',
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
      case _i2.LinkedProvider():
        return 'LinkedProvider';
      case _i3.AccountAlreadyLinkedException():
        return 'AccountAlreadyLinkedException';
      case _i4.EditConflictException():
        return 'EditConflictException';
      case _i5.EmailAlreadyInUseException():
        return 'EmailAlreadyInUseException';
      case _i6.InvalidJoinCodeException():
        return 'InvalidJoinCodeException';
      case _i7.ItemNotFoundException():
        return 'ItemNotFoundException';
      case _i8.ListNotFoundException():
        return 'ListNotFoundException';
      case _i9.NotAMemberException():
        return 'NotAMemberException';
      case _i10.ShopNotFoundException():
        return 'ShopNotFoundException';
      case _i11.ItemChange():
        return 'ItemChange';
      case _i12.ItemChangeKind():
        return 'ItemChangeKind';
      case _i13.Note():
        return 'Note';
      case _i14.ShoppingItem():
        return 'ShoppingItem';
      case _i15.ListMember():
        return 'ListMember';
      case _i16.MemberRole():
        return 'MemberRole';
      case _i17.ShoppingList():
        return 'ShoppingList';
      case _i18.DevicePlatform():
        return 'DevicePlatform';
      case _i19.DeviceToken():
        return 'DeviceToken';
      case _i20.ListMute():
        return 'ListMute';
      case _i21.ListReference():
        return 'ListReference';
      case _i22.PendingItemNotification():
        return 'PendingItemNotification';
      case _i23.Shop():
        return 'Shop';
      case _i24.ShopItemDisposition():
        return 'ShopItemDisposition';
      case _i25.CurrentUser():
        return 'CurrentUser';
      case _i26.MemberProfile():
        return 'MemberProfile';
    }
    className = _i31.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i32.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'LinkedProvider') {
      return deserialize<_i2.LinkedProvider>(data['data']);
    }
    if (dataClassName == 'AccountAlreadyLinkedException') {
      return deserialize<_i3.AccountAlreadyLinkedException>(data['data']);
    }
    if (dataClassName == 'EditConflictException') {
      return deserialize<_i4.EditConflictException>(data['data']);
    }
    if (dataClassName == 'EmailAlreadyInUseException') {
      return deserialize<_i5.EmailAlreadyInUseException>(data['data']);
    }
    if (dataClassName == 'InvalidJoinCodeException') {
      return deserialize<_i6.InvalidJoinCodeException>(data['data']);
    }
    if (dataClassName == 'ItemNotFoundException') {
      return deserialize<_i7.ItemNotFoundException>(data['data']);
    }
    if (dataClassName == 'ListNotFoundException') {
      return deserialize<_i8.ListNotFoundException>(data['data']);
    }
    if (dataClassName == 'NotAMemberException') {
      return deserialize<_i9.NotAMemberException>(data['data']);
    }
    if (dataClassName == 'ShopNotFoundException') {
      return deserialize<_i10.ShopNotFoundException>(data['data']);
    }
    if (dataClassName == 'ItemChange') {
      return deserialize<_i11.ItemChange>(data['data']);
    }
    if (dataClassName == 'ItemChangeKind') {
      return deserialize<_i12.ItemChangeKind>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i13.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i14.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i15.ListMember>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i16.MemberRole>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i17.ShoppingList>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i18.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i19.DeviceToken>(data['data']);
    }
    if (dataClassName == 'ListMute') {
      return deserialize<_i20.ListMute>(data['data']);
    }
    if (dataClassName == 'ListReference') {
      return deserialize<_i21.ListReference>(data['data']);
    }
    if (dataClassName == 'PendingItemNotification') {
      return deserialize<_i22.PendingItemNotification>(data['data']);
    }
    if (dataClassName == 'Shop') {
      return deserialize<_i23.Shop>(data['data']);
    }
    if (dataClassName == 'ShopItemDisposition') {
      return deserialize<_i24.ShopItemDisposition>(data['data']);
    }
    if (dataClassName == 'CurrentUser') {
      return deserialize<_i25.CurrentUser>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i26.MemberProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i31.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i32.Protocol().deserializeByClassName(data);
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
      return _i31.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i32.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
