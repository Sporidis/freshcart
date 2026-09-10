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

  _perceptualDistance();
}

void _perceptualDistance() {
  group('HexColor.perceptualDistanceTo', () {
    test('is zero against itself', () {
      final blue = HexColor.fromArgb(0xFF2456A6);
      expect(blue.perceptualDistanceTo(blue), 0);
    });

    test('is symmetric', () {
      final a = HexColor.fromArgb(0xFF2456A6);
      final b = HexColor.fromArgb(0xFFE8791A);
      expect(
        a.perceptualDistanceTo(b),
        closeTo(b.perceptualDistanceTo(a), 1e-9),
      );
    });

    test('ignores alpha, which says nothing about how a colour looks', () {
      final opaque = HexColor.fromArgb(0xFF2456A6);
      final ghost = HexColor.fromArgb(0x102456A6);
      expect(opaque.perceptualDistanceTo(ghost), 0);
    });

    test('black against white is the far end of the range', () {
      final distance = HexColor.fromArgb(0xFF000000)
          .perceptualDistanceTo(HexColor.fromArgb(0xFFFFFFFF));
      expect(distance, greaterThan(700));
    });

    group('isCloseTo', () {
      test('the design palette is not self-confusable', () {
        // Every swatch offered in the picker must be distinguishable from
        // every other, or the warning would fire on a fresh, valid choice.
        final palette = [
          HexColor.fromArgb(0xFF2456A6), // blue
          HexColor.fromArgb(0xFFE8791A), // orange
          HexColor.fromArgb(0xFFC0392B), // red
          HexColor.fromArgb(0xFF2E9E5B), // green
          HexColor.fromArgb(0xFF8E5CD9), // purple
          HexColor.fromArgb(0xFFD9A62E), // yellow
        ];
        for (final a in palette) {
          for (final b in palette) {
            if (a == b) continue;
            expect(
              a.isCloseTo(b),
              isFalse,
              reason: '${a.toHex()} vs ${b.toHex()}',
            );
          }
        }
      });

      test('catches two blues a shopper would mix up mid-aisle', () {
        expect(
          HexColor.fromArgb(0xFF2456A6)
              .isCloseTo(HexColor.fromArgb(0xFF2A5AAA)),
          isTrue,
        );
      });
    });
  });
}
