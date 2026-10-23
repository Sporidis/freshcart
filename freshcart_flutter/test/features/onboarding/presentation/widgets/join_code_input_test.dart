import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/join_code_input.dart';

/// [JoinCodeInput] draws five boxes but is backed by one real field — these
/// tests are about the *boxes* reading that field correctly, since the
/// field's own editing behaviour (backspace, paste, the 5-character cap) is
/// already covered end to end by `getting_in_flow_test.dart`.
void main() {
  Future<void> pump(
    WidgetTester tester,
    ValueChanged<String> onChanged, {
    String value = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JoinCodeInput(value: value, onChanged: onChanged),
        ),
      ),
    );
  }

  testWidgets('screen readers can reach the invisible field', (tester) async {
    // The field is fully transparent. If it dropped out of the semantics
    // tree with it, a screen-reader user couldn't type a code at all.
    final semantics = tester.ensureSemantics();
    await pump(tester, (_) {});

    expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsOne);
    semantics.dispose();
  });

  testWidgets('each typed character lands in its own box, left to right', (
    tester,
  ) async {
    await pump(tester, (_) {});

    await tester.enterText(find.byType(TextField), 'AB');
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('backspace clears the last box rather than leaving a gap', (
    tester,
  ) async {
    await pump(tester, (_) {}, value: 'ABC');
    await tester.pumpAndSettle();

    // Simulate backspace the same way the platform keyboard would: an
    // edit that shortens the field's own text.
    await tester.enterText(find.byType(TextField), 'AB');
    await tester.pump();

    expect(find.text('C'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('pasting a full code fills every box at once', (tester) async {
    String? reported;
    await pump(tester, (value) => reported = value);

    await tester.enterText(find.byType(TextField), '8f3k2');
    await tester.pump();

    // Uppercased, same as the field's own formatter.
    expect(reported, '8F3K2');
    for (final char in '8F3K2'.split('')) {
      expect(find.text(char), findsOneWidget);
    }
  });

  testWidgets('is capped at five characters', (tester) async {
    String? reported;
    await pump(tester, (value) => reported = value);

    await tester.enterText(find.byType(TextField), '8F3K2XYZ');
    await tester.pump();

    expect(reported, '8F3K2');
  });
}
