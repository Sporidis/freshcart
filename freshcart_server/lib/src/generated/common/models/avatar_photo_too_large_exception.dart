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

/// Thrown when an uploaded avatar photo exceeds the server's own size cap.
///
/// The client is expected to have already downsized the image before
/// upload; this is the backstop for a client that skipped that step, not
/// the size a well-behaved upload is expected to reach.
abstract class AvatarPhotoTooLargeException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  AvatarPhotoTooLargeException._();

  factory AvatarPhotoTooLargeException() = _AvatarPhotoTooLargeExceptionImpl;

  factory AvatarPhotoTooLargeException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AvatarPhotoTooLargeException();
  }

  /// Returns a shallow copy of this [AvatarPhotoTooLargeException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AvatarPhotoTooLargeException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'AvatarPhotoTooLargeException'};
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {'__className__': 'AvatarPhotoTooLargeException'};
  }

  @override
  String toString() {
    return 'AvatarPhotoTooLargeException';
  }
}

class _AvatarPhotoTooLargeExceptionImpl extends AvatarPhotoTooLargeException {
  _AvatarPhotoTooLargeExceptionImpl() : super._();

  /// Returns a shallow copy of this [AvatarPhotoTooLargeException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AvatarPhotoTooLargeException copyWith() {
    return AvatarPhotoTooLargeException();
  }
}
