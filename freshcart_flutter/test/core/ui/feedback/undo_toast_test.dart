import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

void main() {
  final t = translationsFor(AppLocale.en);

  Future<void> show(
    WidgetTester tester, {
    VoidCallback? onUndo,
    bool tick = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUndoToast(
                context,
                message: 'Pasta checked off',
                t: t,
                onUndo: onUndo,
                tick: tick,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('Undo runs the callback once and hides the toast', (
    tester,
  ) async {
    var undone = 0;
    await show(tester, onUndo: () => undone++);

    expect(find.text('Pasta checked off'), findsOneWidget);
    await tester.tap(find.text(t.common.undo));
    await tester.pumpAndSettle();

    expect(undone, 1);
    expect(find.text('Pasta checked off'), findsNothing);
  });

  testWidgets('without onUndo there is no Undo button', (tester) async {
    await show(tester, tick: true);

    expect(find.text(t.common.undo), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('the toast is the design height of 48', (tester) async {
    await show(tester, onUndo: () {});

    final bar = tester.getSize(
      find
          .ancestor(
            of: find.text('Pasta checked off'),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(bar.height, 48);
  });
}
