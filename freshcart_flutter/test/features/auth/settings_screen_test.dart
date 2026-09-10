import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/settings_screen.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_auth_repository.dart';

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
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
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
    expect(find.text('n@example.com'), findsOneWidget);
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
}
