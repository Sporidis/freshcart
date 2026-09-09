import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('maps the server-declared exceptions to their domain meaning', () {
      expect(
        mapExceptionToFailure(dto.ListNotFoundException()),
        const Failure.notFound(),
      );
      expect(
        mapExceptionToFailure(dto.ItemNotFoundException()),
        const Failure.notFound(),
      );
      expect(
        mapExceptionToFailure(dto.NotAMemberException()),
        const Failure.unauthorized(),
      );
      expect(
        mapExceptionToFailure(dto.EditConflictException()),
        const Failure.conflict(),
      );
      expect(
        mapExceptionToFailure(dto.InvalidJoinCodeException()),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'joinCode'),
      );
    });

    test('maps transport-level errors', () {
      expect(
        mapExceptionToFailure(dto.ServerpodClientUnauthorized()),
        const Failure.unauthorized(),
      );
      expect(
        mapExceptionToFailure(dto.ServerpodClientForbidden()),
        const Failure.unauthorized(),
      );
      expect(
        mapExceptionToFailure(dto.ServerpodClientNotFound()),
        const Failure.notFound(),
      );
      expect(
        mapExceptionToFailure(
          dto.ServerpodClientInternalServerError(),
        ),
        isA<NetworkFailure>(),
      );
    });

    test('anything unrecognised becomes unexpected, keeping its cause', () {
      final cause = ArgumentError('nope');
      expect(
        mapExceptionToFailure(cause),
        isA<UnexpectedFailure>().having((f) => f.cause, 'cause', cause),
      );
    });
  });
}
