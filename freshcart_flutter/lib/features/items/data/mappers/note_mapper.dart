import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.Note] into our domain [Note].
extension NoteDtoX on dto.Note {
  /// Converts to the domain [Note].
  Note toDomain() =>
      Note(text: text, authorId: UserId(authorId.uuid), updatedAt: updatedAt);
}

/// Converts a domain [Note] back into a Serverpod [dto.Note].
extension NoteX on Note {
  /// Converts to a [dto.Note].
  dto.Note toDto() => dto.Note(
    text: text,
    authorId: dto.UuidValue.withValidation(authorId.value),
    updatedAt: updatedAt,
  );
}
