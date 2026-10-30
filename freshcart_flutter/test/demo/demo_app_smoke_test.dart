import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/app.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_overrides.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_flutter/demo/fakes/fake_item_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_list_repository.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The real [FreshCartApp] on [createPhoneContainer]: onboarding works with
/// no server, and a change from "the other phone" shows up live.
///
/// `serverpodClientProvider` is not overridden and throws when read, so if
/// any screen still reaches for the real backend, this test fails.
void main() {
  setUpAll(configurePluralResolvers);

  testWidgets('onboard on the fakes, then see the other phone add an item', (
    tester,
  ) async {
    final db = DemoBackend(clock: systemClock, simulateLatency: false);
    final container = createPhoneContainer(db, DemoPersona.a);
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreshCartApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Splash -> Welcome, because the demo identity is always new.
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Nikolaos');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Shops step: keep the presets.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // The fake "server" now has the list, the preset shops and the name.
    final list = db.lists.values.single;
    expect(list.name, 'Home');
    expect(db.shops.values.where((s) => s.listId == list.id), isNotEmpty);
    expect(db.users[DemoPersona.a.id]?.displayName, 'Nikolaos');
    // The avatar keeps the colour onboarding showed, on the list too.
    final shown = AppColors.avatarHexColorFor('Nikolaos');
    expect(db.users[DemoPersona.a.id]?.avatarColor, shown);
    expect(list.memberFor(DemoPersona.a.id)?.avatarColor, shown);
    await tester.tap(find.text('Invite someone'));
    await tester.pumpAndSettle();
    final code = db.lists[list.id]!.invite!.code;
    expect(find.bySemanticsLabel(code.value), findsOneWidget);

    await tester.tap(find.text('Start my list'));
    await tester.pumpAndSettle();

    // "Phone B" joins and adds an item straight through its own fakes.
    final b = DemoPersona.b.id;
    db.users[b] = AuthUser(id: b, displayName: 'Anna', isAnonymous: true);
    await FakeListRepository(db, b).joinByCode(code);
    await FakeItemRepository(db, b).add(listId: list.id, name: 'Milk');
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
  });
}
