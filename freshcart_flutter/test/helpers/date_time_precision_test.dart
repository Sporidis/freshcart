import 'package:flutter_test/flutter_test.dart';

import 'date_time_precision.dart';

void main() {
  group('DateTime.truncatedToSeconds', () {
    test('drops milliseconds and microseconds', () {
      final value = DateTime(2024, 6, 6, 14, 30, 52, 918, 982);

      expect(
        value.truncatedToSeconds,
        DateTime(2024, 6, 6, 14, 30, 52),
      );
    });

    test('preserves a value that already has no sub-second part', () {
      final value = DateTime(2024, 6, 6, 14, 30, 52);

      expect(value.truncatedToSeconds, value);
    });

    test('preserves isUtc', () {
      final value = DateTime.utc(2024, 6, 6, 14, 30, 52, 918);

      final truncated = value.truncatedToSeconds;

      expect(truncated.isUtc, isTrue);
      expect(truncated, DateTime.utc(2024, 6, 6, 14, 30, 52));
    });

    test('does not shift a local value to UTC', () {
      final value = DateTime(2024, 6, 6, 14, 30, 52, 918);

      expect(value.truncatedToSeconds.isUtc, isFalse);
    });
  });
}
