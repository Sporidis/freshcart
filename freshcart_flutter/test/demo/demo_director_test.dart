import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/app.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_overrides.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_flutter/demo/demo_stage.dart';
import 'package:freshcart_flutter/demo/director/demo_director.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The intro, end to end, on two real [FreshCartApp]s sharing one backend.
/// Side by side in one test view: the browser's multi-view setup is
/// `DemoPhone`'s job, not the director's.
void main() {
  setUpAll(configurePluralResolvers);

  late DemoBackend backend;
  late DemoStage stage;
  late ProviderContainer a;
  late ProviderContainer b;

  Future<void> pumpPhones(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1600, 1800)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    backend = DemoBackend(clock: systemClock, simulateLatency: false);
    stage = DemoStage();
    addTearDown(stage.dispose);
    a = createPhoneContainer(backend, DemoPersona.a);
    b = createPhoneContainer(backend, DemoPersona.b);
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    await tester.pumpWidget(
      Row(
        textDirection: TextDirection.ltr,
        children: [
          for (final phone in [a, b])
            Expanded(
              child: UncontrolledProviderScope(
                container: phone,
                child: const FreshCartApp(),
              ),
            ),
        ],
      ),
    );
    stage
      ..register(DemoPersona.a, a)
      ..register(DemoPersona.b, b);
  }

  /// Pumps until [done] completes (the director's waits poll on timers).
  Future<void> pumpUntil(WidgetTester tester, Future<void> done) async {
    var finished = false;
    done.whenComplete(() => finished = true).ignore();
    for (var i = 0; i < 400 && !finished; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(finished, isTrue, reason: 'the intro never finished');
    // Let the last navigation and any screen timers settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('Skip plays the whole intro at once and unlocks the phones', (
    tester,
  ) async {
    await pumpPhones(tester);
    stage.skip();

    await pumpUntil(tester, DemoDirector(stage).run());

    final list = backend.lists.values.single;
    expect(list.name, 'Home');
    expect(
      [for (final m in list.members) m.displayName],
      [
        'Nikolaos',
        'Anna',
      ],
    );
    expect([for (final i in backend.items.values) i.name], ['Milk']);

    // Both phones end on that list, and both show Milk.
    for (final phone in [a, b]) {
      expect(
        phone.read(appRouterProvider).state.uri.path,
        Routes.listDetail(list.id),
      );
    }
    expect(find.text('Milk'), findsNWidgets(2));
    expect(stage.locked.value, isFalse);
  });

  testWidgets('a cancelled intro stops and leaves the phones locked', (
    tester,
  ) async {
    await pumpPhones(tester);
    final director = DemoDirector(stage);
    final run = director.run();

    // Let it get going (it waits on the splash screens), then cancel.
    await tester.pump(const Duration(milliseconds: 200));
    director.cancel();
    await pumpUntil(tester, run);

    expect(backend.lists, isEmpty);
    expect(stage.locked.value, isTrue);
  });
}
