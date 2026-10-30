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
import 'auth/models/account_already_linked_exception.dart' as _i2;
import 'auth/models/linked_provider.dart' as _i3;
import 'common/models/edit_conflict_exception.dart' as _i4;
import 'common/models/not_a_member_exception.dart' as _i5;
import 'common/models/validation_exception.dart' as _i6;
import 'items/models/item_change.dart' as _i7;
import 'items/models/item_change_kind.dart' as _i8;
import 'items/models/item_name_history.dart' as _i9;
import 'items/models/item_not_found_exception.dart' as _i10;
import 'items/models/note.dart' as _i11;
import 'items/models/shopping_item.dart' as _i12;
import 'lists/models/invalid_join_code_exception.dart' as _i13;
import 'lists/models/list_member.dart' as _i14;
import 'lists/models/list_not_found_exception.dart' as _i15;
import 'lists/models/list_summary.dart' as _i16;
import 'lists/models/member_role.dart' as _i17;
import 'lists/models/not_list_owner_exception.dart' as _i18;
import 'lists/models/shopping_list.dart' as _i19;
import 'lists/models/too_many_join_attempts_exception.dart' as _i20;
import 'notifications/models/device_platform.dart' as _i21;
import 'notifications/models/device_token.dart' as _i22;
import 'notifications/models/list_mute.dart' as _i23;
import 'notifications/models/list_reference.dart' as _i24;
import 'notifications/models/notification_preferences.dart' as _i25;
import 'notifications/models/pending_item_notification.dart' as _i26;
import 'profile/models/avatar_photo_too_large_exception.dart' as _i27;
import 'profile/models/current_user.dart' as _i28;
import 'profile/models/member_profile.dart' as _i29;
import 'shops/models/shop.dart' as _i30;
import 'shops/models/shop_item_disposition.dart' as _i31;
import 'shops/models/shop_not_found_exception.dart' as _i32;
import 'package:freshcart_client/src/protocol/auth/models/linked_provider.dart'
    as _i33;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i34;
import 'package:freshcart_client/src/protocol/items/models/item_name_history.dart'
    as _i35;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i36;
import 'package:freshcart_client/src/protocol/lists/models/list_summary.dart'
    as _i37;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i38;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i39;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i40;
