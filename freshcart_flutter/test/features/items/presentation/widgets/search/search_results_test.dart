import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
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

  late FakeItemRepository repository;

  setUp(() {
    repository = FakeItemRepository();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => repository.dispose());

  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repository),
        // The view model's build() watches the list's shops too.
        shopRepositoryProvider.overrideWithValue(FakeShopRepository()),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
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
            // Built directly rather than read from the view model: it's a
            // plain value, so the test can hand SearchResults exactly the
            // query it wants without driving the search controller.
            body: SearchResults(
              state: ItemsSectionState(
                list: list,
                mode: ItemsMode.search,
                allItems: const [],
                shops: const [],
                shopFilter: null,
                me: null,
                selection: const {},
                searchQuery: 'Nutella',
                doneCollapsed: false,
                showCelebration: false,
              ),
              vm: vm,
              t: t,
              dotFor: (_) => null,
              onEdit: (_) {},
              report: (_, {onRetry}) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SearchResults no-results "Add to this list"', () {
    testWidgets('tapping it adds the typed name', (tester) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repository.addCalls.single.name, 'Nutella');
    });

    testWidgets('a rapid second tap does not start a second add', (
      tester,
    ) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
      final pause = Completer<void>();
      repository.addPause = pause.future;
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(repository.addCalls, hasLength(1));

      pause.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping it fires a haptic', (tester) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
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

      await tester.tap(find.byType(FilledButton));
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
