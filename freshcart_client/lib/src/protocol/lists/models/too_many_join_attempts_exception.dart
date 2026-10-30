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

/// Thrown when a user or IP address has had too many failed joins
/// recently. Says nothing about whether the code itself was right.
abstract class TooManyJoinAttemptsException
    implements _i1.SerializableException, _i1.SerializableModel {
  TooManyJoinAttemptsException._();

  factory TooManyJoinAttemptsException() = _TooManyJoinAttemptsExceptionImpl;

  factory TooManyJoinAttemptsException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TooManyJoinAttemptsException();
  }

  /// Returns a shallow copy of this [TooManyJoinAttemptsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TooManyJoinAttemptsException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'TooManyJoinAttemptsException'};
  }

  @override
  String toString() {
    return 'TooManyJoinAttemptsException';
  }
}

class _TooManyJoinAttemptsExceptionImpl extends TooManyJoinAttemptsException {
  _TooManyJoinAttemptsExceptionImpl() : super._();

  /// Returns a shallow copy of this [TooManyJoinAttemptsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TooManyJoinAttemptsException copyWith() {
    return TooManyJoinAttemptsException();
  }
}
