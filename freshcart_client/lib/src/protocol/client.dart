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
import 'dart:async' as _i2;
import 'package:freshcart_client/src/protocol/auth/models/linked_provider.dart'
    as _i3;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i4;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i5;
import 'package:freshcart_client/src/protocol/items/models/shopping_item.dart'
    as _i6;
import 'package:freshcart_client/src/protocol/items/models/item_name_history.dart'
    as _i7;
import 'package:freshcart_client/src/protocol/items/models/item_change.dart'
    as _i8;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i9;
import 'package:freshcart_client/src/protocol/lists/models/list_summary.dart'
    as _i10;
import 'package:freshcart_client/src/protocol/notifications/models/device_token.dart'
    as _i11;
import 'package:freshcart_client/src/protocol/notifications/models/device_platform.dart'
    as _i12;
import 'package:freshcart_client/src/protocol/notifications/models/notification_preferences.dart'
    as _i13;
import 'package:freshcart_client/src/protocol/profile/models/current_user.dart'
    as _i14;
import 'package:freshcart_client/src/protocol/profile/models/member_profile.dart'
    as _i15;
import 'dart:typed_data' as _i16;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i17;
import 'package:freshcart_client/src/protocol/shops/models/shop_item_disposition.dart'
    as _i18;
import 'protocol.dart' as _i19;

/// Endpoint to upgrade an anonymous account by adding a login (email).
/// {@category Endpoint}
class EndpointAccount extends _i1.EndpointRef {
  EndpointAccount(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  /// Which login methods the caller's account has.
  _i2.Future<List<_i3.LinkedProvider>> linkedProviders() =>
      caller.callServerEndpoint<List<_i3.LinkedProvider>>(
        'account',
        'linkedProviders',
        {},
      );

  /// Adds an email and password to the caller's account.
  ///
  /// The `authUserId` stays the same, so all their lists stay theirs.
  _i2.Future<List<_i3.LinkedProvider>> linkEmail(
    String email,
    String password,
  ) => caller.callServerEndpoint<List<_i3.LinkedProvider>>(
    'account',
    'linkEmail',
    {
      'email': email,
      'password': password,
    },
  );
}

/// Endpoint for anonymous login.
///
/// Users get an account on first launch, without a signup form. Later they
/// can link email or Google to the same `authUserId` (decisions.md #6).
/// Every endpoint requires login, so without this the app couldn't call
/// anything.
///
/// Just extending the base class is enough to make it available.
/// {@category Endpoint}
class EndpointAnonymousIdp extends _i4.EndpointAnonymousIdpBase {
  EndpointAnonymousIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'anonymousIdp';