export 'auth/models/account_already_linked_exception.dart';
export 'auth/models/linked_provider.dart';
export 'common/models/edit_conflict_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'common/models/validation_exception.dart';
export 'items/models/item_change.dart';
export 'items/models/item_change_kind.dart';
export 'items/models/item_name_history.dart';
export 'items/models/item_not_found_exception.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/invalid_join_code_exception.dart';
export 'lists/models/list_member.dart';
export 'lists/models/list_not_found_exception.dart';
export 'lists/models/list_summary.dart';
export 'lists/models/member_role.dart';
export 'lists/models/not_list_owner_exception.dart';
export 'lists/models/shopping_list.dart';
export 'lists/models/too_many_join_attempts_exception.dart';
export 'notifications/models/device_platform.dart';
export 'notifications/models/device_token.dart';
export 'notifications/models/list_mute.dart';
export 'notifications/models/list_reference.dart';
export 'notifications/models/notification_preferences.dart';
export 'notifications/models/pending_item_notification.dart';
export 'profile/models/avatar_photo_too_large_exception.dart';
export 'profile/models/current_user.dart';
export 'profile/models/member_profile.dart';
export 'shops/models/shop.dart';
export 'shops/models/shop_item_disposition.dart';
export 'shops/models/shop_not_found_exception.dart';
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

    if (t == _i2.AccountAlreadyLinkedException) {
      return _i2.AccountAlreadyLinkedException.fromJson(data) as T;
    }
    if (t == _i3.LinkedProvider) {
      return _i3.LinkedProvider.fromJson(data) as T;
    }
    if (t == _i4.EditConflictException) {
      return _i4.EditConflictException.fromJson(data) as T;
    }
    if (t == _i5.NotAMemberException) {
      return _i5.NotAMemberException.fromJson(data) as T;
    }
    if (t == _i6.ValidationException) {
      return _i6.ValidationException.fromJson(data) as T;
    }
    if (t == _i7.ItemChange) {
      return _i7.ItemChange.fromJson(data) as T;
    }
    if (t == _i8.ItemChangeKind) {
      return _i8.ItemChangeKind.fromJson(data) as T;
    }
    if (t == _i9.ItemNameHistory) {
      return _i9.ItemNameHistory.fromJson(data) as T;
    }
    if (t == _i10.ItemNotFoundException) {
      return _i10.ItemNotFoundException.fromJson(data) as T;
    }
    if (t == _i11.Note) {
      return _i11.Note.fromJson(data) as T;
    }
    if (t == _i12.ShoppingItem) {
      return _i12.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i13.InvalidJoinCodeException) {
      return _i13.InvalidJoinCodeException.fromJson(data) as T;
    }
    if (t == _i14.ListMember) {
      return _i14.ListMember.fromJson(data) as T;
    }
    if (t == _i15.ListNotFoundException) {
      return _i15.ListNotFoundException.fromJson(data) as T;
    }
    if (t == _i16.ListSummary) {
      return _i16.ListSummary.fromJson(data) as T;
    }
    if (t == _i17.MemberRole) {
      return _i17.MemberRole.fromJson(data) as T;
    }
    if (t == _i18.NotListOwnerException) {
      return _i18.NotListOwnerException.fromJson(data) as T;
    }
    if (t == _i19.ShoppingList) {
      return _i19.ShoppingList.fromJson(data) as T;
    }
    if (t == _i20.TooManyJoinAttemptsException) {
      return _i20.TooManyJoinAttemptsException.fromJson(data) as T;
    }
    if (t == _i21.DevicePlatform) {
      return _i21.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i22.DeviceToken) {
      return _i22.DeviceToken.fromJson(data) as T;
    }
    if (t == _i23.ListMute) {
      return _i23.ListMute.fromJson(data) as T;
    }
    if (t == _i24.ListReference) {
      return _i24.ListReference.fromJson(data) as T;
    }
    if (t == _i25.NotificationPreferences) {
      return _i25.NotificationPreferences.fromJson(data) as T;
    }
    if (t == _i26.PendingItemNotification) {
      return _i26.PendingItemNotification.fromJson(data) as T;
    }
    if (t == _i27.AvatarPhotoTooLargeException) {
      return _i27.AvatarPhotoTooLargeException.fromJson(data) as T;
    }
    if (t == _i28.CurrentUser) {
      return _i28.CurrentUser.fromJson(data) as T;
    }
    if (t == _i29.MemberProfile) {
      return _i29.MemberProfile.fromJson(data) as T;
    }
    if (t == _i30.Shop) {
      return _i30.Shop.fromJson(data) as T;
    }
    if (t == _i31.ShopItemDisposition) {
      return _i31.ShopItemDisposition.fromJson(data) as T;
    }
    if (t == _i32.ShopNotFoundException) {
      return _i32.ShopNotFoundException.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AccountAlreadyLinkedException?>()) {
      return (data != null
              ? _i2.AccountAlreadyLinkedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i3.LinkedProvider?>()) {
      return (data != null ? _i3.LinkedProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.EditConflictException?>()) {
      return (data != null ? _i4.EditConflictException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.NotAMemberException?>()) {
      return (data != null ? _i5.NotAMemberException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.ValidationException?>()) {
      return (data != null ? _i6.ValidationException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ItemChange?>()) {
      return (data != null ? _i7.ItemChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ItemChangeKind?>()) {
      return (data != null ? _i8.ItemChangeKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ItemNameHistory?>()) {
      return (data != null ? _i9.ItemNameHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ItemNotFoundException?>()) {
      return (data != null ? _i10.ItemNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.Note?>()) {
      return (data != null ? _i11.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ShoppingItem?>()) {
      return (data != null ? _i12.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.InvalidJoinCodeException?>()) {
      return (data != null
              ? _i13.InvalidJoinCodeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.ListMember?>()) {
      return (data != null ? _i14.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ListNotFoundException?>()) {
      return (data != null ? _i15.ListNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.ListSummary?>()) {
      return (data != null ? _i16.ListSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.MemberRole?>()) {
      return (data != null ? _i17.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.NotListOwnerException?>()) {
      return (data != null ? _i18.NotListOwnerException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.ShoppingList?>()) {
      return (data != null ? _i19.ShoppingList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.TooManyJoinAttemptsException?>()) {
      return (data != null
              ? _i20.TooManyJoinAttemptsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.DevicePlatform?>()) {
      return (data != null ? _i21.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.DeviceToken?>()) {
      return (data != null ? _i22.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ListMute?>()) {
      return (data != null ? _i23.ListMute.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ListReference?>()) {
      return (data != null ? _i24.ListReference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.NotificationPreferences?>()) {
      return (data != null ? _i25.NotificationPreferences.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.PendingItemNotification?>()) {
      return (data != null ? _i26.PendingItemNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.AvatarPhotoTooLargeException?>()) {
      return (data != null
              ? _i27.AvatarPhotoTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i28.CurrentUser?>()) {
      return (data != null ? _i28.CurrentUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.MemberProfile?>()) {
      return (data != null ? _i29.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Shop?>()) {
      return (data != null ? _i30.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.ShopItemDisposition?>()) {
      return (data != null ? _i31.ShopItemDisposition.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.ShopNotFoundException?>()) {
      return (data != null ? _i32.ShopNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == List<_i14.ListMember>) {
      return (data as List).map((e) => deserialize<_i14.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i12.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i12.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i12.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i12.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i30.Shop>) {
      return (data as List).map((e) => deserialize<_i30.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i30.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i30.Shop>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i23.ListMute>) {
      return (data as List).map((e) => deserialize<_i23.ListMute>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i23.ListMute>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i23.ListMute>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i26.PendingItemNotification>) {
      return (data as List)
              .map((e) => deserialize<_i26.PendingItemNotification>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i26.PendingItemNotification>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i26.PendingItemNotification>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i9.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i9.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i9.ItemNameHistory>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i9.ItemNameHistory>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i33.LinkedProvider>) {
      return (data as List)
              .map((e) => deserialize<_i33.LinkedProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i34.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i1.UuidValue>) {
      return (data as List).map((e) => deserialize<_i1.UuidValue>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i35.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i35.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == List<_i36.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i36.ShoppingList>(e))
              .toList()
          as T;
    }
    if (t == List<_i37.ListSummary>) {
      return (data as List)
              .map((e) => deserialize<_i37.ListSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i38.Shop>) {
      return (data as List).map((e) => deserialize<_i38.Shop>(e)).toList() as T;
    }
    try {
      return _i39.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i40.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AccountAlreadyLinkedException => 'AccountAlreadyLinkedException',
      _i3.LinkedProvider => 'LinkedProvider',
      _i4.EditConflictException => 'EditConflictException',
      _i5.NotAMemberException => 'NotAMemberException',
      _i6.ValidationException => 'ValidationException',
      _i7.ItemChange => 'ItemChange',
      _i8.ItemChangeKind => 'ItemChangeKind',
      _i9.ItemNameHistory => 'ItemNameHistory',
      _i10.ItemNotFoundException => 'ItemNotFoundException',
      _i11.Note => 'Note',
      _i12.ShoppingItem => 'ShoppingItem',
      _i13.InvalidJoinCodeException => 'InvalidJoinCodeException',
      _i14.ListMember => 'ListMember',
      _i15.ListNotFoundException => 'ListNotFoundException',
      _i16.ListSummary => 'ListSummary',
      _i17.MemberRole => 'MemberRole',
      _i18.NotListOwnerException => 'NotListOwnerException',
      _i19.ShoppingList => 'ShoppingList',
      _i20.TooManyJoinAttemptsException => 'TooManyJoinAttemptsException',
      _i21.DevicePlatform => 'DevicePlatform',
      _i22.DeviceToken => 'DeviceToken',
      _i23.ListMute => 'ListMute',
      _i24.ListReference => 'ListReference',
      _i25.NotificationPreferences => 'NotificationPreferences',
      _i26.PendingItemNotification => 'PendingItemNotification',
      _i27.AvatarPhotoTooLargeException => 'AvatarPhotoTooLargeException',
      _i28.CurrentUser => 'CurrentUser',
      _i29.MemberProfile => 'MemberProfile',
      _i30.Shop => 'Shop',
      _i31.ShopItemDisposition => 'ShopItemDisposition',
      _i32.ShopNotFoundException => 'ShopNotFoundException',
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
      case _i2.AccountAlreadyLinkedException():
        return 'AccountAlreadyLinkedException';
      case _i3.LinkedProvider():
        return 'LinkedProvider';
      case _i4.EditConflictException():
        return 'EditConflictException';
      case _i5.NotAMemberException():
        return 'NotAMemberException';
      case _i6.ValidationException():
        return 'ValidationException';
      case _i7.ItemChange():
        return 'ItemChange';
      case _i8.ItemChangeKind():
        return 'ItemChangeKind';
      case _i9.ItemNameHistory():
        return 'ItemNameHistory';
      case _i10.ItemNotFoundException():
        return 'ItemNotFoundException';
      case _i11.Note():
        return 'Note';
      case _i12.ShoppingItem():
        return 'ShoppingItem';
      case _i13.InvalidJoinCodeException():
        return 'InvalidJoinCodeException';
      case _i14.ListMember():
        return 'ListMember';
      case _i15.ListNotFoundException():
        return 'ListNotFoundException';
      case _i16.ListSummary():
        return 'ListSummary';
      case _i17.MemberRole():
        return 'MemberRole';
      case _i18.NotListOwnerException():
        return 'NotListOwnerException';
      case _i19.ShoppingList():
        return 'ShoppingList';
      case _i20.TooManyJoinAttemptsException():
        return 'TooManyJoinAttemptsException';
      case _i21.DevicePlatform():
        return 'DevicePlatform';
      case _i22.DeviceToken():
        return 'DeviceToken';
      case _i23.ListMute():
        return 'ListMute';
      case _i24.ListReference():
        return 'ListReference';
      case _i25.NotificationPreferences():
        return 'NotificationPreferences';
      case _i26.PendingItemNotification():
        return 'PendingItemNotification';
      case _i27.AvatarPhotoTooLargeException():
        return 'AvatarPhotoTooLargeException';
      case _i28.CurrentUser():
        return 'CurrentUser';
      case _i29.MemberProfile():
        return 'MemberProfile';
      case _i30.Shop():
        return 'Shop';
      case _i31.ShopItemDisposition():
        return 'ShopItemDisposition';
      case _i32.ShopNotFoundException():
        return 'ShopNotFoundException';
    }
    className = _i39.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i40.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AccountAlreadyLinkedException') {
      return deserialize<_i2.AccountAlreadyLinkedException>(data['data']);
    }
    if (dataClassName == 'LinkedProvider') {
      return deserialize<_i3.LinkedProvider>(data['data']);
    }
    if (dataClassName == 'EditConflictException') {
      return deserialize<_i4.EditConflictException>(data['data']);
    }
    if (dataClassName == 'NotAMemberException') {
      return deserialize<_i5.NotAMemberException>(data['data']);
    }
    if (dataClassName == 'ValidationException') {
      return deserialize<_i6.ValidationException>(data['data']);
    }
    if (dataClassName == 'ItemChange') {
      return deserialize<_i7.ItemChange>(data['data']);
    }
    if (dataClassName == 'ItemChangeKind') {
      return deserialize<_i8.ItemChangeKind>(data['data']);
    }
    if (dataClassName == 'ItemNameHistory') {
      return deserialize<_i9.ItemNameHistory>(data['data']);
    }
    if (dataClassName == 'ItemNotFoundException') {
      return deserialize<_i10.ItemNotFoundException>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i11.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i12.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'InvalidJoinCodeException') {
      return deserialize<_i13.InvalidJoinCodeException>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i14.ListMember>(data['data']);
    }
    if (dataClassName == 'ListNotFoundException') {
      return deserialize<_i15.ListNotFoundException>(data['data']);
    }
    if (dataClassName == 'ListSummary') {
      return deserialize<_i16.ListSummary>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i17.MemberRole>(data['data']);
    }
    if (dataClassName == 'NotListOwnerException') {
      return deserialize<_i18.NotListOwnerException>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i19.ShoppingList>(data['data']);
    }
    if (dataClassName == 'TooManyJoinAttemptsException') {
      return deserialize<_i20.TooManyJoinAttemptsException>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i21.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i22.DeviceToken>(data['data']);
    }
    if (dataClassName == 'ListMute') {
      return deserialize<_i23.ListMute>(data['data']);
    }
    if (dataClassName == 'ListReference') {
      return deserialize<_i24.ListReference>(data['data']);
    }
    if (dataClassName == 'NotificationPreferences') {
      return deserialize<_i25.NotificationPreferences>(data['data']);
    }
    if (dataClassName == 'PendingItemNotification') {
      return deserialize<_i26.PendingItemNotification>(data['data']);
    }
    if (dataClassName == 'AvatarPhotoTooLargeException') {
      return deserialize<_i27.AvatarPhotoTooLargeException>(data['data']);
    }
    if (dataClassName == 'CurrentUser') {
      return deserialize<_i28.CurrentUser>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i29.MemberProfile>(data['data']);
    }
    if (dataClassName == 'Shop') {
      return deserialize<_i30.Shop>(data['data']);
    }
    if (dataClassName == 'ShopItemDisposition') {
      return deserialize<_i31.ShopItemDisposition>(data['data']);
    }
    if (dataClassName == 'ShopNotFoundException') {
      return deserialize<_i32.ShopNotFoundException>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i39.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i40.Protocol().deserializeByClassName(data);
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
      return _i39.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i40.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
