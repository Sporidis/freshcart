import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';

part 'note.freezed.dart';

/// A free-text annotation on a shopping item — "the oat one, not soy".
///
/// A note has no id of its own: it is owned by exactly one [ShoppingItem] and
/// dies with it. Modelling it as a separate aggregate would buy nothing and
/// cost a join.
@freezed
abstract class Note with _$Note {
  /// Creates a note.
  const factory Note({
    required String text,
    required UserId authorId,
    required DateTime updatedAt,
  }) = _Note;

  const Note._();

  /// Whether the note has any content once trimmed.
  ///
  /// An empty note is stored as no note at all, so the UI does not render an
  /// empty annotation row.
  bool get isEmpty => text.trim().isEmpty;
}
