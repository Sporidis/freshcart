import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';

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
      // The server ran the same domain rule, so the app gets the same
      // validation issue it would have produced itself.
      expect(
        mapExceptionToFailure(
          dto.ValidationException(
            kind: 'tooLong',
            input: 'itemName',
            limit: 80,
          ),
        ),
        const Failure.validation(
          ValidationIssue.tooLong(ValidatedInput.itemName, max: 80),
        ),
      );
      // A rule this version doesn't know (a newer server): not a crash.
      expect(
        mapExceptionToFailure(
          dto.ValidationException(kind: 'newerRule', input: 'itemName'),
        ),
        isA<UnexpectedFailure>(),
      );
      expect(
        mapExceptionToFailure(dto.InvalidJoinCodeException()),
        const Failure.validation(
          ValidationIssue.notFound(ValidatedInput.joinCode),
        ),
      );
      expect(
        mapExceptionToFailure(dto.TooManyJoinAttemptsException()),
        const Failure.rateLimited(),
      );
      // A conflict, so a stale queued "leave" is dropped, not retried.
      expect(
        mapExceptionToFailure(dto.OwnerCannotLeaveException()),
        const Failure.conflict(),
      );
    });

    test('maps the email link errors without hinting at existing accounts', () {
      Failure map(EmailAccountRequestExceptionReason reason) =>
          mapExceptionToFailure(EmailAccountRequestException(reason: reason));
      const wrongCode = Failure.validation(
        ValidationIssue.invalidFormat(ValidatedInput.verificationCode),
      );

      expect(map(EmailAccountRequestExceptionReason.invalid), wrongCode);
      expect(map(EmailAccountRequestExceptionReason.expired), wrongCode);
      expect(
        map(EmailAccountRequestExceptionReason.policyViolation),
        const Failure.validation(
          ValidationIssue.invalidFormat(ValidatedInput.email),
        ),
      );
      expect(
        map(EmailAccountRequestExceptionReason.tooManyAttempts),
        const Failure.rateLimited(),
      );
      // None of them may say "email in use": that is the enumeration the
      // server hides on purpose.
      for (final reason in EmailAccountRequestExceptionReason.values) {
        expect(
          map(reason),
          isNot(
            const Failure.validation(
              ValidationIssue.alreadyInUse(ValidatedInput.email),
            ),
          ),
        );
      }
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
