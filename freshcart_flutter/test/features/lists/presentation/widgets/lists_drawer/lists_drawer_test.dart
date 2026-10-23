import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer/lists_drawer.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../../fakes/fake_auth_repository.dart';
import '../../../../../fakes/fake_list_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  late FakeAuthRepository auth;
  const me = 'user-me';

  setUp(() {
    repository = FakeListRepository();
    // The new drawer header reads the signed-in profile (name, avatar) --
    // unrelated to currentUserIdProvider below, which only decides list
    // membership, so a mismatched id between the two is fine for these
    // tests; none of them assert on the header itself.
    auth = FakeAuthRepository();
  });
  tearDown(() async {
    await repository.dispose();
    await auth.dispose();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ListId? currentId,
  }) async {
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(auth),
        currentUserIdProvider.overrideWith((ref) async => Ok(UserId(me))),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);

    // A real Scaffold.drawer, opened properly -- ListsDrawer's own rows
    // call Navigator.pop() to close themselves before acting, which needs
    // an actual drawer route on the stack to pop, not the drawer pumped in
    // as if it were a screen's plain body content.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            drawer: ListsDrawer(
              currentListId:
                  currentId ?? ListId('00000000-0000-4000-8000-000000000001'),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'falls back to the member count before a summary has loaded',
    (tester) async {
      repository.myListsResult = Ok([
        buildList(
          name: 'Weekly Groceries',
          members: [buildMember(userId: me)],
        ),
        buildList(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Camping Trip',
          members: [buildMember(userId: me)],
        ),
      ]);
      // Unset -- FakeListRepository's own default (Ok(<ListSummary>[])) has
      // no entry for either list id, the same "hasn't resolved yet" shape a
      // slow real fetch would leave the drawer in for a frame.
      await pump(tester);

      expect(find.text('Weekly Groceries'), findsOneWidget);
      expect(find.text('Camping Trip'), findsOneWidget);
      expect(find.text('1 member'), findsNWidgets(2));
    },
  );

  testWidgets('shows progress once its summary has loaded', (
    tester,
  ) async {
    final listId = ListId('00000000-0000-4000-8000-000000000001');
    repository.myListsResult = Ok([
      buildList(
        id: listId.value,
        members: [buildMember(userId: me)],
      ),
    ]);
    repository.summariesResult = Ok([
      ListSummary(listId: listId, total: 8, checkedCount: 2),
    ]);
    await pump(tester, currentId: listId);

    // v3: progress, checked out of total.
    expect(find.text('2/8'), findsOneWidget);
    expect(find.text('1 member'), findsNothing);
  });

  testWidgets('shows a full bar for a list with everything checked', (
    tester,
  ) async {
    final listId = ListId('00000000-0000-4000-8000-000000000001');
    repository.myListsResult = Ok([
      buildList(
        id: listId.value,
        members: [buildMember(userId: me)],
      ),
    ]);
    repository.summariesResult = Ok([
      ListSummary(listId: listId, total: 4, checkedCount: 4),
    ]);
    await pump(tester, currentId: listId);

    expect(find.text('4/4'), findsOneWidget);
  });

  testWidgets('New list opens the create sheet, which actually creates', (
    tester,
  ) async {
    repository.myListsResult = Ok([
      buildList(members: [buildMember(userId: me)]),
    ]);
    repository.createResult = Ok(buildList(name: 'Camping'));
    await pump(tester);

    await tester.tap(find.text('New list'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Camping');
    // Create list enables on the frame after typing.
    await tester.pump();
    await tester.tap(find.text('Create list'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, ['Camping']);
  });

  testWidgets('Join a list opens the join dialog, which actually joins', (
    tester,
  ) async {
    repository.myListsResult = Ok([
      buildList(members: [buildMember(userId: me)]),
    ]);
    repository.joinResult = Ok(buildList(name: 'Shared'));
    await pump(tester);

    await tester.tap(find.text('Join a list with a code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ABC23');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.joinCalls, [JoinCode.parse('ABC23').valueOrNull]);
  });

  group('header (Flow 10)', () {
    testWidgets('shows the signed-in profile and opens Edit profile', (
      tester,
    ) async {
      repository.myListsResult = Ok([
        buildList(
          name: 'Weekly Groceries',
          members: [buildMember(userId: me)],
        ),
        buildList(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Camping Trip',
          members: [
            buildMember(userId: me),
            buildMember(userId: 'user-sam', displayName: 'Sam'),
          ],
        ),
      ]);
      await pump(tester);

      // FakeAuthRepository's own default identity.
      expect(find.text('Nikolaos'), findsOneWidget);
      // v3: the header is the door to your profile.
      expect(find.text('Edit profile'), findsOneWidget);
    });
  });

  group('long-press to rename (Motion & Interaction Spec §13)', () {
    testWidgets(
      "the owner's own list becomes an inline field, and submitting renames it",
      (tester) async {
        final listId = ListId('00000000-0000-4000-8000-000000000001');
        repository.myListsResult = Ok([
          buildList(
            id: listId.value,
            name: 'Weekly Groceries',
            ownerId: me,
            members: [buildMember(userId: me, role: MemberRole.owner)],
          ),
        ]);
        await pump(tester, currentId: listId);

        await tester.longPress(find.text('Weekly Groceries'));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Groceries');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(repository.renameCalls, [(id: listId, name: 'Groceries')]);
      },
    );

    testWidgets("a list the viewer doesn't own never opens a field", (
      tester,
    ) async {
      // ownerId defaults to 'user-1', not `me` -- the viewer is a regular
      // member here, not the owner.
      repository.myListsResult = Ok([
        buildList(
          name: 'Weekly Groceries',
          members: [
            buildMember(userId: 'user-1', displayName: 'Owner'),
            buildMember(userId: me, role: MemberRole.member),
          ],
        ),
      ]);
      await pump(tester);

      await tester.longPress(find.text('Weekly Groceries'));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      expect(repository.renameCalls, isEmpty);
    });
  });
}
