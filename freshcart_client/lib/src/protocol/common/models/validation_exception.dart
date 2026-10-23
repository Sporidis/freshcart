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

/// Thrown when input breaks a domain rule (a blank name, a quantity
/// below 1). [field] and [message] are the domain Failure's, so the app
/// shows the same text it would have checked for itself.
abstract class ValidationException
    implements _i1.SerializableException, _i1.SerializableModel {
  ValidationException._({
    required this.field,
    required this.message,
  });

  factory ValidationException({
    required String field,
    required String message,
  }) = _ValidationExceptionImpl;

  factory ValidationException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ValidationException(
      field: jsonSerialization['field'] as String,
      message: jsonSerialization['message'] as String,
    );
  }

  String field;

  String message;

  /// Returns a shallow copy of this [ValidationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ValidationException copyWith({
    String? field,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ValidationException',
      'field': field,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ValidationException(field: $field, message: $message)';
  }
}

class _ValidationExceptionImpl extends ValidationException {
  _ValidationExceptionImpl({
    required String field,
    required String message,
  }) : super._(
         field: field,
         message: message,
       );

  /// Returns a shallow copy of this [ValidationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ValidationException copyWith({
    String? field,
    String? message,
  }) {
    return ValidationException(
      field: field ?? this.field,
      message: message ?? this.message,
    );
  }
}
