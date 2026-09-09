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

/// Thrown when linking a provider that is already attached to this account.
abstract class AccountAlreadyLinkedException
    implements _i1.SerializableException, _i1.SerializableModel {
  AccountAlreadyLinkedException._();

  factory AccountAlreadyLinkedException() = _AccountAlreadyLinkedExceptionImpl;

  factory AccountAlreadyLinkedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AccountAlreadyLinkedException();
  }

  /// Returns a shallow copy of this [AccountAlreadyLinkedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountAlreadyLinkedException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'AccountAlreadyLinkedException'};
  }

  @override
  String toString() {
    return 'AccountAlreadyLinkedException';
  }
}

class _AccountAlreadyLinkedExceptionImpl extends AccountAlreadyLinkedException {
  _AccountAlreadyLinkedExceptionImpl() : super._();

  /// Returns a shallow copy of this [AccountAlreadyLinkedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountAlreadyLinkedException copyWith() {
    return AccountAlreadyLinkedException();
  }
}
