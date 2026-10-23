import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';

void main() {
  test('the first letter, uppercased, ignoring surrounding space', () {
    expect(initialFor('  nikolaos '), 'N');
  });

  test('a blank name has a placeholder, not a crash', () {
    expect(initialFor(''), '?');
    expect(initialFor('   '), '?');
  });

  test('an emoji comes through whole, not as half a surrogate pair', () {
    expect(initialFor('🍕 Pizza night'), '🍕');
  });

  test('a decomposed accent stays attached to its letter', () {
    // "e" + COMBINING ACUTE ACCENT: two code units, one character.
    expect(initialFor('élodie'), 'É');
  });
}
