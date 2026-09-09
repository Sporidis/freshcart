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

/// Thrown when the caller is authenticated but does not belong to the list they
/// are trying to read or change.
abstract class NotAMemberException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  NotAMemberException._();

  factory NotAMemberException() = _NotAMemberExceptionImpl;

  factory NotAMemberException.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotAMemberException();
  }

  /// Returns a shallow copy of this [NotAMemberException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotAMemberException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'NotAMemberException'};
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {'__className__': 'NotAMemberException'};
  }

  @override
  String toString() {
    return 'NotAMemberException';
  }
}

class _NotAMemberExceptionImpl extends NotAMemberException {
  _NotAMemberExceptionImpl() : super._();

  /// Returns a shallow copy of this [NotAMemberException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotAMemberException copyWith() {
    return NotAMemberException();
  }
}
