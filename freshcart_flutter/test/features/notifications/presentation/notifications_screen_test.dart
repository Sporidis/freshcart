import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:freshcart_flutter/features/notifications/data/push_repository_provider.dart';
import 'package:freshcart_flutter/features/notifications/presentation/notifications_screen.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../fakes/fake_list_repository.dart';
import '../../../fakes/fake_push_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository lists;
  late FakePushRepository push;

  setUp(() {
    lists = FakeListRepository();
    push = FakePushRepository();
  });

  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(lists),
        pushRepositoryProvider.overrideWithValue(push),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeLocaleProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists show On by default, Muted once actually muted', (
    tester,
  ) async {
    final weekly = buildList(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Weekly Groceries',
    );
    final bbq = buildList(
      id: '00000000-0000-4000-8000-000000000002',
      name: 'BBQ Party',
    );
    lists.myListsResult = Ok([weekly, bbq]);
    push.mutedByList[bbq.id] = true;
    await pump(tester);

    expect(find.text('Weekly Groceries'), findsOneWidget);
    expect(find.text('BBQ Party'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Muted'), findsOneWidget);
  });

  testWidgets('tapping a row mutes it, and calls through to the port', (
    tester,
  ) async {
    final weekly = buildList(name: 'Weekly Groceries');
    lists.myListsResult = Ok([weekly]);
    await pump(tester);

    expect(find.text('On'), findsOneWidget);

    await tester.tap(find.text('Weekly Groceries'));
    await tester.pumpAndSettle();

    expect(find.text('Muted'), findsOneWidget);
    expect(push.setListMutedCalls.single, (listId: weekly.id, muted: true));
  });

  testWidgets('tapping an already-muted row unmutes it', (tester) async {
    final weekly = buildList(name: 'Weekly Groceries');
    lists.myListsResult = Ok([weekly]);
    push.mutedByList[weekly.id] = true;
    await pump(tester);

    expect(find.text('Muted'), findsOneWidget);

    await tester.tap(find.text('Weekly Groceries'));
    await tester.pumpAndSettle();

    expect(find.text('On'), findsOneWidget);
    expect(push.setListMutedCalls.single, (listId: weekly.id, muted: false));
  });
}
