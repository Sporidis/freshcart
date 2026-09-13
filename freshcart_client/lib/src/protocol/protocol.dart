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
import 'common/models/avatar_photo_too_large_exception.dart' as _i4;
import 'common/models/edit_conflict_exception.dart' as _i5;
import 'common/models/email_already_in_use_exception.dart' as _i6;
import 'common/models/invalid_join_code_exception.dart' as _i7;
import 'common/models/item_not_found_exception.dart' as _i8;
import 'common/models/list_not_found_exception.dart' as _i9;
import 'common/models/not_a_member_exception.dart' as _i10;
import 'common/models/shop_not_found_exception.dart' as _i11;
import 'items/models/item_change.dart' as _i12;
import 'items/models/item_change_kind.dart' as _i13;
import 'items/models/item_name_history.dart' as _i14;
import 'items/models/note.dart' as _i15;
import 'items/models/shopping_item.dart' as _i16;
import 'lists/models/list_member.dart' as _i17;
import 'lists/models/list_summary.dart' as _i18;
import 'lists/models/member_role.dart' as _i19;
import 'lists/models/shopping_list.dart' as _i20;
import 'notifications/models/device_platform.dart' as _i21;
import 'notifications/models/device_token.dart' as _i22;
import 'notifications/models/list_mute.dart' as _i23;
import 'notifications/models/list_reference.dart' as _i24;
import 'notifications/models/notification_preferences.dart' as _i25;
import 'notifications/models/pending_item_notification.dart' as _i26;
import 'shops/models/shop.dart' as _i27;
import 'shops/models/shop_item_disposition.dart' as _i28;
import 'users/models/current_user.dart' as _i29;
import 'users/models/member_profile.dart' as _i30;
import 'package:freshcart_client/src/protocol/auth/models/linked_provider.dart'
    as _i31;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i32;
import 'package:freshcart_client/src/protocol/items/models/item_name_history.dart'
    as _i33;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i34;
import 'package:freshcart_client/src/protocol/lists/models/list_summary.dart'
    as _i35;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i36;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i37;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i38;
