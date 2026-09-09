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

/// A bare list id, used as the payload of the notification flush future call.
abstract class ListReference
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ListReference._({required this.listId});

  factory ListReference({required _i1.UuidValue listId}) = _ListReferenceImpl;

  factory ListReference.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListReference(
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
    );
  }

  _i1.UuidValue listId;

  /// Returns a shallow copy of this [ListReference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListReference copyWith({_i1.UuidValue? listId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListReference',
      'listId': listId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListReference',
      'listId': listId.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ListReferenceImpl extends ListReference {
  _ListReferenceImpl({required _i1.UuidValue listId}) : super._(listId: listId);

  /// Returns a shallow copy of this [ListReference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListReference copyWith({_i1.UuidValue? listId}) {
    return ListReference(listId: listId ?? this.listId);
  }
}
