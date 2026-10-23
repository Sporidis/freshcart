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

/// Thrown when input breaks a domain rule (a blank name, a quantity
/// below 1). The three fields are the domain ValidationIssue as plain
/// values (ValidationIssueWire): the app rebuilds the issue and shows it
/// in the user's language.
abstract class ValidationException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  ValidationException._({
    required this.kind,
    required this.input,
    this.limit,
  });

  factory ValidationException({
    required String kind,
    required String input,
    int? limit,
  }) = _ValidationExceptionImpl;

  factory ValidationException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ValidationException(
      kind: jsonSerialization['kind'] as String,
      input: jsonSerialization['input'] as String,
      limit: jsonSerialization['limit'] as int?,
    );
  }

  String kind;

  String input;

  int? limit;

  /// Returns a shallow copy of this [ValidationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ValidationException copyWith({
    String? kind,
    String? input,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ValidationException',
      'kind': kind,
      'input': input,
      if (limit != null) 'limit': limit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ValidationException',
      'kind': kind,
      'input': input,
      if (limit != null) 'limit': limit,
    };
  }

  @override
  String toString() {
    return 'ValidationException(kind: $kind, input: $input, limit: $limit)';
  }
}

class _Undefined {}

class _ValidationExceptionImpl extends ValidationException {
  _ValidationExceptionImpl({
    required String kind,
    required String input,
    int? limit,
  }) : super._(
         kind: kind,
         input: input,
         limit: limit,
       );

  /// Returns a shallow copy of this [ValidationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ValidationException copyWith({
    String? kind,
    String? input,
    Object? limit = _Undefined,
  }) {
    return ValidationException(
      kind: kind ?? this.kind,
      input: input ?? this.input,
      limit: limit is int? ? limit : this.limit,
    );
  }
}
