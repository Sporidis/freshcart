import 'dart:async';

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
        mapExceptionToFailure(dto.ShopNotFoundException()),
        const Failure.notFound(),
      );
      expect(
        mapExceptionToFailure(dto.NotListOwnerException()),
        const Failure.unauthorized(),
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
      // The server answered, with an error it didn't handle: a bug, not
      // a connection problem, so it must not be queued for later.
      expect(
        mapExceptionToFailure(
          dto.ServerpodClientInternalServerError(),
        ),
        isA<UnexpectedFailure>(),
      );
    });

    test('network means exactly: the server could not be reached', () {
      // Serverpod's status -1: no response came back at all.
      expect(
        mapExceptionToFailure(const dto.ServerpodClientException('down', -1)),
        isA<NetworkFailure>(),
      );
      expect(
        mapExceptionToFailure(TimeoutException('slow')),
        isA<NetworkFailure>(),
      );
    });

    test(
      'maps the live-update stream\'s own exception family to network, not '
      'unexpected — it runs over a separate WebSocket from the request/'
      'response path above, so it never throws a ServerpodClientException',
      () {
        expect(
          mapExceptionToFailure(const dto.WebSocketClosedException()),
          isA<NetworkFailure>(),
        );
        expect(
          mapExceptionToFailure(const dto.ConnectionClosedException()),
          isA<NetworkFailure>(),
        );
      },
    );

    test('anything unrecognised becomes unexpected, keeping its cause', () {
      final cause = ArgumentError('nope');
      expect(
        mapExceptionToFailure(cause),
        isA<UnexpectedFailure>().having((f) => f.cause, 'cause', cause),
      );
    });
  });
}