export 'auth/models/linked_provider.dart';
export 'common/models/account_already_linked_exception.dart';
export 'common/models/avatar_photo_too_large_exception.dart';
export 'common/models/edit_conflict_exception.dart';
export 'common/models/email_already_in_use_exception.dart';
export 'common/models/invalid_join_code_exception.dart';
export 'common/models/item_not_found_exception.dart';
export 'common/models/list_not_found_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'common/models/shop_not_found_exception.dart';
export 'items/models/item_change.dart';
export 'items/models/item_change_kind.dart';
export 'items/models/item_name_history.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/list_member.dart';
export 'lists/models/list_summary.dart';
export 'lists/models/member_role.dart';
export 'lists/models/shopping_list.dart';
export 'notifications/models/device_platform.dart';
export 'notifications/models/device_token.dart';
export 'notifications/models/list_mute.dart';
export 'notifications/models/list_reference.dart';
export 'notifications/models/notification_preferences.dart';
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
    if (t == _i4.AvatarPhotoTooLargeException) {
      return _i4.AvatarPhotoTooLargeException.fromJson(data) as T;
    }
    if (t == _i5.EditConflictException) {
      return _i5.EditConflictException.fromJson(data) as T;
    }
    if (t == _i6.EmailAlreadyInUseException) {
      return _i6.EmailAlreadyInUseException.fromJson(data) as T;
    }
    if (t == _i7.InvalidJoinCodeException) {
      return _i7.InvalidJoinCodeException.fromJson(data) as T;
    }
    if (t == _i8.ItemNotFoundException) {
      return _i8.ItemNotFoundException.fromJson(data) as T;
    }
    if (t == _i9.ListNotFoundException) {
      return _i9.ListNotFoundException.fromJson(data) as T;
    }
    if (t == _i10.NotAMemberException) {
      return _i10.NotAMemberException.fromJson(data) as T;
    }
    if (t == _i11.ShopNotFoundException) {
      return _i11.ShopNotFoundException.fromJson(data) as T;
    }
    if (t == _i12.ItemChange) {
      return _i12.ItemChange.fromJson(data) as T;
    }
    if (t == _i13.ItemChangeKind) {
      return _i13.ItemChangeKind.fromJson(data) as T;
    }
    if (t == _i14.ItemNameHistory) {
      return _i14.ItemNameHistory.fromJson(data) as T;
    }
    if (t == _i15.Note) {
      return _i15.Note.fromJson(data) as T;
    }
    if (t == _i16.ShoppingItem) {
      return _i16.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i17.ListMember) {
      return _i17.ListMember.fromJson(data) as T;
    }
    if (t == _i18.ListSummary) {
      return _i18.ListSummary.fromJson(data) as T;
    }
    if (t == _i19.MemberRole) {
      return _i19.MemberRole.fromJson(data) as T;
    }
    if (t == _i20.ShoppingList) {
      return _i20.ShoppingList.fromJson(data) as T;
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
    if (t == _i27.Shop) {
      return _i27.Shop.fromJson(data) as T;
    }
    if (t == _i28.ShopItemDisposition) {
      return _i28.ShopItemDisposition.fromJson(data) as T;
    }
    if (t == _i29.CurrentUser) {
      return _i29.CurrentUser.fromJson(data) as T;
    }
    if (t == _i30.MemberProfile) {
      return _i30.MemberProfile.fromJson(data) as T;
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
    if (t == _i1.getType<_i4.AvatarPhotoTooLargeException?>()) {
      return (data != null
              ? _i4.AvatarPhotoTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i5.EditConflictException?>()) {
      return (data != null ? _i5.EditConflictException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.EmailAlreadyInUseException?>()) {
      return (data != null
              ? _i6.EmailAlreadyInUseException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i7.InvalidJoinCodeException?>()) {
      return (data != null ? _i7.InvalidJoinCodeException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ItemNotFoundException?>()) {
      return (data != null ? _i8.ItemNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.ListNotFoundException?>()) {
      return (data != null ? _i9.ListNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.NotAMemberException?>()) {
      return (data != null ? _i10.NotAMemberException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.ShopNotFoundException?>()) {
      return (data != null ? _i11.ShopNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.ItemChange?>()) {
      return (data != null ? _i12.ItemChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ItemChangeKind?>()) {
      return (data != null ? _i13.ItemChangeKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ItemNameHistory?>()) {
      return (data != null ? _i14.ItemNameHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Note?>()) {
      return (data != null ? _i15.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.ShoppingItem?>()) {
      return (data != null ? _i16.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ListMember?>()) {
      return (data != null ? _i17.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ListSummary?>()) {
      return (data != null ? _i18.ListSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.MemberRole?>()) {
      return (data != null ? _i19.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ShoppingList?>()) {
      return (data != null ? _i20.ShoppingList.fromJson(data) : null) as T;
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
    if (t == _i1.getType<_i27.Shop?>()) {
      return (data != null ? _i27.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.ShopItemDisposition?>()) {
      return (data != null ? _i28.ShopItemDisposition.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.CurrentUser?>()) {
      return (data != null ? _i29.CurrentUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.MemberProfile?>()) {
      return (data != null ? _i30.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i17.ListMember>) {
      return (data as List).map((e) => deserialize<_i17.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i16.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i16.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i16.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i16.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i27.Shop>) {
      return (data as List).map((e) => deserialize<_i27.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i27.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i27.Shop>(e)).toList()
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
    if (t == List<_i14.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i14.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.ItemNameHistory>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.ItemNameHistory>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i31.LinkedProvider>) {
      return (data as List)
              .map((e) => deserialize<_i31.LinkedProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i32.ShoppingItem>(e))
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
    if (t == List<_i33.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i33.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i34.ShoppingList>(e))
              .toList()
          as T;
    }
    if (t == List<_i35.ListSummary>) {
      return (data as List)
              .map((e) => deserialize<_i35.ListSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i36.Shop>) {
      return (data as List).map((e) => deserialize<_i36.Shop>(e)).toList() as T;
    }
    try {
      return _i37.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i38.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.LinkedProvider => 'LinkedProvider',
      _i3.AccountAlreadyLinkedException => 'AccountAlreadyLinkedException',
      _i4.AvatarPhotoTooLargeException => 'AvatarPhotoTooLargeException',
      _i5.EditConflictException => 'EditConflictException',
      _i6.EmailAlreadyInUseException => 'EmailAlreadyInUseException',
      _i7.InvalidJoinCodeException => 'InvalidJoinCodeException',
      _i8.ItemNotFoundException => 'ItemNotFoundException',
      _i9.ListNotFoundException => 'ListNotFoundException',
      _i10.NotAMemberException => 'NotAMemberException',
      _i11.ShopNotFoundException => 'ShopNotFoundException',
      _i12.ItemChange => 'ItemChange',
      _i13.ItemChangeKind => 'ItemChangeKind',
      _i14.ItemNameHistory => 'ItemNameHistory',
      _i15.Note => 'Note',
      _i16.ShoppingItem => 'ShoppingItem',
      _i17.ListMember => 'ListMember',
      _i18.ListSummary => 'ListSummary',
      _i19.MemberRole => 'MemberRole',
      _i20.ShoppingList => 'ShoppingList',
      _i21.DevicePlatform => 'DevicePlatform',
      _i22.DeviceToken => 'DeviceToken',
      _i23.ListMute => 'ListMute',
      _i24.ListReference => 'ListReference',
      _i25.NotificationPreferences => 'NotificationPreferences',
      _i26.PendingItemNotification => 'PendingItemNotification',
      _i27.Shop => 'Shop',
      _i28.ShopItemDisposition => 'ShopItemDisposition',
      _i29.CurrentUser => 'CurrentUser',
      _i30.MemberProfile => 'MemberProfile',
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
      case _i4.AvatarPhotoTooLargeException():
        return 'AvatarPhotoTooLargeException';
      case _i5.EditConflictException():
        return 'EditConflictException';
      case _i6.EmailAlreadyInUseException():
        return 'EmailAlreadyInUseException';
      case _i7.InvalidJoinCodeException():
        return 'InvalidJoinCodeException';
      case _i8.ItemNotFoundException():
        return 'ItemNotFoundException';
      case _i9.ListNotFoundException():
        return 'ListNotFoundException';
      case _i10.NotAMemberException():
        return 'NotAMemberException';
      case _i11.ShopNotFoundException():
        return 'ShopNotFoundException';
      case _i12.ItemChange():
        return 'ItemChange';
      case _i13.ItemChangeKind():
        return 'ItemChangeKind';
      case _i14.ItemNameHistory():
        return 'ItemNameHistory';
      case _i15.Note():
        return 'Note';
      case _i16.ShoppingItem():
        return 'ShoppingItem';
      case _i17.ListMember():
        return 'ListMember';
      case _i18.ListSummary():
        return 'ListSummary';
      case _i19.MemberRole():
        return 'MemberRole';
      case _i20.ShoppingList():
        return 'ShoppingList';
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
      case _i27.Shop():
        return 'Shop';
      case _i28.ShopItemDisposition():
        return 'ShopItemDisposition';
      case _i29.CurrentUser():
        return 'CurrentUser';
      case _i30.MemberProfile():
        return 'MemberProfile';
    }
    className = _i37.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i38.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AvatarPhotoTooLargeException') {
      return deserialize<_i4.AvatarPhotoTooLargeException>(data['data']);
    }
    if (dataClassName == 'EditConflictException') {
      return deserialize<_i5.EditConflictException>(data['data']);
    }
    if (dataClassName == 'EmailAlreadyInUseException') {
      return deserialize<_i6.EmailAlreadyInUseException>(data['data']);
    }
    if (dataClassName == 'InvalidJoinCodeException') {
      return deserialize<_i7.InvalidJoinCodeException>(data['data']);
    }
    if (dataClassName == 'ItemNotFoundException') {
      return deserialize<_i8.ItemNotFoundException>(data['data']);
    }
    if (dataClassName == 'ListNotFoundException') {
      return deserialize<_i9.ListNotFoundException>(data['data']);
    }
    if (dataClassName == 'NotAMemberException') {
      return deserialize<_i10.NotAMemberException>(data['data']);
    }
    if (dataClassName == 'ShopNotFoundException') {
      return deserialize<_i11.ShopNotFoundException>(data['data']);
    }
    if (dataClassName == 'ItemChange') {
      return deserialize<_i12.ItemChange>(data['data']);
    }
    if (dataClassName == 'ItemChangeKind') {
      return deserialize<_i13.ItemChangeKind>(data['data']);
    }
    if (dataClassName == 'ItemNameHistory') {
      return deserialize<_i14.ItemNameHistory>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i15.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i16.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i17.ListMember>(data['data']);
    }
    if (dataClassName == 'ListSummary') {
      return deserialize<_i18.ListSummary>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i19.MemberRole>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i20.ShoppingList>(data['data']);
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
    if (dataClassName == 'Shop') {
      return deserialize<_i27.Shop>(data['data']);
    }
    if (dataClassName == 'ShopItemDisposition') {
      return deserialize<_i28.ShopItemDisposition>(data['data']);
    }
    if (dataClassName == 'CurrentUser') {
      return deserialize<_i29.CurrentUser>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i30.MemberProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i37.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i38.Protocol().deserializeByClassName(data);
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
      return _i37.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i38.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
