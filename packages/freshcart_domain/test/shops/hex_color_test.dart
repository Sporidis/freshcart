import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

void main() {
  group('HexColor.parse', () {
    test('parses a 6-digit hex as fully opaque', () {
      final color = HexColor.parse('#4CAF50').valueOrNull!;
      expect(color.alpha, 0xFF);
      expect(color.red, 0x4C);
      expect(color.green, 0xAF);
      expect(color.blue, 0x50);
    });

    test('parses with or without the leading hash, and any case', () {
      expect(
        HexColor.parse('4caf50').valueOrNull,
        HexColor.parse('#4CAF50').valueOrNull,
      );
    });

    test('parses an 8-digit hex including its alpha', () {
      expect(HexColor.parse('804CAF50').valueOrNull?.alpha, 0x80);
    });

    test('rejects malformed input with a validation failure', () {
      for (final bad in ['', '#12345', 'nothex', '#GGGGGG', '#1234567']) {
        expect(
          HexColor.parse(bad).failureOrNull,
          isA<ValidationFailure>(),
          reason: '"$bad" should be rejected',
        );
      }
    });

    test('toHex drops a fully opaque alpha and round-trips', () {
      expect(HexColor.parse('#4CAF50').valueOrNull?.toHex(), '#4CAF50');
      expect(HexColor.parse('#804CAF50').valueOrNull?.toHex(), '#804CAF50');
    });

    test('fromArgb rejects a value that does not fit in 32 bits', () {
      expect(() => HexColor.fromArgb(-1), throwsArgumentError);
      expect(() => HexColor.fromArgb(0x1FFFFFFFF), throwsArgumentError);
    });
  });
}
