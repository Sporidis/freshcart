import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../fakes/fake_client.dart';

void main() {
  setUpAll(configurePluralResolvers);

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    AppLocale? locale,
  }) async {
    // The shell test exercises routing, theming and translation, so the list
    // fetch is answered with an empty collection rather than left unconfigured.
    // The element type matters: FakeClient casts to the endpoint's return
    // type, so an untyped empty list would fail the cast and look like an error.
    final client = FakeClient()..handler = (_, _, _) => <dto.ShoppingList>[];
    final container = ProviderContainer(
      overrides: [serverpodClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    if (locale != null) {
      container.read(activeLocaleProvider.notifier).select(locale);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreshCartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('app shell', () {
    testWidgets('boots to the lists screen', (tester) async {
      await pumpApp(tester, locale: AppLocale.en);

      expect(find.text('My lists'), findsOneWidget);
      expect(
        find.text('No lists yet. Create one to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('renders in the selected locale', (tester) async {
      await pumpApp(tester, locale: AppLocale.nl);
      expect(find.text('Mijn lijsten'), findsOneWidget);
    });

    testWidgets('renders Russian', (tester) async {
      await pumpApp(tester, locale: AppLocale.ru);
      expect(find.text('Мои списки'), findsOneWidget);
    });

    testWidgets('renders Tagalog', (tester) async {
      await pumpApp(tester, locale: AppLocale.tl);
      expect(find.text('Mga listahan ko'), findsOneWidget);
    });

    testWidgets('switching locale at runtime re-renders the strings', (
      tester,
    ) async {
      final container = await pumpApp(tester, locale: AppLocale.en);
      expect(find.text('My lists'), findsOneWidget);

      container.read(activeLocaleProvider.notifier).select(AppLocale.fr);
      await tester.pumpAndSettle();

      expect(find.text('Mes listes'), findsOneWidget);
      expect(find.text('My lists'), findsNothing);
    });
  });

  group('theming', () {
    testWidgets('starts from the brand seed', (tester) async {
      await pumpApp(tester);

      final theme = Theme.of(
        tester.element(find.byType(Scaffold)),
      );
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(seedColor: AppTheme.brandSeed).primary,
      );
    });

    testWidgets('selecting a shop colour re-themes the app', (tester) async {
      final container = await pumpApp(tester);
      final before = Theme.of(
        tester.element(find.byType(Scaffold)),
      ).colorScheme.primary;

      // A shop's seed colour arrives from the domain as a plain ARGB int.
      final shopColour = HexColor.parse('#C62828').valueOrNull!;
      container.read(activeSeedColorProvider.notifier).select(shopColour);
      await tester.pumpAndSettle();

      final after = Theme.of(
        tester.element(find.byType(Scaffold)),
      ).colorScheme.primary;
      expect(after, isNot(before));
      expect(
        after,
        ColorScheme.fromSeed(seedColor: Color(shopColour.argb)).primary,
      );
    });

    testWidgets('clearing the shop returns to the brand seed', (tester) async {
      final container = await pumpApp(tester);
      final notifier = container.read(activeSeedColorProvider.notifier);

      notifier.select(HexColor.parse('#C62828').valueOrNull);
      await tester.pumpAndSettle();
      notifier.select(null);
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary,
        ColorScheme.fromSeed(seedColor: AppTheme.brandSeed).primary,
      );
    });
  });
}
