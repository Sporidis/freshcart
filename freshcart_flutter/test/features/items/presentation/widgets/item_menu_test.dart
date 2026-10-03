import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_item_repository.dart';

/// The hold menu's v3 entrance: where the card ends up, and that its
/// options arrive one after another rather than all at once.
void main() {
  setUpAll(configurePluralResolvers);

  /// One row, pinned to [alignment] of the screen.
  Future<void> pumpRow(
    WidgetTester tester,
    Alignment alignment, {
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: ItemTile(
              item: buildItem(name: 'Milk'),
              shopColor: Colors.orange,
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
              onQuantityChanged: (_) {},
              onMove: (_) {},
              t: previewTranslations,
            ),
          ),
        ),
      ),
    );
  }

  /// Holds the row until the menu opens, then lets go. Leaves the menu's
  /// entrance at its very start.
  Future<void> hold(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Milk')),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump();
  }

  double opacityOf(WidgetTester tester, String option) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(option),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('a bottom row gets its menu moved up so the whole card fits', (
    tester,
  ) async {
    await pumpRow(tester, Alignment.bottomCenter);
    await hold(tester);
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(Scaffold));
    final lastOption = tester.getBottomLeft(find.text('Select more…'));
    expect(lastOption.dy, lessThan(screen.height));
  });

  testWidgets('the options fall in one after another, top first', (
    tester,
  ) async {
    await pumpRow(tester, Alignment.topCenter);
    await hold(tester);

    // ~200ms in: the first option is arriving, the last hasn't started.
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, 'Edit details'), greaterThan(0));
    expect(opacityOf(tester, 'Select more…'), 0);

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'Select more…'), 1);
  });

  testWidgets('closing fades the menu out, then removes it', (tester) async {
    await pumpRow(tester, Alignment.topCenter);
    await hold(tester);
    await tester.pumpAndSettle();

    // Tap the dimmed background, well away from the card.
    final screen = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(Offset(screen.width / 2, screen.height - 20));
    await tester.pump(const Duration(milliseconds: 60));
    // Still on screen, on its way out.
    expect(find.text('Edit details'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsNothing);
  });

  testWidgets('with reduced motion, every option is there at once', (
    tester,
  ) async {
    await pumpRow(tester, Alignment.topCenter, reduceMotion: true);
    await hold(tester);

    // A 120ms fade of the whole card, no cascade: past it, all options
    // are fully shown, the last one included.
    await tester.pump(const Duration(milliseconds: 130));
    expect(opacityOf(tester, 'Edit details'), 1);
    expect(opacityOf(tester, 'Select more…'), 1);
  });
}