  /// Creates a new anonymous account and returns its session.
  ///
  /// Invokes the [AnonymousIdp.beforeAnonymousAccount] callback if configured,
  /// which may prevent account creation if the endpoint is protected.
  @override
  _i2.Future<_i5.AuthSuccess> login({String? token}) =>
      caller.callServerEndpoint<_i5.AuthSuccess>(
        'anonymousIdp',
        'login',
        {'token': token},
      );
}

/// Endpoint for email login. Extending [EmailIdpBaseEndpoint] is enough to
/// make it available.
///
/// The methods that take a password are overridden only to normalize it
/// (`AuthUser.normalizePassword`) before Serverpod hashes or compares it.
/// `linkEmail` stores passwords normalized, so every path has to: a login
/// that skipped this would fail for someone whose keyboard types "é"
/// differently from the one they signed up on.
/// {@category Endpoint}
class EndpointEmailIdp extends _i4.EndpointEmailIdpBase {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// {@macro email_account_base_endpoint.login}
  @override
  _i2.Future<_i5.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// {@macro email_account_base_endpoint.finish_registration}
  @override
  _i2.Future<_i5.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// {@macro email_account_base_endpoint.finish_password_reset}
  @override
  _i2.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i2.Future<_i1.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i2.Future<String> verifyRegistrationCode({
    required _i1.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i2.Future<_i1.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i2.Future<String> verifyPasswordResetCode({
    required _i1.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// Endpoint to refresh login tokens. The app uses it automatically.
/// Just extending [RefreshJwtTokensEndpoint] is enough.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i5.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i5.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i5.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Endpoint for items on a list: read, add, save, delete.
/// {@category Endpoint}
class EndpointItem extends _i1.EndpointRef {
  EndpointItem(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'item';

  /// All items on a list (the caller must be a member).
  _i2.Future<List<_i6.ShoppingItem>> byList(_i1.UuidValue listId) =>
      caller.callServerEndpoint<List<_i6.ShoppingItem>>(
        'item',
        'byList',
        {'listId': listId},
      );

  /// Adds an item to a list (the caller must be a member).
  ///
  /// [quantity] is nullable instead of having a default value, because
  /// Serverpod's generated client ignores defaults and makes every
  /// non-null parameter required. So the default is applied here.
  _i2.Future<_i6.ShoppingItem> add(
    _i1.UuidValue listId,
    String name, {
    int? quantity,
    _i1.UuidValue? shopId,
    String? noteText,
  }) => caller.callServerEndpoint<_i6.ShoppingItem>(
    'item',
    'add',
    {
      'listId': listId,
      'name': name,
      'quantity': quantity,
      'shopId': shopId,
      'noteText': noteText,
    },
  );

  /// Saves an item. Fails with a conflict if someone else changed it first.
  _i2.Future<_i6.ShoppingItem> save(_i6.ShoppingItem item) =>
      caller.callServerEndpoint<_i6.ShoppingItem>(
        'item',
        'save',
        {'item': item},
      );

  /// Deletes an item.
  _i2.Future<void> remove(_i1.UuidValue itemId) =>
      caller.callServerEndpoint<void>(
        'item',
        'remove',
        {'itemId': itemId},
      );

  /// Deletes all checked items on the list. Returns how many.
  _i2.Future<int> clearChecked(_i1.UuidValue listId) =>
      caller.callServerEndpoint<int>(
        'item',
        'clearChecked',
        {'listId': listId},
      );

  /// Deletes the selected items (all at once). Returns how many.
  _i2.Future<int> removeMany(
    _i1.UuidValue listId,
    List<_i1.UuidValue> itemIds,
  ) => caller.callServerEndpoint<int>(
    'item',
    'removeMany',
    {
      'listId': listId,
      'itemIds': itemIds,
    },
  );

  /// Moves [itemIds] to [shopId] (null = no shop), all at once. Returns how
  /// many.
  _i2.Future<int> moveMany(
    _i1.UuidValue listId,
    List<_i1.UuidValue> itemIds,
    _i1.UuidValue? shopId,
  ) => caller.callServerEndpoint<int>(
    'item',
    'moveMany',
    {
      'listId': listId,
      'itemIds': itemIds,
      'shopId': shopId,
    },
  );

  /// Name suggestions for a list that match [query], newest first.
  _i2.Future<List<String>> suggestNames(
    _i1.UuidValue listId,
    String query,
  ) => caller.callServerEndpoint<List<String>>(
    'item',
    'suggestNames',
    {
      'listId': listId,
      'query': query,
    },
  );

  /// Every item name ever used on a list, newest first ("Recently bought").
  _i2.Future<List<_i7.ItemNameHistory>> recentNames(_i1.UuidValue listId) =>
      caller.callServerEndpoint<List<_i7.ItemNameHistory>>(
        'item',
        'recentNames',
        {'listId': listId},
      );

  /// Live updates to a list's items.
  ///
  /// Sends only what changed (not the whole list); the app applies it.
  /// Membership is checked when the stream starts, and again for every
  /// change: the stream ends once the caller is no longer on the list. It
  /// also stops if the session ends.
  ///
  /// This is for live updates while the app is open, not push
  /// notifications (those are for a closed app).
  _i2.Stream<_i8.ItemChange> watchList(_i1.UuidValue listId) => caller
      .callStreamingServerEndpoint<_i2.Stream<_i8.ItemChange>, _i8.ItemChange>(
        'item',
        'watchList',
        {'listId': listId},
        {},
      );
}

/// Endpoint for shopping lists: create, read, join, rename, leave, delete.
///
/// Kept small: each method gets the user and calls [ListService], where the
/// rules are.
/// {@category Endpoint}
class EndpointList extends _i1.EndpointRef {
  EndpointList(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'list';

  /// Every list the caller belongs to.
  _i2.Future<List<_i9.ShoppingList>> myLists() =>
      caller.callServerEndpoint<List<_i9.ShoppingList>>(
        'list',
        'myLists',
        {},
      );

  /// One list the caller belongs to.
  _i2.Future<_i9.ShoppingList> byId(_i1.UuidValue listId) =>
      caller.callServerEndpoint<_i9.ShoppingList>(
        'list',
        'byId',
        {'listId': listId},
      );

  /// Item counts for the caller's lists in [listIds] (for the drawer).
  _i2.Future<List<_i10.ListSummary>> summaries(List<_i1.UuidValue> listIds) =>
      caller.callServerEndpoint<List<_i10.ListSummary>>(
        'list',
        'summaries',
        {'listIds': listIds},
      );

  /// Creates a list owned by the caller.
  _i2.Future<_i9.ShoppingList> create(String name) =>
      caller.callServerEndpoint<_i9.ShoppingList>(
        'list',
        'create',
        {'name': name},
      );

  /// Joins the list matching [joinCode].
  _i2.Future<_i9.ShoppingList> join(String joinCode) =>
      caller.callServerEndpoint<_i9.ShoppingList>(
        'list',
        'join',
        {'joinCode': joinCode},
      );

  /// Renames a list the caller owns.
  _i2.Future<_i9.ShoppingList> rename(
    _i1.UuidValue listId,
    String name,
  ) => caller.callServerEndpoint<_i9.ShoppingList>(
    'list',
    'rename',
    {
      'listId': listId,
      'name': name,
    },
  );

  /// Sets whether a list removes checked items automatically when
  /// everything is checked.
  _i2.Future<_i9.ShoppingList> setClearCheckedAfterShopping(
    _i1.UuidValue listId,
    bool value,
  ) => caller.callServerEndpoint<_i9.ShoppingList>(
    'list',
    'setClearCheckedAfterShopping',
    {
      'listId': listId,
      'value': value,
    },
  );

  /// Removes the caller from a list.
  _i2.Future<void> leave(_i1.UuidValue listId) =>
      caller.callServerEndpoint<void>(
        'list',
        'leave',
        {'listId': listId},
      );

  /// Deletes a list the caller owns, for everyone on it.
  _i2.Future<void> delete(_i1.UuidValue listId) =>
      caller.callServerEndpoint<void>(
        'list',
        'delete',
        {'listId': listId},
      );

  /// Removes another member from a list the caller owns.
  _i2.Future<void> removeMember(
    _i1.UuidValue listId,
    _i1.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'list',
    'removeMember',
    {
      'listId': listId,
      'userId': userId,
    },
  );

  /// Hands ownership of a list the caller owns to another member.
  _i2.Future<_i9.ShoppingList> transferOwnership(
    _i1.UuidValue listId,
    _i1.UuidValue userId,
  ) => caller.callServerEndpoint<_i9.ShoppingList>(
    'list',
    'transferOwnership',
    {
      'listId': listId,
      'userId': userId,
    },
  );

  /// Live updates to a list (its name and members).
  ///
  /// Sends the whole [ShoppingList] each time (it's one small row). This is
  /// for live updates while the app is open, not push notifications.
  _i2.Stream<_i9.ShoppingList> watchList(_i1.UuidValue listId) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i9.ShoppingList>,
        _i9.ShoppingList
      >(
        'list',
        'watchList',
        {'listId': listId},
        {},
      );
}

/// Endpoint for registering phones for push, and notification settings.
/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Registers this phone to get push notifications for the caller.
  ///
  /// Safe to call again: an existing token is moved to the caller (no
  /// duplicate). So if someone else logs in on the phone, the previous
  /// user stops getting notifications there.
  _i2.Future<_i11.DeviceToken> registerDevice(
    String token,
    _i12.DevicePlatform platform,
  ) => caller.callServerEndpoint<_i11.DeviceToken>(
    'notification',
    'registerDevice',
    {
      'token': token,
      'platform': platform,
    },
  );

  /// Stops push notifications to this phone. Called on sign-out.
  _i2.Future<void> unregisterDevice(String token) =>
      caller.callServerEndpoint<void>(
        'notification',
        'unregisterDevice',
        {'token': token},
      );

  /// Mutes or unmutes a list for the caller.
  _i2.Future<void> setListMuted(
    _i1.UuidValue listId,
    bool muted,
  ) => caller.callServerEndpoint<void>(
    'notification',
    'setListMuted',
    {
      'listId': listId,
      'muted': muted,
    },
  );

  /// Whether the caller has muted [listId].
  _i2.Future<bool> isListMuted(_i1.UuidValue listId) =>
      caller.callServerEndpoint<bool>(
        'notification',
        'isListMuted',
        {'listId': listId},
      );

  /// The caller's notification preferences (decisions.md #80).
  _i2.Future<_i13.NotificationPreferences> preferences() =>
      caller.callServerEndpoint<_i13.NotificationPreferences>(
        'notification',
        'preferences',
        {},
      );

  /// Sets whether the caller is notified when someone adds an item.
  _i2.Future<_i13.NotificationPreferences> setItemAddedEnabled(bool value) =>
      caller.callServerEndpoint<_i13.NotificationPreferences>(
        'notification',
        'setItemAddedEnabled',
        {'value': value},
      );

  /// Sets whether the caller is notified when someone joins a list.
  _i2.Future<_i13.NotificationPreferences> setMemberJoinedEnabled(bool value) =>
      caller.callServerEndpoint<_i13.NotificationPreferences>(
        'notification',
        'setMemberJoinedEnabled',
        {'value': value},
      );

  /// Sets whether the caller is notified when a list is finished.
  _i2.Future<_i13.NotificationPreferences> setListFinishedEnabled(bool value) =>
      caller.callServerEndpoint<_i13.NotificationPreferences>(
        'notification',
        'setListFinishedEnabled',
        {'value': value},
      );
}

/// Endpoint for the user's own profile.
/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// Who the caller is.
  ///
  /// The app can't know its own user id otherwise (the server creates it).
  /// It needs it to show "you checked this" before the server answers.
  _i2.Future<_i14.CurrentUser> me() =>
      caller.callServerEndpoint<_i14.CurrentUser>(
        'profile',
        'me',
        {},
      );

  /// The caller's name, or a placeholder if not set.
  _i2.Future<String> displayName() => caller.callServerEndpoint<String>(
    'profile',
    'displayName',
    {},
  );

  /// Sets the caller's display name.
  _i2.Future<_i15.MemberProfile> setDisplayName(String displayName) =>
      caller.callServerEndpoint<_i15.MemberProfile>(
        'profile',
        'setDisplayName',
        {'displayName': displayName},
      );

  /// Sets the caller's avatar colour.
  _i2.Future<_i15.MemberProfile> setAvatarColor(int avatarColorArgb) =>
      caller.callServerEndpoint<_i15.MemberProfile>(
        'profile',
        'setAvatarColor',
        {'avatarColorArgb': avatarColorArgb},
      );

  /// Uploads the caller's avatar photo.
  _i2.Future<_i15.MemberProfile> setAvatarPhoto(_i16.ByteData bytes) =>
      caller.callServerEndpoint<_i15.MemberProfile>(
        'profile',
        'setAvatarPhoto',
        {'bytes': bytes},
      );

  /// Removes the caller's avatar photo.
  _i2.Future<_i15.MemberProfile?> clearAvatarPhoto() =>
      caller.callServerEndpoint<_i15.MemberProfile?>(
        'profile',
        'clearAvatarPhoto',
        {},
      );
}

/// Endpoint for a list's shops.
/// {@category Endpoint}
class EndpointShop extends _i1.EndpointRef {
  EndpointShop(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'shop';

  /// All shops on a list (the caller must be a member).
  _i2.Future<List<_i17.Shop>> byList(_i1.UuidValue listId) =>
      caller.callServerEndpoint<List<_i17.Shop>>(
        'shop',
        'byList',
        {'listId': listId},
      );

  /// Creates a shop on a list (the caller must be a member).
  _i2.Future<_i17.Shop> create(
    _i1.UuidValue listId,
    String name,
    int colorArgb,
  ) => caller.callServerEndpoint<_i17.Shop>(
    'shop',
    'create',
    {
      'listId': listId,
      'name': name,
      'colorArgb': colorArgb,
    },
  );

  /// Saves changes to a shop.
  _i2.Future<_i17.Shop> save(_i17.Shop shop) =>
      caller.callServerEndpoint<_i17.Shop>(
        'shop',
        'save',
        {'shop': shop},
      );

  /// How many items a shop has.
  _i2.Future<int> itemCount(_i1.UuidValue shopId) =>
      caller.callServerEndpoint<int>(
        'shop',
        'itemCount',
        {'shopId': shopId},
      );

  /// Deletes a shop. [disposition] says what happens to its items.
  ///
  /// [disposition] has no default on purpose: the user must decide what
  /// happens to the items.
  _i2.Future<void> remove(
    _i1.UuidValue shopId,
    _i18.ShopItemDisposition disposition,
    _i1.UuidValue? moveToShopId,
  ) => caller.callServerEndpoint<void>(
    'shop',
    'remove',
    {
      'shopId': shopId,
      'disposition': disposition,
      'moveToShopId': moveToShopId,
    },
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i4.Caller(client);
    serverpod_auth_core = _i5.Caller(client);
  }

  late final _i4.Caller serverpod_auth_idp;

  late final _i5.Caller serverpod_auth_core;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i19.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    account = EndpointAccount(this);
    anonymousIdp = EndpointAnonymousIdp(this);
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    item = EndpointItem(this);
    list = EndpointList(this);
    notification = EndpointNotification(this);
    profile = EndpointProfile(this);
    shop = EndpointShop(this);
    modules = Modules(this);
  }

  late final EndpointAccount account;

  late final EndpointAnonymousIdp anonymousIdp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointItem item;

  late final EndpointList list;

  late final EndpointNotification notification;

  late final EndpointProfile profile;

  late final EndpointShop shop;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'account': account,
    'anonymousIdp': anonymousIdp,
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'item': item,
    'list': list,
    'notification': notification,
    'profile': profile,
    'shop': shop,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
