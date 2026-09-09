import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Ok reports isOk and carries its value', () {
      const result = Ok<int>(42);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Err reports isErr and carries its failure', () {
      const result = Err<int>(Failure.notFound());
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, const Failure.notFound());
    });

    test('equality is by value, so tests can assert on whole results', () {
      expect(const Ok<int>(1), const Ok<int>(1));
      expect(const Ok<int>(1), isNot(const Ok<int>(2)));
      expect(
        const Err<int>(Failure.notFound()),
        const Err<int>(Failure.notFound()),
      );
      expect(
        const Err<int>(Failure.notFound()),
        isNot(const Err<int>(Failure.unauthorized())),
      );
    });

    test('fold collapses both branches', () {
      expect(
        const Ok<int>(2).fold(ok: (v) => 'v$v', err: (f) => 'failed'),
        'v2',
      );
      expect(
        const Err<int>(Failure.conflict()).fold(
          ok: (v) => 'v$v',
          err: (f) => 'failed',
        ),
        'failed',
      );
    });

    test('map transforms Ok and leaves Err alone', () {
      expect(const Ok<int>(2).map((v) => v * 2), const Ok<int>(4));
      expect(
        const Err<int>(Failure.conflict()).map((v) => v * 2),
        const Err<int>(Failure.conflict()),
      );
    });

    test('flatMap short-circuits on the first Err', () {
      var ran = false;
      final result = const Err<int>(Failure.notFound()).flatMap<String>((v) {
        ran = true;
        return const Ok('unreachable');
      });
      expect(ran, isFalse, reason: 'transform must not run on an Err');
      expect(result, const Err<String>(Failure.notFound()));
    });

    test('a switch over Result is exhaustive without a default', () {
      // This compiles only because Result is sealed — that is the guarantee.
      String describe(Result<int> r) => switch (r) {
        Ok<int>(:final value) => 'ok $value',
        Err<int>(:final failure) => 'err $failure',
      };
      expect(describe(const Ok(1)), 'ok 1');
      expect(describe(const Err(Failure.notFound())), startsWith('err'));
    });
  });
}
