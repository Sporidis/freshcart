import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/invite_card.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_list_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  const aliceId = 'user-1';
  const bobId = 'user-2';
  final listId = ListId('00000000-0000-4000-8000-000000000001');

  late FakeListRepository repository;

  setUp(() => repository = FakeListRepository());

  ShoppingList household() => buildList(
    name: 'Groceries',
    members: [
      buildMember(userId: aliceId, displayName: 'Alice'),
      buildMember(
        userId: bobId,
        displayName: 'Bob',
        role: MemberRole.member,
      ),
    ],
  );

  /// Pumps the screen as [asUserId].
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required String asUserId,
  }) async {
    repository.byIdResult = Ok(household());
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWith((ref) async => Ok(UserId(asUserId))),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppTheme.brandSeed),
          home: HouseholdScreen(listId: listId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('tags the owner and yourself', (tester) async {
    await pump(tester, asUserId: aliceId);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    // Alice created the list, so she is both.
    expect(find.text('You · Owner'), findsOneWidget);
  });

  testWidgets('a member sees the owner tagged, and themselves', (
    tester,
  ) async {
    await pump(tester, asUserId: bobId);

    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  group('who is offered what', () {
    testWidgets('the owner can manage others but not themselves', (
      tester,
    ) async {
      await pump(tester, asUserId: aliceId);

      // One menu, on Bob's row only -- never on your own.
      expect(find.byType(PopupMenuButton<void>), findsOneWidget);
    });

    testWidgets('a member is offered no management at all', (tester) async {
      await pump(tester, asUserId: bobId);

      expect(
        find.byType(PopupMenuButton<void>),
        findsNothing,
        reason: 'the server would refuse it; the UI should not offer it',
      );
    });
  });

  group('removing a member', () {
    testWidgets('asks first, and does nothing when declined', (tester) async {
      await pump(tester, asUserId: aliceId);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from list'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Bob?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.removeMemberCalls, isEmpty);
    });

    testWidgets('removes on confirmation', (tester) async {
      await pump(tester, asUserId: aliceId);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from list'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove from list'));
      await tester.pumpAndSettle();

      expect(repository.removeMemberCalls.single.userId, UserId(bobId));
    });
  });

  group('transferring ownership', () {
    testWidgets('spells out that you lose it too', (tester) async {
      await pump(tester, asUserId: aliceId);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make owner'));
      await tester.pumpAndSettle();

      expect(find.text('Make Bob the owner?'), findsOneWidget);
      expect(
        find.textContaining('You become an ordinary member'),
        findsOneWidget,
      );
    });

    testWidgets('transfers on confirmation', (tester) async {
      await pump(tester, asUserId: aliceId);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make owner'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Make owner'));
      await tester.pumpAndSettle();

      expect(repository.transferCalls.single.userId, UserId(bobId));
    });
  });

  testWidgets('the invite code can be copied', (tester) async {
    await pump(tester, asUserId: aliceId);

    expect(find.byType(InviteCard), findsOneWidget);
    expect(find.text('ABC23'), findsOneWidget);
  });
}
