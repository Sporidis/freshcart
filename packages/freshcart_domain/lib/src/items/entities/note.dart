import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';

part 'note.freezed.dart';

/// A short note on an item, like "the oat one, not soy".
///
/// No id of its own: it belongs to one [ShoppingItem] and is deleted with
/// it. A separate table would only add complexity.
@freezed
abstract class Note with _$Note {
  /// Creates a note.
  const factory Note({
    required String text,
    required UserId authorId,
    required DateTime updatedAt,
  }) = _Note;

  const Note._();

  /// Whether the note has any text (ignoring spaces). An empty note is
  /// saved as no note, so no empty row is shown.
  bool get isEmpty => text.trim().isEmpty;
}
