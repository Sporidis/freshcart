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

/// A free-text annotation on a shopping item — "the oat one, not soy".
///
/// Deliberately has no `table`: a note is owned by exactly one item and dies
/// with it, so Serverpod stores it as JSON in the item's row. That matches the
/// domain, where `Note` is a value with no identity of its own, and saves a
/// join on the hottest read in the app.
abstract class Note
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Note._({
    required this.text,
    required this.authorId,
    required this.updatedAt,
  });

  factory Note({
    required String text,
    required _i1.UuidValue authorId,
    required DateTime updatedAt,
  }) = _NoteImpl;

  factory Note.fromJson(Map<String, dynamic> jsonSerialization) {
    return Note(
      text: jsonSerialization['text'] as String,
      authorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The note body.
  String text;

  /// The `authUserId` of whoever last wrote it.
  _i1.UuidValue authorId;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Note]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Note copyWith({
    String? text,
    _i1.UuidValue? authorId,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Note',
      'text': text,
      'authorId': authorId.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Note',
      'text': text,
      'authorId': authorId.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NoteImpl extends Note {
  _NoteImpl({
    required String text,
    required _i1.UuidValue authorId,
    required DateTime updatedAt,
  }) : super._(
         text: text,
         authorId: authorId,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Note]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Note copyWith({
    String? text,
    _i1.UuidValue? authorId,
    DateTime? updatedAt,
  }) {
    return Note(
      text: text ?? this.text,
      authorId: authorId ?? this.authorId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
