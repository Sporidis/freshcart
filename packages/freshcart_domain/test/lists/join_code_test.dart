import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

void main() {
  group('JoinCode.parse', () {
    test('accepts a well-formed code', () {
      final result = JoinCode.parse('ABC23');
      expect(result.valueOrNull?.value, 'ABC23');
    });

    test('normalises case, whitespace and separators', () {
      expect(JoinCode.parse('  abc23 ').valueOrNull?.value, 'ABC23');
      expect(JoinCode.parse('AB-C23').valueOrNull?.value, 'ABC23');
    });

    test('rejects the wrong length', () {
      expect(JoinCode.parse('ABC2').failureOrNull, isA<ValidationFailure>());
      expect(JoinCode.parse('ABC234').failureOrNull, isA<ValidationFailure>());
    });

    test('rejects ambiguous characters that are not in the alphabet', () {
      // I, O, 0 and 1 are excluded so a code read aloud is unambiguous.
      for (final ambiguous in ['ABCI4', 'ABCO4', 'ABC04', 'ABC14']) {
        expect(
          JoinCode.parse(ambiguous).failureOrNull,
          isA<ValidationFailure>(),
          reason: '$ambiguous should be rejected',
        );
      }
    });

    test('the alphabet itself contains no ambiguous characters', () {
      for (final banned in ['I', 'O', '0', '1']) {
        expect(JoinCode.alphabet.contains(banned), isFalse);
      }
    });
  });
}
