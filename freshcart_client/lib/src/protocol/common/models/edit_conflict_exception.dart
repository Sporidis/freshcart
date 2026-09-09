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

/// Thrown when a write loses an optimistic-concurrency race: the caller sent
/// the `updatedAt` it last saw, and the stored row has moved on since.
///
/// The client rolls its optimistic edit back and re-reads.
abstract class EditConflictException
    implements _i1.SerializableException, _i1.SerializableModel {
  EditConflictException._();

  factory EditConflictException() = _EditConflictExceptionImpl;

  factory EditConflictException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EditConflictException();
  }

  /// Returns a shallow copy of this [EditConflictException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EditConflictException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'EditConflictException'};
  }

  @override
  String toString() {
    return 'EditConflictException';
  }
}

class _EditConflictExceptionImpl extends EditConflictException {
  _EditConflictExceptionImpl() : super._();

  /// Returns a shallow copy of this [EditConflictException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EditConflictException copyWith() {
    return EditConflictException();
  }
}
