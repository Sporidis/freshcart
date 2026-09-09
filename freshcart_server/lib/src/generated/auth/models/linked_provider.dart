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

/// An identity provider attached to an account.
enum LinkedProvider implements _i1.SerializableModel {
  /// The account was created anonymously and has no recoverable credential.
  anonymous,

  /// Email and password.
  email,

  /// Google sign-in.
  google;

  static LinkedProvider fromJson(String name) {
    switch (name) {
      case 'anonymous':
        return LinkedProvider.anonymous;
      case 'email':
        return LinkedProvider.email;
      case 'google':
        return LinkedProvider.google;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LinkedProvider"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
