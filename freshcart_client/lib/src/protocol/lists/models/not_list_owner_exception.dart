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

/// Thrown when a member tries something only the list's owner may do:
/// rename or delete the list, remove a member, or hand over ownership.
abstract class NotListOwnerException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotListOwnerException._();

  factory NotListOwnerException() = _NotListOwnerExceptionImpl;

  factory NotListOwnerException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotListOwnerException();
  }

  /// Returns a shallow copy of this [NotListOwnerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotListOwnerException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'NotListOwnerException'};
  }

  @override
  String toString() {
    return 'NotListOwnerException';
  }
}

class _NotListOwnerExceptionImpl extends NotListOwnerException {
  _NotListOwnerExceptionImpl() : super._();

  /// Returns a shallow copy of this [NotListOwnerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotListOwnerException copyWith() {
    return NotListOwnerException();
  }
}
