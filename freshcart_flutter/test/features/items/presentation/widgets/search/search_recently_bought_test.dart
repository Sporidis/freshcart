import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/clock/clock_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/item_history/recency_buckets.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_recently_bought.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../fakes/fake_item_repository.dart';
import '../../../../../fakes/fake_list_repository.dart';
import '../../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final me = UserId('user-me');
  final now = DateTime.utc(2026, 9, 13, 12);

  late FakeItemRepository repository;

  setUp(() {
    repository = FakeItemRepository();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => repository.dispose());

  group('bucketByRecency', () {
    NameHistoryEntry entryDaysAgo(String name, int days) => NameHistoryEntry(
      name: name,
      lastUsedAt: now.subtract(Duration(days: days)),
    );

    test('groups into rolling 7-day windows, not calendar weeks', () {
      final buckets = bucketByRecency([
        entryDaysAgo('Milk', 0),
        entryDaysAgo('Bananas', 6),
        entryDaysAgo('Coffee beans', 7),
        entryDaysAgo('Ground beef', 8),
        entryDaysAgo('Pasta', 14),
        entryDaysAgo('Butter', 15),
      ], now);

      expect(
        buckets.thisWeek.map((e) => e.name),
        ['Milk', 'Bananas', 'Coffee beans'],
      );
      expect(buckets.lastWeek.map((e) => e.name), ['Ground beef', 'Pasta']);
      expect(buckets.earlier.map((e) => e.name), ['Butter']);
    });

    test('preserves the incoming (already-sorted) order within each group', () {
      final buckets = bucketByRecency([
        entryDaysAgo('B', 2),
        entryDaysAgo('A', 1),
      ], now);

      expect(buckets.thisWeek.map((e) => e.name), ['B', 'A']);
    });

    test('an empty history produces three empty groups', () {
      final buckets = bucketByRecency(const [], now);

      expect(buckets.thisWeek, isEmpty);
      expect(buckets.lastWeek, isEmpty);
      expect(buckets.earlier, isEmpty);
    });
  });

  group('SearchRecentlyBought', () {
    Future<void> pump(
      WidgetTester tester, {
      DateTime Function() now = DateTime.now,
    }) async {
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repository),
          // The view model's build() watches the list's shops too.
          shopRepositoryProvider.overrideWithValue(FakeShopRepository()),
          currentUserIdProvider.overrideWith((ref) async => Ok(me)),
          clockProvider.overrideWithValue(now),
        ],
      );
      addTearDown(container.dispose);
      container.read(localeControllerProvider.notifier).select(AppLocale.en);
      final list = buildList(id: listId.value);
      // The view model (and the autoDispose itemsControllerProvider it
      // watches) would otherwise be torn down before the tap below; holding
      // a listener keeps them alive, the same way an open screen would.
      final subscription = container.listen(
        itemsSectionControllerProvider(list),
        (_, _) {},
      );
      addTearDown(subscription.close);
      final vm = container.read(itemsSectionControllerProvider(list).notifier);
      final t = container.read(translationsProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SearchRecentlyBought(
                listId: listId,
                t: t,
                vm: vm,
                report: (_, {onRetry}) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders nothing for a list with no history', (
      tester,
    ) async {
      repository.recentNamesResult = const Ok(<NameHistoryEntry>[]);
      await pump(tester);

      expect(find.text('Recently bought'), findsNothing);
    });

    testWidgets('groups entries under This week / Last week / Earlier', (
      tester,
    ) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
        NameHistoryEntry(
          name: 'Ground beef',
          lastUsedAt: now.subtract(const Duration(days: 8)),
        ),
        NameHistoryEntry(
          name: 'Butter',
          lastUsedAt: now.subtract(const Duration(days: 20)),
        ),
      ]);
      await pump(tester, now: () => now);

      expect(find.text('Recently bought'), findsOneWidget);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('LAST WEEK'), findsOneWidget);
      expect(find.text('Ground beef'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);
      expect(find.text('Butter'), findsOneWidget);
    });

    testWidgets('tapping a row\'s + re-adds that name', (tester) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
      ]);
      repository.addResult = Ok(buildItem(name: 'Milk'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(repository.addCalls.single.name, 'Milk');
    });

    testWidgets('after re-adding, the + shows a tick for a moment', (
      tester,
    ) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
      ]);
      repository.addResult = Ok(buildItem(name: 'Milk'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Read with the row's name: "Milk, Added".
      expect(find.bySemanticsLabel(RegExp(r'^Milk\nAdded$')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'^Milk\nAdd again$')),
        findsOneWidget,
      );
    });

    testWidgets('a failed re-add shows no tick', (tester) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
      ]);
      repository.addResult = const Err(Failure.network());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('a rapid second tap does not start a second add', (
      tester,
    ) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
      ]);
      repository.addResult = Ok(buildItem(name: 'Milk'));
      final pause = Completer<void>();
      repository.addPause = pause.future;
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      // The first add is still in flight -- a second tap while it's pending
      // must be a no-op, not a second request.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(repository.addCalls, hasLength(1));

      pause.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping + fires a haptic', (tester) async {
      repository.recentNamesResult = Ok([
        NameHistoryEntry(name: 'Milk', lastUsedAt: now),
      ]);
      repository.addResult = Ok(buildItem(name: 'Milk'));
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(
        calls,
        contains(
          isMethodCall(
            'HapticFeedback.vibrate',
            arguments: 'HapticFeedbackType.lightImpact',
          ),
        ),
      );
    });
  });
}
