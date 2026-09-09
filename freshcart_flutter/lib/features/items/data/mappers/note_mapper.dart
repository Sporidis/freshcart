import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.Note] wire object to the domain entity.
extension NoteDtoX on dto.Note {
  /// Converts to the domain [Note].
  Note toDomain() =>
      Note(text: text, authorId: UserId(authorId.uuid), updatedAt: updatedAt);
}

/// Maps a domain [Note] back to the wire object.
extension NoteX on Note {
  /// Converts to a [dto.Note].
  dto.Note toDto() => dto.Note(
    text: text,
    authorId: dto.UuidValue.withValidation(authorId.value),
    updatedAt: updatedAt,
  );
}
