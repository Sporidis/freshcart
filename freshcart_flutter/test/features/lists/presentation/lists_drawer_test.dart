import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_list_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  const me = 'user-me';

  setUp(() => repository = FakeListRepository());
  tearDown(() => repository.dispose());

  Future<ProviderContainer> pump(WidgetTester tester, {ListId? currentId}) async {
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWith((ref) async => Ok(UserId(me))),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);

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

  testWidgets('lists render with their member count', (tester) async {
    repository.myListsResult = Ok([
      buildList(name: 'Weekly Groceries', members: [buildMember(userId: me)]),
      buildList(
        id: '00000000-0000-4000-8000-000000000002',
        name: 'Camping Trip',
        members: [buildMember(userId: me)],
      ),
    ]);
    await pump(tester);

    expect(find.text('Weekly Groceries'), findsOneWidget);
    expect(find.text('Camping Trip'), findsOneWidget);
    expect(find.text('1 member'), findsNWidgets(2));
  });

  testWidgets(
    "the avatar stack shows who else is on a list, not the viewer's own row",
    (tester) async {
      repository.myListsResult = Ok([
        buildList(
          members: [
            buildMember(userId: me, displayName: 'Me'),
            buildMember(
              userId: 'user-sam',
              displayName: 'Sam',
              role: MemberRole.member,
            ),
          ],
        ),
      ]);
      await pump(tester);

      // Sam's initial shows; the viewer's own "M" does not, since the
      // stack is "who else", not "everyone".
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsNothing);
    },
  );

  testWidgets('more than three others collapses to a +N indicator', (
    tester,
  ) async {
    repository.myListsResult = Ok([
      buildList(
        members: [
          buildMember(userId: me, displayName: 'Me'),
          buildMember(userId: 'u1', displayName: 'Alex'),
          buildMember(userId: 'u2', displayName: 'Bo'),
          buildMember(userId: 'u3', displayName: 'Cam'),
          buildMember(userId: 'u4', displayName: 'Dee'),
        ],
      ),
    ]);
    await pump(tester);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('New list opens the create dialog, which actually creates', (
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
    await tester.tap(find.text('Save'));
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
}
