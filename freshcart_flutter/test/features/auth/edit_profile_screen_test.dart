import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/edit_profile_screen.dart';
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
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the name field starts pre-filled with the current name', (
    tester,
  ) async {
    await pump(tester);

    expect(find.widgetWithText(TextField, 'Nikolaos'), findsOneWidget);
  });

  testWidgets('saving a new name reaches the auth port, trimmed', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(
      find.byType(TextField).first,
      '  Nikos Sporidis  ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(auth.setDisplayNameCalls, ['Nikos Sporidis']);
  });

  testWidgets('a name rejected by validation shows its message inline', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name to continue'), findsOneWidget);
  });

  testWidgets('tapping a swatch sets the avatar colour', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('avatar-swatch-4280571558')));
    await tester.pumpAndSettle();

    expect(auth.setAvatarColorCalls.single.argb, 0xFF2456A6);
  });

  testWidgets('Remove photo only shows once a photo is actually set', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Remove photo'), findsNothing);

    auth.user = Ok(
      AuthUser(
        id: UserId('user-1'),
        displayName: 'Nikolaos',
        isAnonymous: true,
        avatarPhotoUrl: 'https://example.test/avatars/user-1.jpg',
      ),
    );
    await pump(tester);

    expect(find.text('Remove photo'), findsOneWidget);
  });

  testWidgets('Remove photo calls through to the auth port', (tester) async {
    auth.user = Ok(
      AuthUser(
        id: UserId('user-1'),
        displayName: 'Nikolaos',
        isAnonymous: true,
        avatarPhotoUrl: 'https://example.test/avatars/user-1.jpg',
      ),
    );
    await pump(tester);

    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(auth.clearAvatarPhotoCalls, 1);
  });

  testWidgets(
    'a failed load shows the error screen, not a permanent spinner',
    (tester) async {
      auth.user = const Err(Failure.unexpected());
      await pump(tester);

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
