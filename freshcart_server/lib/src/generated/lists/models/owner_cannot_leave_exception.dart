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

/// Thrown when the owner of a list tries to leave it: a list must always
/// have an owner who is on it. The owner hands it over first
/// (transferOwnership) or deletes it.
abstract class OwnerCannotLeaveException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  OwnerCannotLeaveException._();

  factory OwnerCannotLeaveException() = _OwnerCannotLeaveExceptionImpl;

  factory OwnerCannotLeaveException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OwnerCannotLeaveException();
  }

  /// Returns a shallow copy of this [OwnerCannotLeaveException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnerCannotLeaveException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'OwnerCannotLeaveException'};
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {'__className__': 'OwnerCannotLeaveException'};
  }

  @override
  String toString() {
    return 'OwnerCannotLeaveException';
  }
}

class _OwnerCannotLeaveExceptionImpl extends OwnerCannotLeaveException {
  _OwnerCannotLeaveExceptionImpl() : super._();

  /// Returns a shallow copy of this [OwnerCannotLeaveException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnerCannotLeaveException copyWith() {
    return OwnerCannotLeaveException();
  }
}
