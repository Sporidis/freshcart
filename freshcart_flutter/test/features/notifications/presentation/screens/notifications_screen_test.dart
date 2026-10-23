import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_push_repository.dart';

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
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
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

  testWidgets('a failed mute says so, and the row stays On', (tester) async {
    final weekly = buildList(name: 'Weekly Groceries');
    lists.myListsResult = Ok([weekly]);
    push.setListMutedResult = const Err(Failure.network());
    await pump(tester);

    await tester.tap(find.text('Weekly Groceries'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
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

  group('Push', () {
    testWidgets(
      'item-added is on by default -- the design\'s own "off by default '
      'except the first" -- the other two are off',
      (tester) async {
        await pump(tester);

        expect(
          tester
              .widget<SettingToggleOption>(
                find.widgetWithText(
                  SettingToggleOption,
                  'Someone adds an item',
                ),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<SettingToggleOption>(
                find.widgetWithText(
                  SettingToggleOption,
                  'Someone joins a list',
                ),
              )
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<SettingToggleOption>(
                find.widgetWithText(SettingToggleOption, 'A list is finished'),
              )
              .value,
          isFalse,
        );
      },
    );

    testWidgets('each toggle calls through to its own setter', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Someone joins a list'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A list is finished'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Someone adds an item'));
      await tester.pumpAndSettle();

      expect(
        push.preferences,
        const NotificationPreferences(
          itemAdded: false,
          memberJoined: true,
          listFinished: true,
        ),
      );
    });

    testWidgets(
      'a failed load shows no toggles -- never defaults posing as the '
      "user's choices -- and Retry brings them back",
      (tester) async {
        push.preferencesFailure = const Failure.network();
        await pump(tester);

        expect(find.byType(SettingToggleOption), findsNothing);

        push.preferencesFailure = null;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingToggleOption), findsNWidgets(3));
      },
    );
  });
}
