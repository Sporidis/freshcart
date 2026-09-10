import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/active_seed_color_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/features/auth/data/auth_bootstrap_provider.dart';
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
      overrides: [
        serverpodClientProvider.overrideWithValue(client),
        // These tests are about the shell already showing the lists screen,
        // not the onboarding gate — a restored (non-new) identity, resolved
        // instantly rather than actually going through Splash's real bootstrap.
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: true, isNewIdentity: false),
        ),
      ],
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
        find.text('No lists yet'),
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
      // The neutral/brand theme is ink-on-paper, not a Material-generated
      // scheme: primary buttons must not change colour when no shop is
      // active. Only AppTheme.forShop's non-brand seeds get the generated
      // ColorScheme.fromSeed treatment (see AppTheme's class doc).
      expect(theme.colorScheme.primary, AppColors.ink);
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
      // The shop's own colour, not what ColorScheme.fromSeed would have
      // derived from it: M3's seeding snaps a colour to the nearest tone on
      // its own generated ramp, which visibly shifts hue and saturation away
      // from a swatch someone actually picked (see AppTheme._build).
      expect(after, Color(shopColour.argb));
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
        AppColors.ink,
      );
    });
  });
}
