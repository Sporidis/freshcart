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
import 'package:freshcart_client/src/protocol/items/models/item_change.dart'
    as _i7;
import 'package:freshcart_client/src/protocol/lists/models/shopping_list.dart'
    as _i8;
import 'package:freshcart_client/src/protocol/notifications/models/device_token.dart'
    as _i9;
import 'package:freshcart_client/src/protocol/notifications/models/device_platform.dart'
    as _i10;
import 'package:freshcart_client/src/protocol/shops/models/shop.dart' as _i11;
import 'package:freshcart_client/src/protocol/users/models/current_user.dart'
    as _i12;
import 'package:freshcart_client/src/protocol/users/models/member_profile.dart'
    as _i13;
import 'protocol.dart' as _i14;

/// Upgrading an anonymous account by attaching credentials to it.
/// {@category Endpoint}
class EndpointAccount extends _i1.EndpointRef {
  EndpointAccount(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  /// Which providers are attached to the caller's account.
  _i2.Future<List<_i3.LinkedProvider>> linkedProviders() =>
      caller.callServerEndpoint<List<_i3.LinkedProvider>>(
        'account',
        'linkedProviders',
        {},
      );

  /// Attaches an email/password credential to the caller's existing account.
  ///
  /// The caller keeps the same `authUserId`, so nothing they created moves.
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

/// Exposes the anonymous identity provider to clients.
///
/// FreshCart is anonymous-first: a user gets a stable `authUserId` on first
/// launch with no signup form, and Google/email are *linked* to that same id
/// later (`docs/decisions.md` #6). Every endpoint sets `requireLogin`, so
/// without this the app could not call anything at all.
///
/// Extending the base endpoint is what publishes it — the Flutter side looks
/// the endpoint up by type and fails loudly if a server has not exposed it.
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

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i4.EndpointEmailIdpBase {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
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

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
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

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
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

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
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

/// The items on a list: read, add, save, remove.
/// {@category Endpoint}
class EndpointItem extends _i1.EndpointRef {
  EndpointItem(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'item';

  /// Every item on a list the caller belongs to.
  _i2.Future<List<_i6.ShoppingItem>> byList(_i1.UuidValue listId) =>
      caller.callServerEndpoint<List<_i6.ShoppingItem>>(
        'item',
        'byList',
        {'listId': listId},
      );

  /// Adds an item to a list the caller belongs to.
  ///
  /// [quantity] is nullable rather than defaulted because Serverpod's generator
  /// drops Dart default values and emits any non-nullable named parameter as
  /// `required`. Nullability is what makes a parameter optional in the
  /// generated client, so the default lives here instead.
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

  /// Writes an item back, rejecting the write on an optimistic-concurrency
  /// clash.
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

  /// Live changes to a list's items.
  ///
  /// Emits a delta per change rather than the whole list — subscribers keep the
  /// merged state themselves. Membership is checked once, when the stream
  /// opens; the stream closes if the session ends.
  ///
  /// This is the in-app half of the two-layer story: it keeps open clients live
  /// and is unrelated to FCM background push, which covers closed apps.
  _i2.Stream<_i7.ItemChange> watchList(_i1.UuidValue listId) => caller
      .callStreamingServerEndpoint<_i2.Stream<_i7.ItemChange>, _i7.ItemChange>(
        'item',
        'watchList',
        {'listId': listId},
        {},
      );
}

/// Shopping lists: create, read, join, rename, leave.
///
/// Thin by design — every method resolves the caller and hands straight off to
/// [ListService], which is where the rules and the transactions live.
/// {@category Endpoint}
class EndpointList extends _i1.EndpointRef {
  EndpointList(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'list';

  /// Every list the caller belongs to.
  _i2.Future<List<_i8.ShoppingList>> myLists() =>
      caller.callServerEndpoint<List<_i8.ShoppingList>>(
        'list',
        'myLists',
        {},
      );

  /// One list the caller belongs to.
  _i2.Future<_i8.ShoppingList> byId(_i1.UuidValue listId) =>
      caller.callServerEndpoint<_i8.ShoppingList>(
        'list',
        'byId',
        {'listId': listId},
      );

  /// Creates a list owned by the caller.
  _i2.Future<_i8.ShoppingList> create(String name) =>
      caller.callServerEndpoint<_i8.ShoppingList>(
        'list',
        'create',
        {'name': name},
      );

  /// Joins the list matching [joinCode].
  _i2.Future<_i8.ShoppingList> join(String joinCode) =>
      caller.callServerEndpoint<_i8.ShoppingList>(
        'list',
        'join',
        {'joinCode': joinCode},
      );

  /// Renames a list the caller owns.
  _i2.Future<_i8.ShoppingList> rename(
    _i1.UuidValue listId,
    String name,
  ) => caller.callServerEndpoint<_i8.ShoppingList>(
    'list',
    'rename',
    {
      'listId': listId,
      'name': name,
    },
  );

  /// Removes the caller from a list.
  _i2.Future<void> leave(_i1.UuidValue listId) =>
      caller.callServerEndpoint<void>(
        'list',
        'leave',
        {'listId': listId},
      );
}

/// Device registration and per-list notification settings.
/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Registers this device to receive pushes for the caller.
  ///
  /// Idempotent: re-registering an existing token re-points it at the caller
  /// rather than inserting a duplicate, so a shared device that changes hands
  /// does not keep notifying the previous user.
  _i2.Future<_i9.DeviceToken> registerDevice(
    String token,
    _i10.DevicePlatform platform,
  ) => caller.callServerEndpoint<_i9.DeviceToken>(
    'notification',
    'registerDevice',
    {
      'token': token,
      'platform': platform,
    },
  );

  /// Stops pushes to this device. Called on sign-out.
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
}

/// The shops belonging to a list.
/// {@category Endpoint}
class EndpointShop extends _i1.EndpointRef {
  EndpointShop(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'shop';

  /// Every shop on a list the caller belongs to.
  _i2.Future<List<_i11.Shop>> byList(_i1.UuidValue listId) =>
      caller.callServerEndpoint<List<_i11.Shop>>(
        'shop',
        'byList',
        {'listId': listId},
      );

  /// Creates a shop on a list the caller belongs to.
  _i2.Future<_i11.Shop> create(
    _i1.UuidValue listId,
    String name,
    int colorArgb,
  ) => caller.callServerEndpoint<_i11.Shop>(
    'shop',
    'create',
    {
      'listId': listId,
      'name': name,
      'colorArgb': colorArgb,
    },
  );

  /// Writes a shop back.
  _i2.Future<_i11.Shop> save(_i11.Shop shop) =>
      caller.callServerEndpoint<_i11.Shop>(
        'shop',
        'save',
        {'shop': shop},
      );

  /// Deletes a shop, untagging its items rather than deleting them.
  _i2.Future<void> remove(_i1.UuidValue shopId) =>
      caller.callServerEndpoint<void>(
        'shop',
        'remove',
        {'shopId': shopId},
      );
}

/// The caller's own FreshCart profile.
/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// Who the caller is.
  ///
  /// The client cannot know its own auth user id any other way — it is minted
  /// server-side — and needs it to render optimistic updates that attribute a
  /// change to the right person.
  _i2.Future<_i12.CurrentUser> me() =>
      caller.callServerEndpoint<_i12.CurrentUser>(
        'profile',
        'me',
        {},
      );

  /// The caller's display name, falling back to a placeholder.
  _i2.Future<String> displayName() => caller.callServerEndpoint<String>(
    'profile',
    'displayName',
    {},
  );

  /// Sets the caller's display name.
  _i2.Future<_i13.MemberProfile> setDisplayName(String displayName) =>
      caller.callServerEndpoint<_i13.MemberProfile>(
        'profile',
        'setDisplayName',
        {'displayName': displayName},
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
         _i14.Protocol(),
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
    shop = EndpointShop(this);
    profile = EndpointProfile(this);
    modules = Modules(this);
  }

  late final EndpointAccount account;

  late final EndpointAnonymousIdp anonymousIdp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointItem item;

  late final EndpointList list;

  late final EndpointNotification notification;

  late final EndpointShop shop;

  late final EndpointProfile profile;

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
    'shop': shop,
    'profile': profile,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
