import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

void main() {
  late int taps;

  Future<void> pump(WidgetTester tester) {
    taps = 0;
    void onTap() => taps++;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapTarget(
              onTap: onTap,
              child: InkWell(
                key: const ValueKey('control'),
                onTap: onTap,
                child: const SizedBox.square(dimension: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('grows a 20px control to the 44pt minimum', (tester) async {
    await pump(tester);
    expect(
      tester.getSize(find.byType(TapTarget)),
      const Size.square(AppSpacing.minTapTarget),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('control'))),
      const Size.square(20),
    );
  });

  testWidgets('a tap in the margin reaches the handler', (tester) async {
    await pump(tester);
    final box = tester.getRect(find.byType(TapTarget));
    await tester.tapAt(box.topLeft + const Offset(2, 2));
    expect(taps, 1);
  });

  testWidgets('a tap on the control fires once, not twice', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('control')));
    expect(taps, 1);
  });
}
