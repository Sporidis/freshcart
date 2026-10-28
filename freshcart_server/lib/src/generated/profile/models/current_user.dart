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

/// Who the caller is, as the server sees them.
///
/// The client needs its own identity to render an optimistic check ("you
/// ticked this") before the server has answered. It is deliberately derived
/// from the session rather than sent by the client — identity a caller asserts
/// about itself is not identity.
abstract class CurrentUser
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CurrentUser._({
    required this.userId,
    required this.displayName,
    required this.hasProfile,
    this.avatarColorArgb,
    this.avatarPhotoUrl,
    required this.isAnonymous,
  });

  factory CurrentUser({
    required _i1.UuidValue userId,
    required String displayName,
    required bool hasProfile,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required bool isAnonymous,
  }) = _CurrentUserImpl;

  factory CurrentUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return CurrentUser(
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      displayName: jsonSerialization['displayName'] as String,
      hasProfile: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasProfile'],
      ),
      avatarColorArgb: jsonSerialization['avatarColorArgb'] as int?,
      avatarPhotoUrl: jsonSerialization['avatarPhotoUrl'] as String?,
      isAnonymous: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isAnonymous'],
      ),
    );
  }

  /// The caller's stable auth user id.
  _i1.UuidValue userId;

  /// The name collaborators see, or a placeholder if none is set yet.
  String displayName;

  /// Whether the caller has set up a profile (picked a name). False means
  /// they haven't finished onboarding yet, even if the account exists.
  bool hasProfile;

  /// A colour the caller picked for their own avatar, or `null` if they
  /// have not set one -- the client falls back to its own deterministic
  /// hash colour in that case.
  int? avatarColorArgb;

  /// The caller's avatar photo, already resolved to a public URL, or `null`
  /// if they have not set one.
  String? avatarPhotoUrl;

  /// Whether the account has any credential attached.
  ///
  /// False means an anonymous session: losing this device loses access to every
  /// shared list, which is what the upgrade nudge exists to prevent.
  bool isAnonymous;

  /// Returns a shallow copy of this [CurrentUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CurrentUser copyWith({
    _i1.UuidValue? userId,
    String? displayName,
    bool? hasProfile,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    bool? isAnonymous,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CurrentUser',
      'userId': userId.toJson(),
      'displayName': displayName,
      'hasProfile': hasProfile,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoUrl != null) 'avatarPhotoUrl': avatarPhotoUrl,
      'isAnonymous': isAnonymous,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CurrentUser',
      'userId': userId.toJson(),
      'displayName': displayName,
      'hasProfile': hasProfile,
      if (avatarColorArgb != null) 'avatarColorArgb': avatarColorArgb,
      if (avatarPhotoUrl != null) 'avatarPhotoUrl': avatarPhotoUrl,
      'isAnonymous': isAnonymous,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CurrentUserImpl extends CurrentUser {
  _CurrentUserImpl({
    required _i1.UuidValue userId,
    required String displayName,
    required bool hasProfile,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
    required bool isAnonymous,
  }) : super._(
         userId: userId,
         displayName: displayName,
         hasProfile: hasProfile,
         avatarColorArgb: avatarColorArgb,
         avatarPhotoUrl: avatarPhotoUrl,
         isAnonymous: isAnonymous,
       );

  /// Returns a shallow copy of this [CurrentUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CurrentUser copyWith({
    _i1.UuidValue? userId,
    String? displayName,
    bool? hasProfile,
    Object? avatarColorArgb = _Undefined,
    Object? avatarPhotoUrl = _Undefined,
    bool? isAnonymous,
  }) {
    return CurrentUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      hasProfile: hasProfile ?? this.hasProfile,
      avatarColorArgb: avatarColorArgb is int?
          ? avatarColorArgb
          : this.avatarColorArgb,
      avatarPhotoUrl: avatarPhotoUrl is String?
          ? avatarPhotoUrl
          : this.avatarPhotoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
