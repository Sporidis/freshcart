import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/core/error/validation_messages.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

void main() {
  final t = translationsFor(AppLocale.en);

  test('a photo the server could not read says so, not a generic error', () {
    // What the server sends when AvatarPhotoSanitizer refuses an upload.
    final failure = mapExceptionToFailure(
      dto.ValidationException(kind: 'invalidFormat', input: 'avatarPhoto'),
    );

    expect(
      failure,
      const Failure.validation(
        ValidationIssue.invalidFormat(ValidatedInput.avatarPhoto),
      ),
    );
    expect(
      (failure as ValidationFailure).issue.toMessage(t),
      "That file isn't a photo we can use. Try another one.",
    );
  });
}
