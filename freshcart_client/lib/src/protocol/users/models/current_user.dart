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

/// Who the caller is, as the server sees them.
///
/// The client needs its own identity to render an optimistic check ("you
/// ticked this") before the server has answered. It is deliberately derived
/// from the session rather than sent by the client — identity a caller asserts
/// about itself is not identity.
abstract class CurrentUser implements _i1.SerializableModel {
  CurrentUser._({
    required this.userId,
    required this.displayName,
  });

  factory CurrentUser({
    required _i1.UuidValue userId,
    required String displayName,
  }) = _CurrentUserImpl;

  factory CurrentUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return CurrentUser(
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      displayName: jsonSerialization['displayName'] as String,
    );
  }

  /// The caller's stable auth user id.
  _i1.UuidValue userId;

  /// The name collaborators see, or a placeholder if none is set yet.
  String displayName;

  /// Returns a shallow copy of this [CurrentUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CurrentUser copyWith({
    _i1.UuidValue? userId,
    String? displayName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CurrentUser',
      'userId': userId.toJson(),
      'displayName': displayName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CurrentUserImpl extends CurrentUser {
  _CurrentUserImpl({
    required _i1.UuidValue userId,
    required String displayName,
  }) : super._(
         userId: userId,
         displayName: displayName,
       );

  /// Returns a shallow copy of this [CurrentUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CurrentUser copyWith({
    _i1.UuidValue? userId,
    String? displayName,
  }) {
    return CurrentUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
    );
  }
}
