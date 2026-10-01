import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:freshcart_flutter/features/settings/presentation/screens/settings_screen.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_push_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => auth.dispose());

  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an anonymous account offers to link an email', (tester) async {
    await pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Secure your lists'), findsOneWidget);
    expect(find.text('Link email'), findsOneWidget);
  });

  testWidgets('a linked account shows the address it is secured by', (
    tester,
  ) async {
    auth.user = Ok(
      AuthUser(
        id: UserId('user-1'),
        displayName: 'Nikolaos',
        isAnonymous: false,
        email: 'n@example.com',
      ),
    );

    await pump(tester);

    expect(find.text('Your account is secured.'), findsOneWidget);
    expect(find.text('n@example.com'), findsNWidgets(2));
    expect(find.text('Link email'), findsNothing);
  });

  testWidgets('linking from settings reaches the same dialog as the nudge', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Link email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'me@example.com');
    await tester.enterText(find.byType(TextField).last, 'a good passphrase');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(auth.linkCalls.single.email, 'me@example.com');
    expect(find.text('Your account is secured.'), findsOneWidget);
  });

  testWidgets('sign out button calls the auth repository', (tester) async {
    await pump(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
  });

  group('Preferences', () {
    // A fixed-distance drag here was fragile to exactly how much content sat
    // above/below the target on the day it was written -- it happened to
    // work by clamping to the list's max scroll extent, which broke the
    // moment that extent grew. Scrolling to the specific widget each test
    // actually needs is robust to the Preferences section changing size.
    Future<void> scrollToPreferences(WidgetTester tester, Finder target) async {
      await tester.dragUntilVisible(
        target,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'choosing Dark from the Appearance dialog persists the choice',
      (tester) async {
        await pump(tester);
        await scrollToPreferences(tester, find.text('Appearance'));

        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(find.text('Dark'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('appearance_mode'), 'dark');
      },
    );

    testWidgets(
      'larger list text is off by default and persists once toggled',
      (tester) async {
        await pump(tester);
        final tile = find.widgetWithText(SwitchListTile, 'Larger list text');
        await scrollToPreferences(tester, tile);

        expect(tester.widget<SwitchListTile>(tile).value, isFalse);

        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(tester.widget<SwitchListTile>(tile).value, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('large_list_text'), isTrue);
      },
    );

    testWidgets(
      'haptics is on by default -- matching every call site\'s current '
      'unconditional behavior -- and persists once turned off',
      (tester) async {
        await pump(tester);
        final tile = find.widgetWithText(SwitchListTile, 'Haptics');
        await scrollToPreferences(tester, tile);

        expect(tester.widget<SwitchListTile>(tile).value, isTrue);

        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(tester.widget<SwitchListTile>(tile).value, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('haptics_enabled'), isFalse);
      },
    );

    testWidgets(
      'reduce motion reports the OS status as read-only text, not a switch',
      (tester) async {
        await pump(tester);
        final row = find.widgetWithText(ListTile, 'Reduce motion');
        await scrollToPreferences(tester, row);

        expect(row, findsOneWidget);
        expect(tester.widget(row), isNot(isA<SwitchListTile>()));
        expect(
          find.descendant(of: row, matching: find.byType(Switch)),
          findsNothing,
        );
        expect(find.text('Off'), findsOneWidget);
      },
    );

    testWidgets(
      'the Notifications row opens the Notifications screen',
      (tester) async {
        // The real journey, not SettingsScreen constructed directly: a
        // context.push needs an actual GoRouter ancestor, which only
        // FreshCartApp's routing provides -- the same reasoning
        // list_settings_screen_test.dart's own pump helper documents.
        final notifList = buildList(members: [buildMember()]);
        final notifAuth = FakeAuthRepository();
        final notifLists = FakeListRepository()
          ..myListsResult = Ok([notifList])
          ..byIdResult = Ok(notifList);
        final notifItems = FakeItemRepository();
        addTearDown(notifAuth.dispose);
        addTearDown(notifLists.dispose);
        addTearDown(notifItems.dispose);

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(notifAuth),
            listRepositoryProvider.overrideWithValue(notifLists),
            itemRepositoryProvider.overrideWithValue(notifItems),
            shopRepositoryProvider.overrideWithValue(FakeShopRepository()),
            pushRepositoryProvider.overrideWithValue(FakePushRepository()),
            authBootstrapProvider.overrideWith(
              (ref) async => (authenticated: true, isNewIdentity: false),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(localeControllerProvider.notifier).select(AppLocale.en);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FreshCartApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Notifications'));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationsScreen), findsOneWidget);
      },
    );
  });
}
